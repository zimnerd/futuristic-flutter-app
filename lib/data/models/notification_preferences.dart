import 'package:equatable/equatable.dart';

/// Model representing user notification preferences
/// Controls all notification delivery channels and categories
class NotificationPreferences extends Equatable {
  /// Enable/disable all push notifications
  final bool pushEnabled;

  /// Enable/disable all email notifications
  final bool emailEnabled;

  /// Enable/disable all SMS notifications
  final bool smsEnabled;

  /// Category-specific notification preferences
  final NotificationCategories categories;

  /// Quiet hours configuration
  final QuietHours? quietHours;

  /// Notification sound enabled
  final bool soundEnabled;

  /// Notification vibration enabled
  final bool vibrationEnabled;

  /// Show notification previews on lock screen
  final bool previewEnabled;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    required this.categories,
    this.quietHours,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.previewEnabled = true,
  });

  /// Default notification preferences for new users
  factory NotificationPreferences.defaults() {
    return NotificationPreferences(
      pushEnabled: true,
      emailEnabled: true,
      smsEnabled: false,
      categories: NotificationCategories.defaults(),
      soundEnabled: true,
      vibrationEnabled: true,
      previewEnabled: true,
    );
  }

  /// Create from JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      categories: json['categories'] != null
          ? NotificationCategories.fromJson(
              json['categories'] as Map<String, dynamic>,
            )
          : NotificationCategories.defaults(),
      quietHours: json['quietHours'] != null
          ? QuietHours.fromJson(json['quietHours'] as Map<String, dynamic>)
          : null,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      previewEnabled: json['previewEnabled'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'categories': categories.toJson(),
      'quietHours': quietHours?.toJson(),
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'previewEnabled': previewEnabled,
    };
  }

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    NotificationCategories? categories,
    QuietHours? quietHours,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? previewEnabled,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      categories: categories ?? this.categories,
      quietHours: quietHours ?? this.quietHours,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      previewEnabled: previewEnabled ?? this.previewEnabled,
    );
  }

  @override
  List<Object?> get props => [
    pushEnabled,
    emailEnabled,
    smsEnabled,
    categories,
    quietHours,
    soundEnabled,
    vibrationEnabled,
    previewEnabled,
  ];
}

/// Notification category preferences
class NotificationCategories extends Equatable {
  /// New match notifications
  final bool matches;

  /// New message notifications
  final bool messages;

  /// New like notifications
  final bool likes;

  /// New super like notifications
  final bool superLikes;

  /// Profile view notifications
  final bool profileViews;

  /// Event-related notifications
  final bool events;

  /// Promotional notifications
  final bool promotions;

  /// Video call notifications
  final bool videoCalls;

  /// Voice call notifications
  final bool voiceCalls;

  /// AI companion message notifications
  final bool aiCompanion;

  const NotificationCategories({
    this.matches = true,
    this.messages = true,
    this.likes = true,
    this.superLikes = true,
    this.profileViews = true,
    this.events = true,
    this.promotions = false,
    this.videoCalls = true,
    this.voiceCalls = true,
    this.aiCompanion = true,
  });

  /// Default category preferences
  factory NotificationCategories.defaults() {
    return const NotificationCategories();
  }

  /// Create from JSON
  factory NotificationCategories.fromJson(Map<String, dynamic> json) {
    return NotificationCategories(
      matches: json['matches'] as bool? ?? true,
      messages: json['messages'] as bool? ?? true,
      likes: json['likes'] as bool? ?? true,
      superLikes: json['superLikes'] as bool? ?? true,
      profileViews: json['profileViews'] as bool? ?? true,
      events: json['events'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? false,
      videoCalls: json['videoCalls'] as bool? ?? true,
      voiceCalls: json['voiceCalls'] as bool? ?? true,
      aiCompanion: json['aiCompanion'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'matches': matches,
      'messages': messages,
      'likes': likes,
      'superLikes': superLikes,
      'profileViews': profileViews,
      'events': events,
      'promotions': promotions,
      'videoCalls': videoCalls,
      'voiceCalls': voiceCalls,
      'aiCompanion': aiCompanion,
    };
  }

  /// Create a copy with updated fields
  NotificationCategories copyWith({
    bool? matches,
    bool? messages,
    bool? likes,
    bool? superLikes,
    bool? profileViews,
    bool? events,
    bool? promotions,
    bool? videoCalls,
    bool? voiceCalls,
    bool? aiCompanion,
  }) {
    return NotificationCategories(
      matches: matches ?? this.matches,
      messages: messages ?? this.messages,
      likes: likes ?? this.likes,
      superLikes: superLikes ?? this.superLikes,
      profileViews: profileViews ?? this.profileViews,
      events: events ?? this.events,
      promotions: promotions ?? this.promotions,
      videoCalls: videoCalls ?? this.videoCalls,
      voiceCalls: voiceCalls ?? this.voiceCalls,
      aiCompanion: aiCompanion ?? this.aiCompanion,
    );
  }

  @override
  List<Object?> get props => [
    matches,
    messages,
    likes,
    superLikes,
    profileViews,
    events,
    promotions,
    videoCalls,
    voiceCalls,
    aiCompanion,
  ];
}

/// Quiet hours configuration (do not disturb)
class QuietHours extends Equatable {
  /// Quiet hours enabled
  final bool enabled;

  /// Start time (24-hour format, e.g., "22:00")
  final String startTime;

  /// End time (24-hour format, e.g., "08:00")
  final String endTime;

  const QuietHours({
    required this.enabled,
    required this.startTime,
    required this.endTime,
  });

  /// Default quiet hours (10 PM to 8 AM, disabled)
  factory QuietHours.defaults() {
    return const QuietHours(
      enabled: false,
      startTime: '22:00',
      endTime: '08:00',
    );
  }

  /// Create from JSON
  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      enabled: json['enabled'] as bool? ?? false,
      startTime: json['startTime'] as String? ?? '22:00',
      endTime: json['endTime'] as String? ?? '08:00',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'startTime': startTime, 'endTime': endTime};
  }

  /// Create a copy with updated fields
  QuietHours copyWith({bool? enabled, String? startTime, String? endTime}) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [enabled, startTime, endTime];
}
