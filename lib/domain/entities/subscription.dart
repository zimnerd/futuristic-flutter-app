import 'package:equatable/equatable.dart';

/// Subscription entity for premium features
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.period,
    required this.features,
    this.isPopular = false,
    this.discountPercent = 0,
    this.trialDays = 0,
    this.isActive = false,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String period; // 'month', 'year', 'week'
  final List<String> features;
  final bool isPopular;
  final int discountPercent;
  final int trialDays;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// Check if subscription is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get days remaining for subscription
  int get daysRemaining {
    if (expiresAt == null) return -1;
    final difference = expiresAt!.difference(DateTime.now());
    return difference.inDays;
  }

  /// Check if subscription is in trial period
  bool get isInTrial {
    if (trialDays == 0 || createdAt == null) return false;
    final trialEnd = createdAt!.add(Duration(days: trialDays));
    return DateTime.now().isBefore(trialEnd);
  }

  /// Get savings amount compared to original price
  double get savingsAmount => originalPrice - price;

  /// Get savings percentage
  double get savingsPercent {
    if (originalPrice == 0) return 0;
    return ((originalPrice - price) / originalPrice) * 100;
  }

  /// Get formatted price string
  String get formattedPrice {
    return '\$${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  }

  /// Get formatted original price string
  String get formattedOriginalPrice {
    return '\$${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)}';
  }

  /// Get period display string
  String get periodDisplay {
    switch (period.toLowerCase()) {
      case 'month':
        return 'month';
      case 'year':
        return 'year';
      case 'week':
        return 'week';
      default:
        return period;
    }
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? period,
    List<String>? features,
    bool? isPopular,
    int? discountPercent,
    int? trialDays,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      period: period ?? this.period,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
      discountPercent: discountPercent ?? this.discountPercent,
      trialDays: trialDays ?? this.trialDays,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create Subscription from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      isPopular: json['isPopular'] as bool? ?? false,
      discountPercent: json['discountPercent'] as int? ?? 0,
      trialDays: json['trialDays'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert Subscription to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'period': period,
      'features': features,
      'isPopular': isPopular,
      'discountPercent': discountPercent,
      'trialDays': trialDays,
      'isActive': isActive,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        originalPrice,
        period,
        features,
        isPopular,
        discountPercent,
        trialDays,
        isActive,
        expiresAt,
        createdAt,
      ];
}

/// Premium feature entity
class PremiumFeature extends Equatable {
  const PremiumFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isEnabled = false,
    this.requiredPlan,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isEnabled;
  final String? requiredPlan;

  PremiumFeature copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isEnabled,
    String? requiredPlan,
  }) {
    return PremiumFeature(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isEnabled: isEnabled ?? this.isEnabled,
      requiredPlan: requiredPlan ?? this.requiredPlan,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        isEnabled,
        requiredPlan,
      ];
}
