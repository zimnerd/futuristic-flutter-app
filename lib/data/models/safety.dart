import 'package:equatable/equatable.dart';

/// Emergency contact for user safety
class EmergencyContact extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String email;
  final String relationship;
  final bool isActive;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.relationship,
    this.isActive = true,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      relationship: json['relationship'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phoneNumber,
        email,
        relationship,
        isActive,
        createdAt,
      ];
}

/// Safe date check-in for user safety
class SafeDateCheckIn extends Equatable {
  final String id;
  final String userId;
  final String matchId;
  final DateTime scheduledTime;
  final LocationData location;
  final CheckInStatus status;
  final DateTime lastUpdateAt;
  final String? notes;
  final String? matchName;

  const SafeDateCheckIn({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.scheduledTime,
    required this.location,
    required this.status,
    required this.lastUpdateAt,
    this.notes,
    this.matchName,
  });

  factory SafeDateCheckIn.fromJson(Map<String, dynamic> json) {
    return SafeDateCheckIn(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchId: json['matchId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      status: CheckInStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CheckInStatus.scheduled,
      ),
      lastUpdateAt: DateTime.parse(json['lastUpdateAt'] as String),
      notes: json['notes'] as String?,
      matchName: json['matchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'matchId': matchId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'location': location.toJson(),
      'status': status.name,
      'lastUpdateAt': lastUpdateAt.toIso8601String(),
      'notes': notes,
      'matchName': matchName,
    };
  }

  SafeDateCheckIn copyWith({
    String? id,
    String? userId,
    String? matchId,
    DateTime? scheduledTime,
    LocationData? location,
    CheckInStatus? status,
    DateTime? lastUpdateAt,
    String? notes,
    String? matchName,
  }) {
    return SafeDateCheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      location: location ?? this.location,
      status: status ?? this.status,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      notes: notes ?? this.notes,
      matchName: matchName ?? this.matchName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        matchId,
        scheduledTime,
        location,
        status,
        lastUpdateAt,
        notes,
        matchName,
      ];
}

/// Check-in status options
enum CheckInStatus {
  scheduled('Scheduled', 0xFF2196F3),
  checkedIn('Checked In', 0xFF4CAF50),
  missed('Missed', 0xFFFF9800),
  emergency('Emergency', 0xFFF44336);

  const CheckInStatus(this.displayName, this.colorValue);
  final String displayName;
  final int colorValue;
}

/// Location data for safety features
class LocationData extends Equatable {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;

  const LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [name, address, latitude, longitude, accuracy, timestamp];
}

/// Location sharing for real-time safety
class LocationShare extends Equatable {
  final String id;
  final String userId;
  final String sharedWithUserId;
  final DateTime expiresAt;
  final bool isActive;
  final LocationData location;
  final String? sharedWithName;

  const LocationShare({
    required this.id,
    required this.userId,
    required this.sharedWithUserId,
    required this.expiresAt,
    this.isActive = true,
    required this.location,
    this.sharedWithName,
  });

  factory LocationShare.fromJson(Map<String, dynamic> json) {
    return LocationShare(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sharedWithUserId: json['sharedWithUserId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      sharedWithName: json['sharedWithName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sharedWithUserId': sharedWithUserId,
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'location': location.toJson(),
      'sharedWithName': sharedWithName,
    };
  }

  /// Check if the location share is still valid
  bool get isValid => isActive && DateTime.now().isBefore(expiresAt);

  @override
  List<Object?> get props => [
        id,
        userId,
        sharedWithUserId,
        expiresAt,
        isActive,
        location,
        sharedWithName,
      ];
}

/// Safety settings for the user
class SafetySettings extends Equatable {
  final String userId;
  final bool emergencyContactsEnabled;
  final bool checkInRemindersEnabled;
  final bool locationSharingEnabled;
  final bool panicButtonEnabled;
  final int checkInInterval; // in minutes
  final bool autoCheckInEnabled;
  final List<String> trustedContactIds;

  const SafetySettings({
    required this.userId,
    this.emergencyContactsEnabled = true,
    this.checkInRemindersEnabled = true,
    this.locationSharingEnabled = false,
    this.panicButtonEnabled = true,
    this.checkInInterval = 60, // default 1 hour
    this.autoCheckInEnabled = false,
    this.trustedContactIds = const [],
  });

  factory SafetySettings.fromJson(Map<String, dynamic> json) {
    return SafetySettings(
      userId: json['userId'] as String,
      emergencyContactsEnabled: json['emergencyContactsEnabled'] as bool? ?? true,
      checkInRemindersEnabled: json['checkInRemindersEnabled'] as bool? ?? true,
      locationSharingEnabled: json['locationSharingEnabled'] as bool? ?? false,
      panicButtonEnabled: json['panicButtonEnabled'] as bool? ?? true,
      checkInInterval: json['checkInInterval'] as int? ?? 60,
      autoCheckInEnabled: json['autoCheckInEnabled'] as bool? ?? false,
      trustedContactIds: (json['trustedContactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emergencyContactsEnabled': emergencyContactsEnabled,
      'checkInRemindersEnabled': checkInRemindersEnabled,
      'locationSharingEnabled': locationSharingEnabled,
      'panicButtonEnabled': panicButtonEnabled,
      'checkInInterval': checkInInterval,
      'autoCheckInEnabled': autoCheckInEnabled,
      'trustedContactIds': trustedContactIds,
    };
  }

  SafetySettings copyWith({
    String? userId,
    bool? emergencyContactsEnabled,
    bool? checkInRemindersEnabled,
    bool? locationSharingEnabled,
    bool? panicButtonEnabled,
    int? checkInInterval,
    bool? autoCheckInEnabled,
    List<String>? trustedContactIds,
  }) {
    return SafetySettings(
      userId: userId ?? this.userId,
      emergencyContactsEnabled: emergencyContactsEnabled ?? this.emergencyContactsEnabled,
      checkInRemindersEnabled: checkInRemindersEnabled ?? this.checkInRemindersEnabled,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      panicButtonEnabled: panicButtonEnabled ?? this.panicButtonEnabled,
      checkInInterval: checkInInterval ?? this.checkInInterval,
      autoCheckInEnabled: autoCheckInEnabled ?? this.autoCheckInEnabled,
      trustedContactIds: trustedContactIds ?? this.trustedContactIds,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        emergencyContactsEnabled,
        checkInRemindersEnabled,
        locationSharingEnabled,
        panicButtonEnabled,
        checkInInterval,
        autoCheckInEnabled,
        trustedContactIds,
      ];
}

/// Safety report types
enum SafetyReportType {
  harassment,
  inappropriateContent,
  spam,
  scam,
  fakeProfie,
  underage,
  violence,
  sexualMisconduct,
  hateSpeech,
  other,
}

/// Safety report for user complaints and issues
class SafetyReport extends Equatable {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? contentId;
  final String? contentType;
  final SafetyReportType reportType;
  final String description;
  final List<String> evidenceUrls;
  final String? incidentLocation;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;

  const SafetyReport({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.contentId,
    this.contentType,
    required this.reportType,
    required this.description,
    this.evidenceUrls = const [],
    this.incidentLocation,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.adminNotes,
  });

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    return SafetyReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedUserId: json['reportedUserId'] as String?,
      contentId: json['contentId'] as String?,
      contentType: json['contentType'] as String?,
      reportType: SafetyReportType.values.firstWhere(
        (e) => e.name == json['reportType'],
        orElse: () => SafetyReportType.other,
      ),
      description: json['description'] as String,
      evidenceUrls: List<String>.from(json['evidenceUrls'] ?? []),
      incidentLocation: json['incidentLocation'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      adminNotes: json['adminNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'contentId': contentId,
      'contentType': contentType,
      'reportType': reportType.name,
      'description': description,
      'evidenceUrls': evidenceUrls,
      'incidentLocation': incidentLocation,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'adminNotes': adminNotes,
    };
  }

  SafetyReport copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? contentId,
    String? contentType,
    SafetyReportType? reportType,
    String? description,
    List<String>? evidenceUrls,
    String? incidentLocation,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNotes,
  }) {
    return SafetyReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      reportType: reportType ?? this.reportType,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        reportedUserId,
        contentId,
        contentType,
        reportType,
        description,
        evidenceUrls,
        incidentLocation,
        status,
        createdAt,
        resolvedAt,
        adminNotes,
      ];
}

/// Report status enum
enum ReportStatus {
  pending,
  investigating,
  resolved,
  dismissed,
  escalated,
}

/// Blocked user information
class BlockedUser extends Equatable {
  final String id;
  final String userId;
  final String blockedUserId;
  final String blockedUserName;
  final String? blockedUserPhotoUrl;
  final String? reason;
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.userId,
    required this.blockedUserId,
    required this.blockedUserName,
    this.blockedUserPhotoUrl,
    this.reason,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as String,
      userId: json['userId'] as String,
      blockedUserId: json['blockedUserId'] as String,
      blockedUserName: json['blockedUserName'] as String,
      blockedUserPhotoUrl: json['blockedUserPhotoUrl'] as String?,
      reason: json['reason'] as String?,
      blockedAt: DateTime.parse(json['blockedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'blockedUserId': blockedUserId,
      'blockedUserName': blockedUserName,
      'blockedUserPhotoUrl': blockedUserPhotoUrl,
      'reason': reason,
      'blockedAt': blockedAt.toIso8601String(),
    };
  }

  BlockedUser copyWith({
    String? id,
    String? userId,
    String? blockedUserId,
    String? blockedUserName,
    String? blockedUserPhotoUrl,
    String? reason,
    DateTime? blockedAt,
  }) {
    return BlockedUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      blockedUserName: blockedUserName ?? this.blockedUserName,
      blockedUserPhotoUrl: blockedUserPhotoUrl ?? this.blockedUserPhotoUrl,
      reason: reason ?? this.reason,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        blockedUserId,
        blockedUserName,
        blockedUserPhotoUrl,
        reason,
        blockedAt,
      ];
}

/// Safety tip information
class SafetyTip extends Equatable {
  final String id;
  final String title;
  final String content;
  final SafetyTipCategory category;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SafetyTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.priority = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SafetyTip.fromJson(Map<String, dynamic> json) {
    return SafetyTip(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: SafetyTipCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SafetyTipCategory.general,
      ),
      priority: json['priority'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.name,
      'priority': priority,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SafetyTip copyWith({
    String? id,
    String? title,
    String? content,
    SafetyTipCategory? category,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafetyTip(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        priority,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Safety tip categories
enum SafetyTipCategory {
  general,
  datingSafety,
  onlineSafety,
  meetingTips,
  emergencyPreparedness,
  privacyProtection,
  scamAwareness,
}
