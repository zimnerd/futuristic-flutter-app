import 'package:equatable/equatable.dart';
import 'premium_plan.dart';

/// Subscription status enum
enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  expired,
  pending,
  failed,
  pendingCancellation,
  pastDue,
  suspended,
}

/// Subscription model
class Subscription extends Equatable {
  final String id;
  final String userId;
  final String planId;
  final PremiumPlan? plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final bool autoRenew;
  final String? paymentMethodId;
  final double amountPaid;
  final String currency;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.plan,
    this.status = SubscriptionStatus.pending,
    required this.startDate,
    this.endDate,
    this.cancelledAt,
    this.cancellationReason,
    this.autoRenew = true,
    this.paymentMethodId,
    required this.amountPaid,
    this.currency = 'USD',
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Subscription from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      plan: json['plan'] != null
          ? PremiumPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      status: _parseSubscriptionStatus(json['status'] as String?),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      autoRenew: json['autoRenew'] as bool? ?? true,
      paymentMethodId: json['paymentMethodId'] as String?,
      amountPaid: (json['amountPaid'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Subscription to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'plan': plan?.toJson(),
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'autoRenew': autoRenew,
      'paymentMethodId': paymentMethodId,
      'amountPaid': amountPaid,
      'currency': currency,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parse subscription status from string
  static SubscriptionStatus _parseSubscriptionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'inactive':
        return SubscriptionStatus.inactive;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'failed':
        return SubscriptionStatus.failed;
      default:
        return SubscriptionStatus.pending;
    }
  }

  /// Check if subscription is currently active
  bool get isActive {
    if (status != SubscriptionStatus.active) return false;
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Check if subscription is cancelled
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  /// Check if subscription is expired
  bool get isExpired {
    if (status == SubscriptionStatus.expired) return true;
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Get days remaining in subscription
  int? get daysRemaining {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  /// Get renewal date
  DateTime? get renewalDate {
    if (!autoRenew || status != SubscriptionStatus.active) return null;
    return endDate;
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case SubscriptionStatus.active:
        return isActive ? 'Active' : 'Expired';
      case SubscriptionStatus.inactive:
        return 'Inactive';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.pending:
        return 'Pending';
      case SubscriptionStatus.failed:
        return 'Failed';
      case SubscriptionStatus.pendingCancellation:
        return 'Cancelling';
      case SubscriptionStatus.pastDue:
        return 'Past Due';
      case SubscriptionStatus.suspended:
        return 'Suspended';
    }
  }

  /// Get formatted amount paid
  String get formattedAmountPaid {
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${amountPaid.toStringAsFixed(2)}';
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

  /// Copy with method for immutable updates
  Subscription copyWith({
    String? id,
    String? userId,
    String? planId,
    PremiumPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? cancelledAt,
    String? cancellationReason,
    bool? autoRenew,
    String? paymentMethodId,
    double? amountPaid,
    String? currency,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        planId,
        plan,
        status,
        startDate,
        endDate,
        cancelledAt,
        cancellationReason,
        autoRenew,
        paymentMethodId,
        amountPaid,
        currency,
        metadata,
        createdAt,
        updatedAt,
      ];
}
