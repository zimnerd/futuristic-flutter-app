import 'package:equatable/equatable.dart';

/// User profile statistics model
class ProfileStats extends Equatable {
  final int matchesCount;
  final int likesReceived;
  final int likesSent;
  final int profileViews;
  final int messagesCount;

  const ProfileStats({
    required this.matchesCount,
    required this.likesReceived,
    required this.likesSent,
    required this.profileViews,
    this.messagesCount = 0,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      matchesCount: json['matchesCount'] ?? json['matches'] ?? 0,
      likesReceived: json['likesReceived'] ?? json['receivedLikes'] ?? 0,
      likesSent: json['likesSent'] ?? json['sentLikes'] ?? 0,
      profileViews: json['profileViews'] ?? json['views'] ?? 0,
      messagesCount: json['messagesCount'] ?? json['messages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchesCount': matchesCount,
      'likesReceived': likesReceived,
      'likesSent': likesSent,
      'profileViews': profileViews,
      'messagesCount': messagesCount,
    };
  }

  ProfileStats copyWith({
    int? matchesCount,
    int? likesReceived,
    int? likesSent,
    int? profileViews,
    int? messagesCount,
  }) {
    return ProfileStats(
      matchesCount: matchesCount ?? this.matchesCount,
      likesReceived: likesReceived ?? this.likesReceived,
      likesSent: likesSent ?? this.likesSent,
      profileViews: profileViews ?? this.profileViews,
      messagesCount: messagesCount ?? this.messagesCount,
    );
  }

  @override
  List<Object?> get props => [
    matchesCount,
    likesReceived,
    likesSent,
    profileViews,
    messagesCount,
  ];

  @override
  String toString() =>
      'ProfileStats(matches: $matchesCount, likesReceived: $likesReceived, '
      'likesSent: $likesSent, views: $profileViews, messages: $messagesCount)';
}
