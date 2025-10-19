import 'package:equatable/equatable.dart';

/// Achievement model
class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final int points;
  final List<String> requirements;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isHidden;
  final int rarity; // 1-5 scale
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    this.points = 0,
    this.requirements = const [],
    this.isUnlocked = false,
    this.unlockedAt,
    this.isHidden = false,
    this.rarity = 1,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Achievement from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      category: json['category'] as String,
      points: json['points'] as int? ?? 0,
      requirements: (json['requirements'] as List?)?.cast<String>() ?? [],
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isHidden: json['isHidden'] as bool? ?? false,
      rarity: json['rarity'] as int? ?? 1,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Achievement to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'category': category,
      'points': points,
      'requirements': requirements,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isHidden': isHidden,
      'rarity': rarity,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get rarity display text
  String get rarityText {
    switch (rarity) {
      case 1:
        return 'Common';
      case 2:
        return 'Uncommon';
      case 3:
        return 'Rare';
      case 4:
        return 'Epic';
      case 5:
        return 'Legendary';
      default:
        return 'Common';
    }
  }

  /// Get rarity color (as hex string)
  String get rarityColor {
    switch (rarity) {
      case 1:
        return '#9E9E9E'; // Grey
      case 2:
        return '#4CAF50'; // Green
      case 3:
        return '#2196F3'; // Blue
      case 4:
        return '#9C27B0'; // Purple
      case 5:
        return '#FF9800'; // Orange/Gold
      default:
        return '#9E9E9E';
    }
  }

  /// Get time since unlocked (if unlocked)
  String? get timeSinceUnlocked {
    if (!isUnlocked || unlockedAt == null) return null;

    final now = DateTime.now();
    final difference = now.difference(unlockedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  /// Check if achievement should be shown to user
  bool get shouldShow => !isHidden || isUnlocked;

  /// Get progress percentage (if metadata contains progress info)
  double? get progressPercentage {
    if (metadata == null) return null;

    final current = metadata!['currentProgress'] as int?;
    final required = metadata!['requiredProgress'] as int?;

    if (current != null && required != null && required > 0) {
      return (current / required).clamp(0.0, 1.0);
    }

    return null;
  }

  /// Copy with method for immutable updates
  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    String? category,
    int? points,
    List<String>? requirements,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isHidden,
    int? rarity,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isHidden: isHidden ?? this.isHidden,
      rarity: rarity ?? this.rarity,
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
    iconUrl,
    category,
    points,
    requirements,
    isUnlocked,
    unlockedAt,
    isHidden,
    rarity,
    metadata,
    createdAt,
    updatedAt,
  ];
}
