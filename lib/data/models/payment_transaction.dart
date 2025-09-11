import 'package:equatable/equatable.dart';

/// Payment history transaction model
class PaymentTransaction extends Equatable {
  final String id;
  final String userId;
  final String? subscriptionId;
  final double amount;
  final String currency;
  final PaymentTransactionType type;
  final PaymentTransactionStatus status;
  final String? paymentMethodId;
  final String description;
  final DateTime processedAt;
  final String? refundId;
  final String? failureReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.paymentMethodId,
    required this.description,
    required this.processedAt,
    this.refundId,
    this.failureReason,
    this.metadata,
    required this.createdAt,
  });

  /// Create from JSON
  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subscriptionId: json['subscriptionId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: PaymentTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentTransactionType.payment,
      ),
      status: PaymentTransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentTransactionStatus.pending,
      ),
      paymentMethodId: json['paymentMethodId'] as String?,
      description: json['description'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String),
      refundId: json['refundId'] as String?,
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'status': status.name,
      'paymentMethodId': paymentMethodId,
      'description': description,
      'processedAt': processedAt.toIso8601String(),
      'refundId': refundId,
      'failureReason': failureReason,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with updates
  PaymentTransaction copyWith({
    String? id,
    String? userId,
    String? subscriptionId,
    double? amount,
    String? currency,
    PaymentTransactionType? type,
    PaymentTransactionStatus? status,
    String? paymentMethodId,
    String? description,
    DateTime? processedAt,
    String? refundId,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      description: description ?? this.description,
      processedAt: processedAt ?? this.processedAt,
      refundId: refundId ?? this.refundId,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        subscriptionId,
        amount,
        currency,
        type,
        status,
        paymentMethodId,
        description,
        processedAt,
        refundId,
        failureReason,
        metadata,
        createdAt,
      ];
}

/// Payment transaction types
enum PaymentTransactionType {
  payment,
  refund,
  subscription,
  upgrade,
  cancellation,
}

/// Payment transaction status
enum PaymentTransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

/// Payment history filter options
class PaymentHistoryFilter {
  final PaymentTransactionType? type;
  final PaymentTransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? subscriptionId;
  final double? minAmount;
  final double? maxAmount;

  const PaymentHistoryFilter({
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.subscriptionId,
    this.minAmount,
    this.maxAmount,
  });

  /// Check if transaction matches filter
  bool matches(PaymentTransaction transaction) {
    if (type != null && transaction.type != type) return false;
    if (status != null && transaction.status != status) return false;
    if (subscriptionId != null && transaction.subscriptionId != subscriptionId) return false;
    if (minAmount != null && transaction.amount < minAmount!) return false;
    if (maxAmount != null && transaction.amount > maxAmount!) return false;
    
    if (startDate != null && transaction.processedAt.isBefore(startDate!)) return false;
    if (endDate != null && transaction.processedAt.isAfter(endDate!)) return false;
    
    return true;
  }
}
