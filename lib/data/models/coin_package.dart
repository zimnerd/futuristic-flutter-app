import 'package:equatable/equatable.dart';

/// Represents a coin package available for purchase
class CoinPackage extends Equatable {
  final String id;
  final int coins;
  final int bonusCoins;
  final double price;
  final String priceDisplay;
  final bool isMostPopular;
  final bool isBestValue;

  const CoinPackage({
    required this.id,
    required this.coins,
    this.bonusCoins = 0,
    required this.price,
    required this.priceDisplay,
    this.isMostPopular = false,
    this.isBestValue = false,
  });

  /// Total coins including bonus
  int get totalCoins => coins + bonusCoins;

  /// Price per coin (including bonus)
  double get pricePerCoin => price / totalCoins;

  /// Discount percentage from bonus coins
  int get discountPercent {
    if (bonusCoins == 0) return 0;
    return ((bonusCoins / coins) * 100).round();
  }

  @override
  List<Object?> get props => [
        id,
        coins,
        bonusCoins,
        price,
        priceDisplay,
        isMostPopular,
        isBestValue,
      ];
}

/// Standard coin packages
class CoinPackages {
  static const starter = CoinPackage(
    id: 'coins_10',
    coins: 10,
    bonusCoins: 0,
    price: 5.00,
    priceDisplay: '\$5',
  );

  static const popular = CoinPackage(
    id: 'coins_30',
    coins: 30,
    bonusCoins: 0,
    price: 12.00,
    priceDisplay: '\$12',
    isMostPopular: true,
  );

  static const value = CoinPackage(
    id: 'coins_60',
    coins: 60,
    bonusCoins: 5,
    price: 20.00,
    priceDisplay: '\$20',
  );

  static const mega = CoinPackage(
    id: 'coins_120',
    coins: 120,
    bonusCoins: 0,
    price: 35.00,
    priceDisplay: '\$35',
    isBestValue: true,
  );

  static List<CoinPackage> get all => [starter, popular, value, mega];
}
