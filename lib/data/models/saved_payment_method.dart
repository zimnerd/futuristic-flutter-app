/// Model for saved payment method data
class SavedPaymentMethod {
  final String id;
  final String token; // Tokenized payment method from PeachPayments
  final String cardType; // Visa, Mastercard, etc.
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;
  final String cardholderName;
  String nickname; // User-friendly name
  bool isDefault;
  final DateTime createdAt;
  DateTime lastUsedAt;

  SavedPaymentMethod({
    required this.id,
    required this.token,
    required this.cardType,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    required this.nickname,
    this.isDefault = false,
    required this.createdAt,
    required this.lastUsedAt,
  });

  /// Create from JSON (for storage/retrieval)
  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String,
      token: json['token'] as String,
      cardType: json['cardType'] as String,
      lastFourDigits: json['lastFourDigits'] as String,
      expiryMonth: json['expiryMonth'] as String,
      expiryYear: json['expiryYear'] as String,
      cardholderName: json['cardholderName'] as String,
      nickname: json['nickname'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
    );
  }

  /// Convert to JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'cardType': cardType,
      'lastFourDigits': lastFourDigits,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardholderName': cardholderName,
      'nickname': nickname,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SavedPaymentMethod copyWith({
    String? id,
    String? token,
    String? cardType,
    String? lastFourDigits,
    String? expiryMonth,
    String? expiryYear,
    String? cardholderName,
    String? nickname,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return SavedPaymentMethod(
      id: id ?? this.id,
      token: token ?? this.token,
      cardType: cardType ?? this.cardType,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      nickname: nickname ?? this.nickname,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Check if payment method is expired
  bool get isExpired {
    final now = DateTime.now();
    final expiryDate = DateTime(
      int.parse('20$expiryYear'),
      int.parse(expiryMonth),
    );
    return expiryDate.isBefore(now);
  }

  /// Get masked card number for display
  String get maskedCardNumber {
    return '**** **** **** $lastFourDigits';
  }

  /// Get display name (nickname or generated name)
  String get displayName {
    return nickname.isNotEmpty
        ? nickname
        : '$cardType ending in $lastFourDigits';
  }

  /// Get card brand icon name
  String get cardIconName {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return 'visa';
      case 'mastercard':
        return 'mastercard';
      case 'american express':
        return 'amex';
      case 'discover':
        return 'discover';
      default:
        return 'credit_card';
    }
  }

  @override
  String toString() {
    return 'SavedPaymentMethod(id: $id, cardType: $cardType, lastFour: $lastFourDigits, nickname: $nickname)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedPaymentMethod && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
