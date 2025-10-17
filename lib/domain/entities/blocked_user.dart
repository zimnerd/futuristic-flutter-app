/// Domain entity representing a blocked user
class BlockedUser {
  final String id;
  final String userId;
  final String blockedUserId;
  final DateTime blockedAt;
  final String? reason;

  const BlockedUser({
    required this.id,
    required this.userId,
    required this.blockedUserId,
    required this.blockedAt,
    this.reason,
  });

  /// Creates a copy of this blocked user with the given fields replaced with new values
  BlockedUser copyWith({
    String? id,
    String? userId,
    String? blockedUserId,
    DateTime? blockedAt,
    String? reason,
  }) {
    return BlockedUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      blockedAt: blockedAt ?? this.blockedAt,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BlockedUser &&
        other.id == id &&
        other.userId == userId &&
        other.blockedUserId == blockedUserId &&
        other.blockedAt == blockedAt &&
        other.reason == reason;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        blockedUserId.hashCode ^
        blockedAt.hashCode ^
        reason.hashCode;
  }

  @override
  String toString() {
    return 'BlockedUser(id: $id, userId: $userId, blockedUserId: $blockedUserId, blockedAt: $blockedAt, reason: $reason)';
  }
}
