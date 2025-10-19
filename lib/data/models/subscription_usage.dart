import 'package:equatable/equatable.dart';

/// Tracks subscription feature usage
class SubscriptionUsage extends Equatable {
  final String subscriptionId;
  final String planId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, UsageCounter> usage;
  final DateTime lastUpdated;

  const SubscriptionUsage({
    required this.subscriptionId,
    required this.planId,
    required this.periodStart,
    required this.periodEnd,
    required this.usage,
    required this.lastUpdated,
  });

  /// Create empty usage tracker
  factory SubscriptionUsage.empty() {
    final now = DateTime.now();
    return SubscriptionUsage(
      subscriptionId: '',
      planId: '',
      periodStart: now,
      periodEnd: now,
      usage: {},
      lastUpdated: now,
    );
  }

  /// Create from JSON
  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    final usageMap = <String, UsageCounter>{};
    if (json['usage'] is Map<String, dynamic>) {
      for (final entry in (json['usage'] as Map<String, dynamic>).entries) {
        usageMap[entry.key] = UsageCounter.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return SubscriptionUsage(
      subscriptionId: json['subscriptionId'] as String,
      planId: json['planId'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      usage: usageMap,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final usageMap = <String, dynamic>{};
    for (final entry in usage.entries) {
      usageMap[entry.key] = entry.value.toJson();
    }

    return {
      'subscriptionId': subscriptionId,
      'planId': planId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'usage': usageMap,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Get usage for a specific feature
  UsageCounter getFeatureUsage(String featureId) {
    return usage[featureId] ?? UsageCounter.zero(featureId);
  }

  /// Check if a feature is available
  bool isFeatureAvailable(String featureId, {int? limit}) {
    final counter = getFeatureUsage(featureId);
    return limit == null || counter.count < limit;
  }

  /// Copy with updates
  SubscriptionUsage copyWith({
    String? subscriptionId,
    String? planId,
    DateTime? periodStart,
    DateTime? periodEnd,
    Map<String, UsageCounter>? usage,
    DateTime? lastUpdated,
  }) {
    return SubscriptionUsage(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      planId: planId ?? this.planId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      usage: usage ?? this.usage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    subscriptionId,
    planId,
    periodStart,
    periodEnd,
    usage,
    lastUpdated,
  ];
}

/// Individual feature usage counter
class UsageCounter extends Equatable {
  final String featureId;
  final int count;
  final int? limit;
  final DateTime lastUsed;
  final Map<String, dynamic>? metadata;

  const UsageCounter({
    required this.featureId,
    required this.count,
    this.limit,
    required this.lastUsed,
    this.metadata,
  });

  /// Create zero counter
  factory UsageCounter.zero(String featureId) {
    return UsageCounter(
      featureId: featureId,
      count: 0,
      lastUsed: DateTime.now(),
    );
  }

  /// Create from JSON
  factory UsageCounter.fromJson(Map<String, dynamic> json) {
    return UsageCounter(
      featureId: json['featureId'] as String,
      count: json['count'] as int,
      limit: json['limit'] as int?,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'featureId': featureId,
      'count': count,
      'limit': limit,
      'lastUsed': lastUsed.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Increment usage
  UsageCounter increment({Map<String, dynamic>? metadata}) {
    return UsageCounter(
      featureId: featureId,
      count: count + 1,
      limit: limit,
      lastUsed: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if limit is reached
  bool get isLimitReached => limit != null && count >= limit!;

  /// Get remaining usage
  int get remaining => limit == null ? -1 : (limit! - count).clamp(0, limit!);

  @override
  List<Object?> get props => [featureId, count, limit, lastUsed, metadata];
}
