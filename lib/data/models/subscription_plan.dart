/// Billing cycle enum
enum BillingCycle { weekly, monthly, quarterly, yearly }

extension BillingCycleExtension on BillingCycle {
  String get displayName {
    switch (this) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }

  Duration get duration {
    switch (this) {
      case BillingCycle.weekly:
        return const Duration(days: 7);
      case BillingCycle.monthly:
        return const Duration(days: 30);
      case BillingCycle.quarterly:
        return const Duration(days: 90);
      case BillingCycle.yearly:
        return const Duration(days: 365);
    }
  }
}

/// Subscription plan feature
class PlanFeature {
  final String id;
  final String name;
  final String description;
  final int? limit; // null means unlimited
  final String type; // 'boolean', 'numeric', 'text'

  const PlanFeature({
    required this.id,
    required this.name,
    required this.description,
    this.limit,
    required this.type,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      limit: json['limit'] as int?,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'limit': limit,
      'type': type,
    };
  }

  /// Check if feature is unlimited
  bool get isUnlimited => limit == null;

  /// Get display limit text
  String get limitText {
    if (isUnlimited) return 'Unlimited';
    return limit.toString();
  }
}

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final List<PlanFeature> features;
  final bool isPopular;
  final bool isActive;
  final String? promoText;
  final double? originalAmount; // For showing discounts
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.features,
    this.isPopular = false,
    this.isActive = true,
    this.promoText,
    this.originalAmount,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == json['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      features:
          (json['features'] as List?)
              ?.map((f) => PlanFeature.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      isPopular: json['isPopular'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      promoText: json['promoText'] as String?,
      originalAmount: json['originalAmount'] != null
          ? (json['originalAmount'] as num).toDouble()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'billingCycle': billingCycle.name,
      'features': features.map((f) => f.toJson()).toList(),
      'isPopular': isPopular,
      'isActive': isActive,
      'promoText': promoText,
      'originalAmount': originalAmount,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted price
  String get formattedPrice {
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Get formatted price with billing cycle
  String get formattedPriceWithCycle {
    return '$formattedPrice/${billingCycle.displayName.toLowerCase()}';
  }

  /// Check if plan has discount
  bool get hasDiscount {
    return originalAmount != null && originalAmount! > amount;
  }

  /// Get discount percentage
  double? get discountPercentage {
    if (!hasDiscount) return null;
    return ((originalAmount! - amount) / originalAmount!) * 100;
  }

  /// Get formatted discount percentage
  String? get formattedDiscountPercentage {
    final discount = discountPercentage;
    if (discount == null) return null;
    return '${discount.round()}% OFF';
  }

  /// Get feature by ID
  PlanFeature? getFeature(String featureId) {
    try {
      return features.firstWhere((f) => f.id == featureId);
    } catch (e) {
      return null;
    }
  }

  /// Check if plan has specific feature
  bool hasFeature(String featureId) {
    return getFeature(featureId) != null;
  }

  /// Get feature limit
  int? getFeatureLimit(String featureId) {
    return getFeature(featureId)?.limit;
  }

  /// Check if feature is unlimited
  bool isFeatureUnlimited(String featureId) {
    return getFeature(featureId)?.isUnlimited ?? false;
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'ZAR':
        return 'R';
      default:
        return currencyCode;
    }
  }

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, amount: $amount, cycle: ${billingCycle.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined subscription plans
class PredefinedPlans {
  static final DateTime _defaultDate = DateTime(2024, 1, 1);

  static final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'basic_monthly',
      name: 'Basic',
      description: 'Perfect for casual users',
      amount: 9.99,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      features: [
        PlanFeature(
          id: 'matches_per_day',
          name: 'Daily Matches',
          description: 'Number of matches per day',
          limit: 50,
          type: 'numeric',
        ),
        PlanFeature(
          id: 'super_likes',
          name: 'Super Likes',
          description: 'Special likes per day',
          limit: 5,
          type: 'numeric',
        ),
      ],
      createdAt: _defaultDate,
      updatedAt: _defaultDate,
    ),
    SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium',
      description: 'For serious daters',
      amount: 19.99,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      features: [
        PlanFeature(
          id: 'matches_per_day',
          name: 'Daily Matches',
          description: 'Unlimited matches per day',
          limit: null,
          type: 'numeric',
        ),
        PlanFeature(
          id: 'super_likes',
          name: 'Super Likes',
          description: 'Super likes per day',
          limit: 15,
          type: 'numeric',
        ),
        PlanFeature(
          id: 'boost_monthly',
          name: 'Monthly Boost',
          description: 'Profile boost per month',
          limit: 3,
          type: 'numeric',
        ),
      ],
      isPopular: true,
      createdAt: _defaultDate,
      updatedAt: _defaultDate,
    ),
  ];
}
