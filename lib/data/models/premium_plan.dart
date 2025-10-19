import 'package:equatable/equatable.dart';

/// Premium plan model
class PremiumPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // monthly, yearly
  final int intervalCount;
  final List<String> features;
  final Map<String, dynamic> limits;
  final bool isActive;
  final bool isPopular;
  final String? badge;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PremiumPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'USD',
    this.interval = 'monthly',
    this.intervalCount = 1,
    this.features = const [],
    this.limits = const {},
    this.isActive = true,
    this.isPopular = false,
    this.badge,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create PremiumPlan from JSON
  factory PremiumPlan.fromJson(Map<String, dynamic> json) {
    return PremiumPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      interval: json['interval'] as String? ?? 'monthly',
      intervalCount: json['intervalCount'] as int? ?? 1,
      features: (json['features'] as List?)?.cast<String>() ?? [],
      limits: Map<String, dynamic>.from(json['limits'] ?? {}),
      isActive: json['isActive'] as bool? ?? true,
      isPopular: json['isPopular'] as bool? ?? false,
      badge: json['badge'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert PremiumPlan to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'intervalCount': intervalCount,
      'features': features,
      'limits': limits,
      'isActive': isActive,
      'isPopular': isPopular,
      'badge': badge,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted price string
  String get formattedPrice {
    final currencySymbol = _getCurrencySymbol(currency);
    if (interval == 'yearly') {
      return '$currencySymbol${price.toStringAsFixed(0)}/year';
    }
    return '$currencySymbol${price.toStringAsFixed(0)}/month';
  }

  /// Get monthly equivalent price for yearly plans
  double get monthlyEquivalentPrice {
    if (interval == 'yearly') {
      return price / 12;
    }
    return price;
  }

  /// Get savings percentage for yearly plans
  double? get yearlyDiscount {
    if (interval == 'yearly' && metadata?['monthlyPrice'] != null) {
      final monthlyPrice = metadata!['monthlyPrice'] as double;
      final yearlyMonthlyEquivalent = price / 12;
      return ((monthlyPrice - yearlyMonthlyEquivalent) / monthlyPrice) * 100;
    }
    return null;
  }

  /// Get currency symbol
  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currency;
    }
  }

  /// Check if plan has specific feature
  bool hasFeature(String feature) {
    return features.contains(feature);
  }

  /// Get limit value for specific feature
  dynamic getLimit(String limitKey) {
    return limits[limitKey];
  }

  /// Get tier level (basic = 1, premium = 2, etc.)
  int get tierLevel {
    final tierMap = {
      'basic': 1,
      'premium': 2,
      'plus': 3,
      'platinum': 4,
      'diamond': 5,
    };

    for (final entry in tierMap.entries) {
      if (name.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return 1; // Default to basic
  }

  /// Copy with method for immutable updates
  PremiumPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? interval,
    int? intervalCount,
    List<String>? features,
    Map<String, dynamic>? limits,
    bool? isActive,
    bool? isPopular,
    String? badge,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PremiumPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      interval: interval ?? this.interval,
      intervalCount: intervalCount ?? this.intervalCount,
      features: features ?? this.features,
      limits: limits ?? this.limits,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      badge: badge ?? this.badge,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    currency,
    interval,
    intervalCount,
    features,
    limits,
    isActive,
    isPopular,
    badge,
    metadata,
    createdAt,
    updatedAt,
  ];
}
