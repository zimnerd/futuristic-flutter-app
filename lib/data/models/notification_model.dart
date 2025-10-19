import 'package:equatable/equatable.dart';

/// Model representing a notification
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  final bool isRead;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      type: NotificationType.values.byName(json['type']),
      title: json['title'],
      message: json['message'],
      data: json['data'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      isRead: json['isRead'] ?? false,
      priority: NotificationPriority.values.byName(
        json['priority'] ?? 'normal',
      ),
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    message,
    data,
    imageUrl,
    actionUrl,
    isRead,
    priority,
    createdAt,
    readAt,
  ];
}

/// Types of notifications
enum NotificationType {
  newMessage,
  newMatch,
  profileView,
  like,
  superLike,
  incomingCall,
  missedCall,
  newFollower,
  friendRequest,
  system,
  promotion,
  reminder,
  verification,
  security,
  payment,
}

/// Notification priority levels
enum NotificationPriority { low, normal, high, urgent }

/// Model for notification settings
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.newMessages = true,
    this.newMatches = true,
    this.profileViews = true,
    this.likes = true,
    this.calls = true,
    this.system = true,
    this.promotions = false,
    this.reminders = true,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  final bool newMessages;
  final bool newMatches;
  final bool profileViews;
  final bool likes;
  final bool calls;
  final bool system;
  final bool promotions;
  final bool reminders;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      newMessages: json['newMessages'] ?? true,
      newMatches: json['newMatches'] ?? true,
      profileViews: json['profileViews'] ?? true,
      likes: json['likes'] ?? true,
      calls: json['calls'] ?? true,
      system: json['system'] ?? true,
      promotions: json['promotions'] ?? false,
      reminders: json['reminders'] ?? true,
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newMessages': newMessages,
      'newMatches': newMatches,
      'profileViews': profileViews,
      'likes': likes,
      'calls': calls,
      'system': system,
      'promotions': promotions,
      'reminders': reminders,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  NotificationSettings copyWith({
    bool? newMessages,
    bool? newMatches,
    bool? profileViews,
    bool? likes,
    bool? calls,
    bool? system,
    bool? promotions,
    bool? reminders,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettings(
      newMessages: newMessages ?? this.newMessages,
      newMatches: newMatches ?? this.newMatches,
      profileViews: profileViews ?? this.profileViews,
      likes: likes ?? this.likes,
      calls: calls ?? this.calls,
      system: system ?? this.system,
      promotions: promotions ?? this.promotions,
      reminders: reminders ?? this.reminders,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  @override
  List<Object?> get props => [
    newMessages,
    newMatches,
    profileViews,
    likes,
    calls,
    system,
    promotions,
    reminders,
    pushEnabled,
    emailEnabled,
    soundEnabled,
    vibrationEnabled,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
  ];
}
