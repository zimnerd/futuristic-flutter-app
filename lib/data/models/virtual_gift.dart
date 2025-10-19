import 'package:equatable/equatable.dart';

/// Represents a virtual gift that can be sent
class VirtualGift extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String? animationUrl;
  final int price; // in credits or cents
  final GiftCategory category;
  final GiftRarity rarity;
  final bool isActive;
  final DateTime createdAt;

  const VirtualGift({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.animationUrl,
    required this.price,
    required this.category,
    required this.rarity,
    this.isActive = true,
    required this.createdAt,
  });

  factory VirtualGift.fromJson(Map<String, dynamic> json) {
    return VirtualGift(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      animationUrl: json['animationUrl'] as String?,
      price: json['price'] as int,
      category: GiftCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GiftCategory.flowers,
      ),
      rarity: GiftRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => GiftRarity.common,
      ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'animationUrl': animationUrl,
      'price': price,
      'category': category.name,
      'rarity': rarity.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconUrl,
    animationUrl,
    price,
    category,
    rarity,
    isActive,
    createdAt,
  ];
}

/// Gift categories for organization
enum GiftCategory {
  flowers('Flowers & Nature', '🌸'),
  drinks('Drinks & Food', '🍷'),
  activities('Activities', '🎭'),
  premium('Premium', '👑'),
  seasonal('Seasonal', '🎄'),
  romantic('Romantic', '💕');

  const GiftCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// Gift rarity levels
enum GiftRarity {
  common('Common', 0xFF4CAF50),
  rare('Rare', 0xFF2196F3),
  epic('Epic', 0xFF9C27B0),
  legendary('Legendary', 0xFFFF9800);

  const GiftRarity(this.displayName, this.colorValue);
  final String displayName;
  final int colorValue;
}

/// Represents a gift transaction
class GiftTransaction extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String giftId;
  final String? message;
  final DateTime sentAt;
  final bool isOpened;
  final DateTime? openedAt;
  final VirtualGift? gift;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? receiverName;

  const GiftTransaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.giftId,
    this.message,
    required this.sentAt,
    this.isOpened = false,
    this.openedAt,
    this.gift,
    this.senderName,
    this.senderAvatarUrl,
    this.receiverName,
  });

  factory GiftTransaction.fromJson(Map<String, dynamic> json) {
    return GiftTransaction(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      giftId: json['giftId'] as String,
      message: json['message'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isOpened: json['isOpened'] as bool? ?? false,
      openedAt: json['openedAt'] != null
          ? DateTime.parse(json['openedAt'] as String)
          : null,
      gift: json['gift'] != null
          ? VirtualGift.fromJson(json['gift'] as Map<String, dynamic>)
          : null,
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      receiverName: json['receiverName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'giftId': giftId,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'isOpened': isOpened,
      'openedAt': openedAt?.toIso8601String(),
      'gift': gift?.toJson(),
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverName': receiverName,
    };
  }

  GiftTransaction copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? giftId,
    String? message,
    DateTime? sentAt,
    bool? isOpened,
    DateTime? openedAt,
    VirtualGift? gift,
    String? senderName,
    String? senderAvatarUrl,
    String? receiverName,
  }) {
    return GiftTransaction(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      giftId: giftId ?? this.giftId,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      gift: gift ?? this.gift,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      receiverName: receiverName ?? this.receiverName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    giftId,
    message,
    sentAt,
    isOpened,
    openedAt,
    gift,
    senderName,
    senderAvatarUrl,
    receiverName,
  ];
}

/// User's credits and gift statistics
class UserGiftStats extends Equatable {
  final String userId;
  final int credits;
  final int giftsSent;
  final int giftsReceived;
  final int totalSpent;
  final int totalEarned;
  final List<GiftTransaction> recentTransactions;

  const UserGiftStats({
    required this.userId,
    this.credits = 0,
    this.giftsSent = 0,
    this.giftsReceived = 0,
    this.totalSpent = 0,
    this.totalEarned = 0,
    this.recentTransactions = const [],
  });

  factory UserGiftStats.fromJson(Map<String, dynamic> json) {
    return UserGiftStats(
      userId: json['userId'] as String,
      credits: json['credits'] as int? ?? 0,
      giftsSent: json['giftsSent'] as int? ?? 0,
      giftsReceived: json['giftsReceived'] as int? ?? 0,
      totalSpent: json['totalSpent'] as int? ?? 0,
      totalEarned: json['totalEarned'] as int? ?? 0,
      recentTransactions:
          (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => GiftTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'credits': credits,
      'giftsSent': giftsSent,
      'giftsReceived': giftsReceived,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    userId,
    credits,
    giftsSent,
    giftsReceived,
    totalSpent,
    totalEarned,
    recentTransactions,
  ];
}
