import 'package:equatable/equatable.dart';

/// Entity representing a user report for violations
class Report extends Equatable {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? conversationId;
  final String? messageId;
  final String? contentId;
  final String type; // 'profile', 'conversation', 'message', 'photo', etc.
  final String reason;
  final String? description;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Report({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.conversationId,
    this.messageId,
    this.contentId,
    required this.type,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    reporterId,
    reportedUserId,
    conversationId,
    messageId,
    contentId,
    type,
    reason,
    description,
    status,
    createdAt,
    updatedAt,
  ];

  /// Create a copy of this report with some properties changed
  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? conversationId,
    String? messageId,
    String? contentId,
    String? type,
    String? reason,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
      contentId: contentId ?? this.contentId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert Report to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      if (reportedUserId != null) 'reportedUserId': reportedUserId,
      if (conversationId != null) 'conversationId': conversationId,
      if (messageId != null) 'messageId': messageId,
      if (contentId != null) 'contentId': contentId,
      'type': type,
      'reason': reason,
      if (description != null) 'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create Report from JSON
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedUserId: json['reportedUserId'] as String?,
      conversationId: json['conversationId'] as String?,
      messageId: json['messageId'] as String?,
      contentId: json['contentId'] as String?,
      type: json['type'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Report(id: $id, type: $type, reason: $reason, status: $status)';
  }
}

/// Common report reasons that can be used across the app
class ReportReasons {
  static const String inappropriateContent = 'inappropriate_content';
  static const String harassment = 'harassment';
  static const String spam = 'spam';
  static const String fakeProfile = 'fake_profile';
  static const String underage = 'underage';
  static const String violence = 'violence';
  static const String hateSpeech = 'hate_speech';
  static const String scam = 'scam';
  static const String other = 'other';

  static const List<String> all = [
    inappropriateContent,
    harassment,
    spam,
    fakeProfile,
    underage,
    violence,
    hateSpeech,
    scam,
    other,
  ];

  /// Get human-readable reason description
  static String getReasonDescription(String reason) {
    switch (reason) {
      case inappropriateContent:
        return 'Inappropriate Content';
      case harassment:
        return 'Harassment or Bullying';
      case spam:
        return 'Spam or Unwanted Messages';
      case fakeProfile:
        return 'Fake Profile';
      case underage:
        return 'Underage User';
      case violence:
        return 'Violence or Threats';
      case hateSpeech:
        return 'Hate Speech';
      case scam:
        return 'Scam or Fraud';
      case other:
        return 'Other';
      default:
        return reason;
    }
  }
}
