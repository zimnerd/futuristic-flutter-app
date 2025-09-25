class StatisticsModel {
  final int profileViews;
  final int matchesCount;
  final int likesSent;
  final int likesReceived;
  final int messagesSent;
  final int messagesReceived;
  final int avgResponseTime; // in minutes
  final int conversationsStarted;
  final int newMatches;
  final int profileCompleteness;

  const StatisticsModel({
    required this.profileViews,
    required this.matchesCount,
    required this.likesSent,
    required this.likesReceived,
    required this.messagesSent,
    required this.messagesReceived,
    required this.avgResponseTime,
    required this.conversationsStarted,
    required this.newMatches,
    required this.profileCompleteness,
  });

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      profileViews: json['profileViews'] ?? 0,
      matchesCount: json['matchesCount'] ?? 0,
      likesSent: json['likesSent'] ?? 0,
      likesReceived: json['likesReceived'] ?? 0,
      messagesSent: json['messagesSent'] ?? 0,
      messagesReceived: json['messagesReceived'] ?? 0,
      avgResponseTime: json['avgResponseTime'] ?? 0,
      conversationsStarted: json['conversationsStarted'] ?? 0,
      newMatches: json['newMatches'] ?? 0,
      profileCompleteness: json['profileCompleteness'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileViews': profileViews,
      'matchesCount': matchesCount,
      'likesSent': likesSent,
      'likesReceived': likesReceived,
      'messagesSent': messagesSent,
      'messagesReceived': messagesReceived,
      'avgResponseTime': avgResponseTime,
      'conversationsStarted': conversationsStarted,
      'newMatches': newMatches,
      'profileCompleteness': profileCompleteness,
    };
  }
}

class HeatmapData {
  final double latitude;
  final double longitude;
  final int userCount;
  final String status; // 'matched', 'liked_me', 'unmatched'

  const HeatmapData({
    required this.latitude,
    required this.longitude,
    required this.userCount,
    required this.status,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      userCount: json['userCount'] ?? 0,
      status: json['status'] ?? 'unmatched',
    );
  }
}