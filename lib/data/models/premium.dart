import 'package:equatable/equatable.dart';

/// Premium subscription tiers
enum PremiumTier {
  free('Free', 0, []),
  basic('Basic', 999, [
    PremiumFeature.advancedFilters,
    PremiumFeature.unlimitedLikes,
    PremiumFeature.readReceipts,
  ]),
  premium('Premium', 1999, [
    PremiumFeature.advancedFilters,
    PremiumFeature.unlimitedLikes,
    PremiumFeature.readReceipts,
    PremiumFeature.whoLikedYou,
    PremiumFeature.prioritySupport,
    PremiumFeature.customGifts,
  ]),
  elite('Elite', 2999, [
    PremiumFeature.advancedFilters,
    PremiumFeature.unlimitedLikes,
    PremiumFeature.readReceipts,
    PremiumFeature.whoLikedYou,
    PremiumFeature.prioritySupport,
    PremiumFeature.customGifts,
    PremiumFeature.aiCompanion,
    PremiumFeature.conciergeService,
    PremiumFeature.exclusiveEvents,
  ]);

  const PremiumTier(this.displayName, this.priceInCents, this.features);
  final String displayName;
  final int priceInCents; // price in cents for Stripe
  final List<PremiumFeature> features;

  /// Get formatted price string
  String get formattedPrice {
    if (priceInCents == 0) return 'Free';
    final dollars = priceInCents / 100;
    return '\$${dollars.toStringAsFixed(2)}/month';
  }

  /// Check if tier has specific feature
  bool hasFeature(PremiumFeature feature) => features.contains(feature);
}

/// Available premium features
enum PremiumFeature {
  advancedFilters('Advanced Filters', '🔍', 'Filter by education, interests, and more'),
  unlimitedLikes('Unlimited Likes', '💫', 'Like as many profiles as you want'),
  readReceipts('Read Receipts', '✓', 'See when your messages are read'),
  whoLikedYou('Who Liked You', '👀', 'See who liked your profile'),
  prioritySupport('Priority Support', '🎧', '24/7 priority customer support'),
  customGifts('Custom Gifts', '🎁', 'Send personalized virtual gifts'),
  aiCompanion('AI Companion', '🤖', 'Personal AI dating assistant'),
  conciergeService('Concierge Service', '👨‍💼', 'Personal dating concierge'),
  exclusiveEvents('Exclusive Events', '🍾', 'Access to VIP dating events');

  const PremiumFeature(this.displayName, this.icon, this.description);
  final String displayName;
  final String icon;
  final String description;
}

/// User's premium subscription status
class PremiumSubscription extends Equatable {
  final String id;
  final String userId;
  final PremiumTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool autoRenew;
  final String? paymentMethodId;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;
  final List<String> features;

  const PremiumSubscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.autoRenew = true,
    this.paymentMethodId,
    this.lastPaymentDate,
    this.nextPaymentDate,
    this.features = const [],
  });

  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    return PremiumSubscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tier: PremiumTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => PremiumTier.free,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      autoRenew: json['autoRenew'] as bool? ?? true,
      paymentMethodId: json['paymentMethodId'] as String?,
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'] as String)
          : null,
      nextPaymentDate: json['nextPaymentDate'] != null
          ? DateTime.parse(json['nextPaymentDate'] as String)
          : null,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tier': tier.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'paymentMethodId': paymentMethodId,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'nextPaymentDate': nextPaymentDate?.toIso8601String(),
      'features': features,
    };
  }

  /// Check if user has access to specific feature
  bool hasFeature(PremiumFeature feature) {
    return tier.hasFeature(feature) || features.contains(feature.name);
  }

  /// Check if subscription is currently valid
  bool get isValid {
    if (!isActive) return false;
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (endDate == null) return null;
    final difference = endDate!.difference(DateTime.now());
    return difference.inDays;
  }

  PremiumSubscription copyWith({
    String? id,
    String? userId,
    PremiumTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoRenew,
    String? paymentMethodId,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    List<String>? features,
  }) {
    return PremiumSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      features: features ?? this.features,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tier,
        startDate,
        endDate,
        isActive,
        autoRenew,
        paymentMethodId,
        lastPaymentDate,
        nextPaymentDate,
        features,
      ];
}

/// Premium feature usage analytics
class PremiumUsageStats extends Equatable {
  final String userId;
  final Map<String, int> featureUsage;
  final int totalLikes;
  final int totalMatches;
  final int totalMessages;
  final int totalGifts;
  final DateTime lastUpdated;

  const PremiumUsageStats({
    required this.userId,
    this.featureUsage = const {},
    this.totalLikes = 0,
    this.totalMatches = 0,
    this.totalMessages = 0,
    this.totalGifts = 0,
    required this.lastUpdated,
  });

  factory PremiumUsageStats.fromJson(Map<String, dynamic> json) {
    return PremiumUsageStats(
      userId: json['userId'] as String,
      featureUsage: Map<String, int>.from(json['featureUsage'] as Map? ?? {}),
      totalLikes: json['totalLikes'] as int? ?? 0,
      totalMatches: json['totalMatches'] as int? ?? 0,
      totalMessages: json['totalMessages'] as int? ?? 0,
      totalGifts: json['totalGifts'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'featureUsage': featureUsage,
      'totalLikes': totalLikes,
      'totalMatches': totalMatches,
      'totalMessages': totalMessages,
      'totalGifts': totalGifts,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        userId,
        featureUsage,
        totalLikes,
        totalMatches,
        totalMessages,
        totalGifts,
        lastUpdated,
      ];
}

/// Premium subscription benefits info
class PremiumBenefits extends Equatable {
  final PremiumTier tier;
  final List<String> features;
  final List<String> benefits;
  final String monthlyPrice;
  final String yearlyPrice;
  final int yearlySavings;
  final bool isPopular;

  const PremiumBenefits({
    required this.tier,
    required this.features,
    required this.benefits,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.yearlySavings = 0,
    this.isPopular = false,
  });

  factory PremiumBenefits.fromTier(PremiumTier tier) {
    final features = tier.features.map((f) => f.displayName).toList();
    final benefits = tier.features.map((f) => f.description).toList();
    
    return PremiumBenefits(
      tier: tier,
      features: features,
      benefits: benefits,
      monthlyPrice: tier.formattedPrice,
      yearlyPrice: _calculateYearlyPrice(tier.priceInCents),
      yearlySavings: _calculateYearlySavings(tier.priceInCents),
      isPopular: tier == PremiumTier.premium,
    );
  }

  static String _calculateYearlyPrice(int monthlyPriceInCents) {
    if (monthlyPriceInCents == 0) return 'Free';
    final yearlyPriceInCents = monthlyPriceInCents * 10; // 20% discount
    final yearlyDollars = yearlyPriceInCents / 100;
    return '\$${yearlyDollars.toStringAsFixed(2)}/year';
  }

  static int _calculateYearlySavings(int monthlyPriceInCents) {
    if (monthlyPriceInCents == 0) return 0;
    final fullYearPrice = monthlyPriceInCents * 12;
    final discountedYearPrice = monthlyPriceInCents * 10;
    return ((fullYearPrice - discountedYearPrice) / 100).round();
  }

  @override
  List<Object?> get props => [
        tier,
        features,
        benefits,
        monthlyPrice,
        yearlyPrice,
        yearlySavings,
        isPopular,
      ];
}

/// Premium plan information
class PremiumPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final int priceInCents;
  final String currency;
  final String interval; // 'month', 'year'
  final List<String> features;
  final bool isPopular;
  final String? promoText;
  final int? discountPercent;
  final bool isActive;

  const PremiumPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInCents,
    this.currency = 'USD',
    this.interval = 'month',
    this.features = const [],
    this.isPopular = false,
    this.promoText,
    this.discountPercent,
    this.isActive = true,
  });

  factory PremiumPlan.fromJson(Map<String, dynamic> json) {
    return PremiumPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priceInCents: json['priceInCents'] as int,
      currency: json['currency'] as String? ?? 'USD',
      interval: json['interval'] as String? ?? 'month',
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['isPopular'] as bool? ?? false,
      promoText: json['promoText'] as String?,
      discountPercent: json['discountPercent'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceInCents': priceInCents,
      'currency': currency,
      'interval': interval,
      'features': features,
      'isPopular': isPopular,
      'promoText': promoText,
      'discountPercent': discountPercent,
      'isActive': isActive,
    };
  }

  String get formattedPrice {
    final dollars = priceInCents / 100;
    return '\$${dollars.toStringAsFixed(2)}/$interval';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        priceInCents,
        currency,
        interval,
        features,
        isPopular,
        promoText,
        discountPercent,
        isActive,
      ];
}

/// User subscription information
class UserSubscription extends Equatable {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final bool autoRenew;
  final String? paymentMethodId;
  final int priceInCents;
  final String currency;
  final String interval;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.autoRenew = true,
    this.paymentMethodId,
    required this.priceInCents,
    this.currency = 'USD',
    this.interval = 'month',
    this.cancelledAt,
    this.cancelReason,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.inactive,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      nextBillingDate: json['nextBillingDate'] != null ? DateTime.parse(json['nextBillingDate'] as String) : null,
      autoRenew: json['autoRenew'] as bool? ?? true,
      paymentMethodId: json['paymentMethodId'] as String?,
      priceInCents: json['priceInCents'] as int,
      currency: json['currency'] as String? ?? 'USD',
      interval: json['interval'] as String? ?? 'month',
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      cancelReason: json['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextBillingDate': nextBillingDate?.toIso8601String(),
      'autoRenew': autoRenew,
      'paymentMethodId': paymentMethodId,
      'priceInCents': priceInCents,
      'currency': currency,
      'interval': interval,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
    };
  }

  bool get isActive => status == SubscriptionStatus.active;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  bool get isPastDue => status == SubscriptionStatus.pastDue;

  @override
  List<Object?> get props => [
        id,
        userId,
        planId,
        planName,
        status,
        startDate,
        endDate,
        nextBillingDate,
        autoRenew,
        paymentMethodId,
        priceInCents,
        currency,
        interval,
        cancelledAt,
        cancelReason,
      ];
}

/// Subscription status enum
enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  pastDue,
  suspended,
  expired,
}

/// Premium feature types
enum PremiumFeatureType {
  boost,
  superLike,
  rewind,
  readReceipts,
  unlimitedLikes,
  whoLikedYou,
  advancedFilters,
  prioritySupport,
  customGifts,
  aiCompanion,
  conciergeService,
  exclusiveEvents,
}

/// Purchase result information
class PurchaseResult extends Equatable {
  final String id;
  final String userId;
  final String transactionId;
  final int amount;
  final String currency;
  final String itemType; // 'coins', 'subscription', 'feature'
  final String itemId;
  final DateTime purchaseDate;
  final bool isSuccessful;
  final String? errorMessage;

  const PurchaseResult({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.amount,
    this.currency = 'USD',
    required this.itemType,
    required this.itemId,
    required this.purchaseDate,
    this.isSuccessful = true,
    this.errorMessage,
  });

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      transactionId: json['transactionId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String? ?? 'USD',
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      isSuccessful: json['isSuccessful'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'itemType': itemType,
      'itemId': itemId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'isSuccessful': isSuccessful,
      'errorMessage': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        transactionId,
        amount,
        currency,
        itemType,
        itemId,
        purchaseDate,
        isSuccessful,
        errorMessage,
      ];
}

/// Coin balance information
class CoinBalance extends Equatable {
  final String userId;
  final int totalCoins;
  final int earnedCoins;
  final int purchasedCoins;
  final int spentCoins;
  final DateTime lastUpdated;

  const CoinBalance({
    required this.userId,
    required this.totalCoins,
    this.earnedCoins = 0,
    this.purchasedCoins = 0,
    this.spentCoins = 0,
    required this.lastUpdated,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      userId: json['userId'] as String,
      totalCoins: json['totalCoins'] as int,
      earnedCoins: json['earnedCoins'] as int? ?? 0,
      purchasedCoins: json['purchasedCoins'] as int? ?? 0,
      spentCoins: json['spentCoins'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalCoins': totalCoins,
      'earnedCoins': earnedCoins,
      'purchasedCoins': purchasedCoins,
      'spentCoins': spentCoins,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        userId,
        totalCoins,
        earnedCoins,
        purchasedCoins,
        spentCoins,
        lastUpdated,
      ];
}

/// Coin transaction information
class CoinTransaction extends Equatable {
  final String id;
  final String userId;
  final int amount;
  final CoinTransactionType type;
  final String description;
  final String? relatedId; // related purchase, gift, etc.
  final DateTime createdAt;

  const CoinTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.relatedId,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: json['amount'] as int,
      type: CoinTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CoinTransactionType.other,
      ),
      description: json['description'] as String,
      relatedId: json['relatedId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'relatedId': relatedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        type,
        description,
        relatedId,
        createdAt,
      ];
}

/// Coin transaction types
enum CoinTransactionType {
  purchase,
  earned,
  spent,
  refund,
  bonus,
  gift,
  other,
}

/// Promo code result
class PromoCodeResult extends Equatable {
  final String promoCode;
  final bool isValid;
  final String? discountType; // 'percentage', 'fixed_amount', 'free_trial'
  final int? discountValue;
  final String? description;
  final DateTime? expiryDate;
  final bool isRedeemed;
  final String? errorMessage;

  const PromoCodeResult({
    required this.promoCode,
    required this.isValid,
    this.discountType,
    this.discountValue,
    this.description,
    this.expiryDate,
    this.isRedeemed = false,
    this.errorMessage,
  });

  factory PromoCodeResult.fromJson(Map<String, dynamic> json) {
    return PromoCodeResult(
      promoCode: json['promoCode'] as String,
      isValid: json['isValid'] as bool,
      discountType: json['discountType'] as String?,
      discountValue: json['discountValue'] as int?,
      description: json['description'] as String?,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      isRedeemed: json['isRedeemed'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promoCode': promoCode,
      'isValid': isValid,
      'discountType': discountType,
      'discountValue': discountValue,
      'description': description,
      'expiryDate': expiryDate?.toIso8601String(),
      'isRedeemed': isRedeemed,
      'errorMessage': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
        promoCode,
        isValid,
        discountType,
        discountValue,
        description,
        expiryDate,
        isRedeemed,
        errorMessage,
      ];
}
