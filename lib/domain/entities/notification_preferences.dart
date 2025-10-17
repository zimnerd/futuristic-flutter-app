/// Entity representing user notification preferences
class NotificationPreferences {
  // Match & Discovery Notifications
  final bool matchNotifications;
  final bool messageNotifications;
  final bool likeNotifications;
  final bool superLikeNotifications;

  // Event Notifications
  final bool eventNotifications;
  final bool eventReminders;
  final bool speedDatingNotifications;

  // Premium & Promotional
  final bool premiumNotifications;
  final bool promotionalNotifications;

  // System Notifications
  final bool securityAlerts;
  final bool accountActivity;
  final bool newFeatures;
  final bool tipsTricks;

  const NotificationPreferences({
    this.matchNotifications = true,
    this.messageNotifications = true,
    this.likeNotifications = true,
    this.superLikeNotifications = true,
    this.eventNotifications = true,
    this.eventReminders = true,
    this.speedDatingNotifications = true,
    this.premiumNotifications = true,
    this.promotionalNotifications = false,
    this.securityAlerts = true,
    this.accountActivity = true,
    this.newFeatures = true,
    this.tipsTricks = true,
  });

  /// Create with default values
  factory NotificationPreferences.defaults() {
    return const NotificationPreferences();
  }

  /// Create a copy with updated fields
  NotificationPreferences copyWith(Map<String, dynamic> updates) {
    return NotificationPreferences(
      matchNotifications: updates['matchNotifications'] ?? matchNotifications,
      messageNotifications:
          updates['messageNotifications'] ?? messageNotifications,
      likeNotifications: updates['likeNotifications'] ?? likeNotifications,
      superLikeNotifications:
          updates['superLikeNotifications'] ?? superLikeNotifications,
      eventNotifications: updates['eventNotifications'] ?? eventNotifications,
      eventReminders: updates['eventReminders'] ?? eventReminders,
      speedDatingNotifications:
          updates['speedDatingNotifications'] ?? speedDatingNotifications,
      premiumNotifications:
          updates['premiumNotifications'] ?? premiumNotifications,
      promotionalNotifications:
          updates['promotionalNotifications'] ?? promotionalNotifications,
      securityAlerts: updates['securityAlerts'] ?? securityAlerts,
      accountActivity: updates['accountActivity'] ?? accountActivity,
      newFeatures: updates['newFeatures'] ?? newFeatures,
      tipsTricks: updates['tipsTricks'] ?? tipsTricks,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'matchNotifications': matchNotifications,
      'messageNotifications': messageNotifications,
      'likeNotifications': likeNotifications,
      'superLikeNotifications': superLikeNotifications,
      'eventNotifications': eventNotifications,
      'eventReminders': eventReminders,
      'speedDatingNotifications': speedDatingNotifications,
      'premiumNotifications': premiumNotifications,
      'promotionalNotifications': promotionalNotifications,
      'securityAlerts': securityAlerts,
      'accountActivity': accountActivity,
      'newFeatures': newFeatures,
      'tipsTricks': tipsTricks,
    };
  }

  /// Create from JSON map
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      matchNotifications: json['matchNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      likeNotifications: json['likeNotifications'] ?? true,
      superLikeNotifications: json['superLikeNotifications'] ?? true,
      eventNotifications: json['eventNotifications'] ?? true,
      eventReminders: json['eventReminders'] ?? true,
      speedDatingNotifications: json['speedDatingNotifications'] ?? true,
      premiumNotifications: json['premiumNotifications'] ?? true,
      promotionalNotifications: json['promotionalNotifications'] ?? false,
      securityAlerts: json['securityAlerts'] ?? true,
      accountActivity: json['accountActivity'] ?? true,
      newFeatures: json['newFeatures'] ?? true,
      tipsTricks: json['tipsTricks'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPreferences &&
        other.matchNotifications == matchNotifications &&
        other.messageNotifications == messageNotifications &&
        other.likeNotifications == likeNotifications &&
        other.superLikeNotifications == superLikeNotifications &&
        other.eventNotifications == eventNotifications &&
        other.eventReminders == eventReminders &&
        other.speedDatingNotifications == speedDatingNotifications &&
        other.premiumNotifications == premiumNotifications &&
        other.promotionalNotifications == promotionalNotifications &&
        other.securityAlerts == securityAlerts &&
        other.accountActivity == accountActivity &&
        other.newFeatures == newFeatures &&
        other.tipsTricks == tipsTricks;
  }

  @override
  int get hashCode {
    return matchNotifications.hashCode ^
        messageNotifications.hashCode ^
        likeNotifications.hashCode ^
        superLikeNotifications.hashCode ^
        eventNotifications.hashCode ^
        eventReminders.hashCode ^
        speedDatingNotifications.hashCode ^
        premiumNotifications.hashCode ^
        promotionalNotifications.hashCode ^
        securityAlerts.hashCode ^
        accountActivity.hashCode ^
        newFeatures.hashCode ^
        tipsTricks.hashCode;
  }
}
