/// Payment-related entities for the PulseLink payment system

enum PaymentType {
  boost,
  premium,
  gift,
  credit,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

enum CardType {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}

/// Payment method entity representing saved payment methods
class PaymentMethod {
  final String id;
  final String userId;
  final String cardType;
  final String lastFourDigits;
  final String expiryDate;
  final String cardholderName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.cardType,
    required this.lastFourDigits,
    required this.expiryDate,
    required this.cardholderName,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? cardType,
    String? lastFourDigits,
    String? expiryDate,
    String? cardholderName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardType: cardType ?? this.cardType,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryDate: expiryDate ?? this.expiryDate,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardType': cardType,
      'lastFourDigits': lastFourDigits,
      'expiryDate': expiryDate,
      'cardholderName': cardholderName,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      userId: json['userId'] as String,
      cardType: json['cardType'] as String,
      lastFourDigits: json['lastFourDigits'] as String,
      expiryDate: json['expiryDate'] as String,
      cardholderName: json['cardholderName'] as String,
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethod && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentMethod(id: $id, cardType: $cardType, lastFour: $lastFourDigits)';
  }
}

/// Payment transaction entity
class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentType type;
  final PaymentStatus status;
  final String? productId;
  final String? productDescription;
  final String? paymentMethodId;
  final String? transactionId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.productId,
    this.productDescription,
    this.paymentMethodId,
    this.transactionId,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PaymentType? type,
    PaymentStatus? status,
    String? productId,
    String? productDescription,
    String? paymentMethodId,
    String? transactionId,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      productId: productId ?? this.productId,
      productDescription: productDescription ?? this.productDescription,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'status': status.name,
      'productId': productId,
      'productDescription': productDescription,
      'paymentMethodId': paymentMethodId,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: PaymentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentType.boost,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      productId: json['productId'] as String?,
      productDescription: json['productDescription'] as String?,
      paymentMethodId: json['paymentMethodId'] as String?,
      transactionId: json['transactionId'] as String?,
      failureReason: json['failureReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentTransaction(id: $id, amount: $amount, status: $status)';
  }
}

/// Subscription plan entity
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? durationDays,
    List<String>? features,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      durationDays: durationDays ?? this.durationDays,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'durationDays': durationDays,
      'features': features,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      durationDays: json['durationDays'] as int,
      features: (json['features'] as List<dynamic>).cast<String>(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, price: $price)';
  }
}

/// Refund request entity
class RefundRequest {
  final String id;
  final String transactionId;
  final String userId;
  final double amount;
  final String reason;
  final PaymentStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RefundRequest({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  RefundRequest copyWith({
    String? id,
    String? transactionId,
    String? userId,
    double? amount,
    String? reason,
    PaymentStatus? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'status': status.name,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      adminNotes: json['adminNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefundRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RefundRequest(id: $id, amount: $amount, status: $status)';
  }
}
