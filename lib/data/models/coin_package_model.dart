/// Coin package model for in-app purchases
class CoinPackage {
  final String id;
  final int coinAmount;
  final int bonusCoins;
  final double price;
  final String currency;
  final bool isPopular;
  final String? description;

  CoinPackage({
    required this.id,
    required this.coinAmount,
    required this.bonusCoins,
    required this.price,
    this.currency = 'ZAR',
    this.isPopular = false,
    this.description,
  });

  /// Total coins user will receive (base + bonus)
  int get totalCoins => coinAmount + bonusCoins;

  /// Price per coin
  double get pricePerCoin => price / totalCoins;

  /// Savings percentage compared to base package
  double savingsPercentage(CoinPackage basePackage) {
    if (basePackage.pricePerCoin == 0) return 0;
    return ((basePackage.pricePerCoin - pricePerCoin) /
            basePackage.pricePerCoin) * 100;
  }

  /// Formatted price string
  String get formattedPrice {
    switch (currency) {
      case 'ZAR':
        return 'R ${price.toStringAsFixed(2)}';
      case 'USD':
        return '\$${price.toStringAsFixed(2)}';
      case 'EUR':
        return '€${price.toStringAsFixed(2)}';
      case 'GBP':
        return '£${price.toStringAsFixed(2)}';
      default:
        return '$currency ${price.toStringAsFixed(2)}';
    }
  }

  /// Display text for coin amount
  String get coinDisplayText {
    if (bonusCoins > 0) {
      return '$coinAmount + $bonusCoins bonus';
    }
    return '$coinAmount coins';
  }

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: json['id'] as String,
      coinAmount: json['coinAmount'] as int,
      bonusCoins: json['bonusCoins'] as int? ?? 0,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'ZAR',
      isPopular: json['isPopular'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coinAmount': coinAmount,
      'bonusCoins': bonusCoins,
      'price': price,
      'currency': currency,
      'isPopular': isPopular,
      'description': description,
    };
  }

  /// Default coin packages (fallback if backend doesn't provide)
  static List<CoinPackage> get defaultPackages => [
    CoinPackage(
      id: 'coins_10',
      coinAmount: 10,
      bonusCoins: 0,
      price: 19.99,
      description: 'Starter pack',
    ),
    CoinPackage(
      id: 'coins_30',
      coinAmount: 30,
      bonusCoins: 5,
      price: 49.99,
      description: 'Popular choice',
    ),
    CoinPackage(
      id: 'coins_60',
      coinAmount: 60,
      bonusCoins: 15,
      price: 89.99,
      isPopular: true,
      description: 'Best value',
    ),
    CoinPackage(
      id: 'coins_120',
      coinAmount: 120,
      bonusCoins: 40,
      price: 149.99,
      isPopular: true,
      description: 'Ultimate pack',
    ),
  ];

  @override
  String toString() {
    return 'CoinPackage(id: $id, coins: $totalCoins, price: $formattedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoinPackage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
