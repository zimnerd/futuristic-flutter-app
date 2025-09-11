import 'package:equatable/equatable.dart';

/// Notification types enum
enum NotificationType {
  message,
  match,
  like,
  superLike,
  boost,
  premium,
  achievement,
  system,
  social,
  reminder,
}

/// Notification priority enum
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification model
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String? imageUrl;
  final String? iconUrl;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.system,
    this.priority = NotificationPriority.normal,
    this.imageUrl,
    this.iconUrl,
    this.data,
    this.actionUrl,
    this.isRead = false,
    this.readAt,
    this.isArchived = false,
    this.archivedAt,
    this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: _parseNotificationType(json['type'] as String?),
      priority: _parseNotificationPriority(json['priority'] as String?),
      imageUrl: json['imageUrl'] as String?,
      iconUrl: json['iconUrl'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['actionUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      isArchived: json['isArchived'] as bool? ?? false,
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'data': data,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isArchived': isArchived,
      'archivedAt': archivedAt?.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'match':
        return NotificationType.match;
      case 'like':
        return NotificationType.like;
      case 'superlike':
      case 'super_like':
        return NotificationType.superLike;
      case 'boost':
        return NotificationType.boost;
      case 'premium':
        return NotificationType.premium;
      case 'achievement':
        return NotificationType.achievement;
      case 'system':
        return NotificationType.system;
      case 'social':
        return NotificationType.social;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }

  /// Parse notification priority from string
  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }

  /// Check if notification is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }

  /// Check if notification is scheduled for future
  bool get isScheduled {
    if (scheduledFor == null) return false;
    return DateTime.now().isBefore(scheduledFor!);
  }

  /// Get notification icon based on type
  String get defaultIcon {
    switch (type) {
      case NotificationType.message:
        return 'message';
      case NotificationType.match:
        return 'favorite';
      case NotificationType.like:
        return 'thumb_up';
      case NotificationType.superLike:
        return 'star';
      case NotificationType.boost:
        return 'rocket_launch';
      case NotificationType.premium:
        return 'diamond';
      case NotificationType.achievement:
        return 'military_tech';
      case NotificationType.system:
        return 'info';
      case NotificationType.social:
        return 'group';
      case NotificationType.reminder:
        return 'notifications';
    }
  }

  /// Get notification color based on type and priority
  String get notificationColor {
    // Priority colors override type colors for urgent notifications
    if (priority == NotificationPriority.urgent) {
      return '#F44336'; // Red
    } else if (priority == NotificationPriority.high) {
      return '#FF9800'; // Orange
    }

    // Type-specific colors
    switch (type) {
      case NotificationType.message:
        return '#2196F3'; // Blue
      case NotificationType.match:
        return '#E91E63'; // Pink
      case NotificationType.like:
        return '#4CAF50'; // Green
      case NotificationType.superLike:
        return '#FF9800'; // Orange
      case NotificationType.boost:
        return '#9C27B0'; // Purple
      case NotificationType.premium:
        return '#FFD700'; // Gold
      case NotificationType.achievement:
        return '#FF5722'; // Deep Orange
      case NotificationType.system:
        return '#607D8B'; // Blue Grey
      case NotificationType.social:
        return '#795548'; // Brown
      case NotificationType.reminder:
        return '#9E9E9E'; // Grey
    }
  }

  /// Copy with method for immutable updates
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    String? imageUrl,
    String? iconUrl,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool? isRead,
    DateTime? readAt,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        priority,
        imageUrl,
        iconUrl,
        data,
        actionUrl,
        isRead,
        readAt,
        isArchived,
        archivedAt,
        scheduledFor,
        createdAt,
        updatedAt,
      ];
}
