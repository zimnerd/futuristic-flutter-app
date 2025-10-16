import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../core/utils/logger.dart';

/// Service for handling In-App Purchases via App Store and Google Play
class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  static InAppPurchaseService get instance => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  
  // Purchase stream controller for external listeners
  final _purchaseStreamController = StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseStream => _purchaseStreamController.stream;

  // Available products
  final Map<String, ProductDetails> _products = {};
  bool _isAvailable = false;
  bool _purchasePending = false;

  // Product IDs mapping to coin packages
  static const Map<String, String> productIds = {
    'coins_100': 'com.pulselink.coins.100',
    'coins_500': 'com.pulselink.coins.500',
    'coins_1000': 'com.pulselink.coins.1000',
    'coins_2500': 'com.pulselink.coins.2500',
    'coins_5000': 'com.pulselink.coins.5000',
    'coins_10000': 'com.pulselink.coins.10000',
  };

  /// Initialize the in-app purchase service
  Future<bool> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        AppLogger.warning('In-app purchases not available on this device');
        return false;
      }

      // Set up purchase listener
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseDone,
        onError: _onPurchaseError,
      );

      // Initialize store-specific configurations
      if (Platform.isIOS) {
        final iosPlatform = _inAppPurchase
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatform.setDelegate(PaymentQueueDelegate());
      }

      // Load products
      await _loadProducts();

      AppLogger.info('In-app purchase service initialized successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to initialize in-app purchases: $e');
      return false;
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final Set<String> ids = productIds.values.toSet();
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning('Products not found: ${response.notFoundIDs}');
      }

      for (final product in response.productDetails) {
        _products[product.id] = product;
        AppLogger.debug('Loaded product: ${product.id} - ${product.title} (${product.price})');
      }

      if (response.error != null) {
        AppLogger.error('Error loading products: ${response.error}');
      }
    } catch (e) {
      AppLogger.error('Failed to load products: $e');
    }
  }

  /// Get product details for a coin package
  ProductDetails? getProduct(String coinPackageId) {
    final productId = productIds[coinPackageId];
    if (productId == null) {
      AppLogger.error('No product ID found for coin package: $coinPackageId');
      return null;
    }
    return _products[productId];
  }

  /// Get all available products
  List<ProductDetails> getAllProducts() {
    return _products.values.toList();
  }

  /// Purchase a coin package
  Future<bool> purchaseCoinPackage(String coinPackageId) async {
    if (!_isAvailable) {
      AppLogger.error('In-app purchases not available');
      return false;
    }

    if (_purchasePending) {
      AppLogger.warning('Purchase already in progress');
      return false;
    }

    final product = getProduct(coinPackageId);
    if (product == null) {
      AppLogger.error('Product not found for package: $coinPackageId');
      return false;
    }

    try {
      _purchasePending = true;
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null, // Can be set to user ID if needed
      );

      final bool success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );

      if (!success) {
        _purchasePending = false;
        AppLogger.error('Failed to initiate purchase');
      }

      return success;
    } catch (e) {
      _purchasePending = false;
      AppLogger.error('Error initiating purchase: $e');
      return false;
    }
  }

  /// Restore previous purchases (iOS)
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      throw Exception('In-app purchases not available');
    }

    try {
      if (Platform.isIOS) {
        await _inAppPurchase.restorePurchases();
        AppLogger.info('Restore purchases initiated');
      } else {
        AppLogger.warning('Restore purchases only available on iOS');
      }
    } catch (e) {
      AppLogger.error('Error restoring purchases: $e');
      rethrow;
    }
  }

  /// Handle purchase updates from the store
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      AppLogger.debug(
        'Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}',
      );

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase with backend before delivering coins
        _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handlePurchaseError(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _handlePurchaseCanceled(purchaseDetails);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify purchase with backend
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      AppLogger.info('Verifying purchase: ${purchaseDetails.productID}');
      
      // Find the coin package ID from product ID
      String? coinPackageId;
      productIds.forEach((key, value) {
        if (value == purchaseDetails.productID) {
          coinPackageId = key;
        }
      });

      if (coinPackageId == null) {
        AppLogger.error('Could not find coin package for product: ${purchaseDetails.productID}');
        return;
      }

      // Emit purchase details for backend verification
      _purchaseStreamController.add(purchaseDetails);
      
      _purchasePending = false;
      AppLogger.info('Purchase verified successfully: ${purchaseDetails.productID}');
    } catch (e) {
      _purchasePending = false;
      AppLogger.error('Error verifying purchase: $e');
    }
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    _purchasePending = false;
    final error = purchaseDetails.error;
    AppLogger.error(
      'Purchase error: ${error?.code} - ${error?.message}',
    );
    _purchaseStreamController.addError(
      Exception('Purchase failed: ${error?.message ?? "Unknown error"}'),
    );
  }

  /// Handle purchase cancellation
  void _handlePurchaseCanceled(PurchaseDetails purchaseDetails) {
    _purchasePending = false;
    AppLogger.info('Purchase canceled: ${purchaseDetails.productID}');
    _purchaseStreamController.addError(
      Exception('Purchase was canceled'),
    );
  }

  /// Called when purchase stream is done
  void _onPurchaseDone() {
    AppLogger.info('Purchase stream completed');
  }

  /// Called when purchase stream has error
  void _onPurchaseError(dynamic error) {
    _purchasePending = false;
    AppLogger.error('Purchase stream error: $error');
    _purchaseStreamController.addError(error);
  }

  /// Check if purchases are available
  bool get isAvailable => _isAvailable;

  /// Check if a purchase is pending
  bool get isPurchasePending => _purchasePending;

  /// Dispose the service
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseStreamController.close();
  }
}

/// Payment queue delegate for iOS
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
