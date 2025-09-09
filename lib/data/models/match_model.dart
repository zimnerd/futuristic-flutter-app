/// Simple match model without complex JSON generation
/// Part of the clean architecture - easy to read and maintain
class MatchModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final bool isMatched;
  final double compatibilityScore;
  final Map<String, dynamic>? matchReasons;
  final String status; // pending, matched, rejected, expired
  final DateTime? matchedAt;
  final DateTime? rejectedAt;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.isMatched = false,
    this.compatibilityScore = 0.0,
    this.matchReasons,
    this.status = 'pending',
    this.matchedAt,
    this.rejectedAt,
    this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Simple JSON methods without code generation
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? '',
      user1Id: json['user1Id'] ?? '',
      user2Id: json['user2Id'] ?? '',
      isMatched: json['isMatched'] ?? false,
      compatibilityScore: (json['compatibilityScore'] ?? 0.0).toDouble(),
      matchReasons: json['matchReasons'] != null
          ? Map<String, dynamic>.from(json['matchReasons'])
          : null,
      status: json['status'] ?? 'pending',
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.parse(json['expiredAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'isMatched': isMatched,
      'compatibilityScore': compatibilityScore,
      'matchReasons': matchReasons,
      'status': status,
      'matchedAt': matchedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'expiredAt': expiredAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MatchModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    bool? isMatched,
    double? compatibilityScore,
    Map<String, dynamic>? matchReasons,
    String? status,
    DateTime? matchedAt,
    DateTime? rejectedAt,
    DateTime? expiredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      isMatched: isMatched ?? this.isMatched,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      matchReasons: matchReasons ?? this.matchReasons,
      status: status ?? this.status,
      matchedAt: matchedAt ?? this.matchedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MatchModel(id: $id, status: $status, score: $compatibilityScore)';
}
