import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/coin_package.dart';
import '../../data/services/in_app_purchase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../blocs/premium/premium_bloc.dart';
import '../blocs/premium/premium_event.dart';
import '../blocs/premium/premium_state.dart';
import '../widgets/premium/coin_package_card.dart';

/// Bottom sheet for purchasing coin packages
class CoinPurchaseSheet extends StatefulWidget {
  const CoinPurchaseSheet({super.key});

  @override
  State<CoinPurchaseSheet> createState() => _CoinPurchaseSheetState();
}

class _CoinPurchaseSheetState extends State<CoinPurchaseSheet> {
  bool _isLoading = false;
  String? _errorMessage;
  final InAppPurchaseService _iapService = InAppPurchaseService.instance;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    final initialized = await _iapService.initialize();
    if (!initialized && mounted) {
      setState(() {
        _errorMessage = 'In-app purchases are not available on this device';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buy Coins',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<PremiumBloc, PremiumState>(
                        builder: (context, state) {
                          int balance = 0;
                          if (state is PremiumLoaded) {
                            balance = state.coinBalance.totalCoins;
                          }
                          return Text(
                            'Current Balance: $balance coins',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // What can you do with coins section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What can you do with coins?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCoinUsageItem(
                    Icons.rocket_launch, 'Boost your profile', '5 coins'),
                _buildCoinUsageItem(
                    Icons.star, 'Send Super Likes', '1 coin each'),
                _buildCoinUsageItem(
                    Icons.visibility, 'See who viewed you', '3 coins'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Coin packages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: CoinPackages.all.length,
              itemBuilder: (context, index) {
                final package = CoinPackages.all[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CoinPackageCard(
                    package: package,
                    onTap: () => _purchasePackage(package),
                    isLoading: _isLoading,
                  ),
                );
              },
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextButton(
                  onPressed: _restorePurchases,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coins never expire and are non-refundable',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinUsageItem(IconData icon, String text, String coins) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            coins,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchasePackage(CoinPackage package) async {
    if (!_iapService.isAvailable) {
      setState(() {
        _errorMessage = 'In-app purchases are not available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the product details from the store
      final product = _iapService.getProduct(package.id);
      
      if (product == null) {
        throw Exception('Product not found in store');
      }

      // Show confirmation dialog with real store price
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Text(
            'Buy ${package.totalCoins} coins for ${product.price}?'
            '${package.bonusCoins > 0 ? '\n\nIncludes ${package.bonusCoins} bonus coins!' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Purchase',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Listen for purchase completion
      final purchaseSubscription = _iapService.purchaseStream.listen(
        (purchaseDetails) async {
          AppLogger.info('Purchase completed: ${purchaseDetails.productID}');
          
          // Verify with backend using the purchase receipt
          if (!mounted) return;
          
          final receiptData = purchaseDetails.verificationData.serverVerificationData;
          
          context.read<PremiumBloc>().add(
                PurchaseCoins(
                  coinPackageId: package.id,
                  paymentMethodId: receiptData, // Send receipt to backend for verification
                ),
              );

          // Show success message
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully purchased ${package.totalCoins} coins!',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );

          // Close the sheet
          if (!mounted) return;
          Navigator.pop(context);
        },
        onError: (error) {
          AppLogger.error('Purchase error: $error');
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          }
        },
      );

      // Initiate the purchase through the store
      final success = await _iapService.purchaseCoinPackage(package.id);
      
      if (!success) {
        await purchaseSubscription.cancel();
        throw Exception('Failed to initiate purchase');
      }

      // Wait a bit for the purchase to process
      await Future.delayed(const Duration(seconds: 1));
      await purchaseSubscription.cancel();
      
    } catch (e) {
      AppLogger.error('Purchase failed: $e');
      setState(() {
        _errorMessage = 'Purchase failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _iapService.restorePurchases();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking for previous purchases...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh coin balance after restore
      context.read<PremiumBloc>().add(LoadCoinBalance());
      
    } catch (e) {
      AppLogger.error('Restore purchases failed: $e');
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Purchases'),
          content: Text(
            'Failed to restore purchases: ${e.toString()}\n\n'
            'Your coin balance is automatically synced with your account. '
            'If you believe there\'s a discrepancy, please contact support.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
