/// Group chat models for PulseLink dating app
library;

enum GroupType {
  standard,
  study,
  interest,
  dating,
  liveHost,
  speedDating,
}

enum ParticipantRole {
  owner,
  admin,
  moderator,
  member,
  guest,
}

enum LiveSessionStatus {
  waiting,
  active,
  ended,
}

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
}

class GroupSettings {
  final String id;
  final GroupType groupType;
  final int maxParticipants;
  final bool allowParticipantInvite;
  final bool requireApproval;
  final bool autoAcceptFriends;
  final bool enableVoiceChat;
  final bool enableVideoChat;

  const GroupSettings({
    required this.id,
    required this.groupType,
    required this.maxParticipants,
    required this.allowParticipantInvite,
    required this.requireApproval,
    required this.autoAcceptFriends,
    required this.enableVoiceChat,
    required this.enableVideoChat,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      id: json['id'] as String,
      groupType: _parseGroupType(json['groupType'] as String),
      maxParticipants: json['maxParticipants'] as int,
      allowParticipantInvite: json['allowParticipantInvite'] as bool,
      requireApproval: json['requireApproval'] as bool,
      autoAcceptFriends: json['autoAcceptFriends'] as bool,
      enableVoiceChat: json['enableVoiceChat'] as bool,
      enableVideoChat: json['enableVideoChat'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupType': groupType.name.toUpperCase(),
      'maxParticipants': maxParticipants,
      'allowParticipantInvite': allowParticipantInvite,
      'requireApproval': requireApproval,
      'autoAcceptFriends': autoAcceptFriends,
      'enableVoiceChat': enableVoiceChat,
      'enableVideoChat': enableVideoChat,
    };
  }

  static GroupType _parseGroupType(String value) {
    switch (value.toUpperCase()) {
      case 'STUDY':
        return GroupType.study;
      case 'INTEREST':
        return GroupType.interest;
      case 'DATING':
        return GroupType.dating;
      case 'LIVE_HOST':
        return GroupType.liveHost;
      case 'SPEED_DATING':
        return GroupType.speedDating;
      default:
        return GroupType.standard;
    }
  }
}

class GroupParticipant {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePhoto;
  final ParticipantRole role;
  final DateTime joinedAt;
  final bool isOnline;

  const GroupParticipant({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
    required this.role,
    required this.joinedAt,
    this.isOnline = false,
  });

  String get fullName => '$firstName $lastName';

  factory GroupParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return GroupParticipant(
      id: json['id'] as String,
      userId: user?['id'] as String? ?? json['userId'] as String? ?? '',
      firstName: user?['firstName'] as String? ?? 'Unknown',
      lastName: user?['lastName'] as String? ?? '',
      profilePhoto: user?['profilePhoto'] as String?,
      role: _parseRole(json['role'] as String? ?? 'MEMBER'),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  static ParticipantRole _parseRole(String value) {
    switch (value.toUpperCase()) {
      case 'OWNER':
        return ParticipantRole.owner;
      case 'ADMIN':
        return ParticipantRole.admin;
      case 'MODERATOR':
        return ParticipantRole.moderator;
      case 'GUEST':
        return ParticipantRole.guest;
      default:
        return ParticipantRole.member;
    }
  }
}

class GroupConversation {
  final String id;
  final String title;
  final String? description;
  final GroupSettings? settings;
  final List<GroupParticipant> participants;
  final int participantCount;
  final DateTime? lastActivity;
  final String? lastMessage;
  final bool hasUnread;

  const GroupConversation({
    required this.id,
    required this.title,
    this.description,
    this.settings,
    this.participants = const [],
    required this.participantCount,
    this.lastActivity,
    this.lastMessage,
    this.hasUnread = false,
  });

  // Helper getters for GroupListScreen compatibility
  String get name => title;
  GroupType get groupType => settings?.groupType ?? GroupType.standard;

  factory GroupConversation.fromJson(Map<String, dynamic> json) {
    // Handle both response formats:
    // 1. Create response: { id, title, settings: {...}, participants: [...] }
    // 2. User-groups response: { id, title, type: "TRADITIONAL", participants: [...] }
    
    GroupSettings? parsedSettings;
    if (json['settings'] != null) {
      // Format 1: settings object from create response
      parsedSettings = GroupSettings.fromJson(json['settings'] as Map<String, dynamic>);
    } else if (json['type'] != null) {
      // Format 2: type field from user-groups response - create minimal settings
      parsedSettings = GroupSettings(
        id: json['id'] as String, // Use conversation ID as settings ID
        groupType: GroupSettings._parseGroupType(json['type'] as String),
        maxParticipants: 50, // Default value
        allowParticipantInvite: false,
        requireApproval: false,
        autoAcceptFriends: false,
        enableVoiceChat: true,
        enableVideoChat: false,
      );
    }

    return GroupConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      settings: parsedSettings,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => GroupParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      participantCount: json['participantCount'] as int? ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : null,
      lastMessage: json['lastMessage'] as String?,
      hasUnread: json['hasUnread'] as bool? ?? false,
    );
  }
}

class LiveSession {
  final String id;
  final String conversationId;
  final String hostId;
  final String hostName;
  final String? hostPhoto;
  final String title;
  final String? description;
  final GroupType groupType;
  final LiveSessionStatus status;
  final int currentParticipants;
  final int maxParticipants;
  final bool requireApproval;
  final DateTime? startedAt;
  final DateTime createdAt;

  const LiveSession({
    required this.id,
    required this.conversationId,
    required this.hostId,
    required this.hostName,
    this.hostPhoto,
    required this.title,
    this.description,
    required this.groupType,
    required this.status,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.requireApproval,
    this.startedAt,
    required this.createdAt,
  });

  bool get isFull => currentParticipants >= maxParticipants;

  // Helper getters for backward compatibility
  String? get hostAvatarUrl => hostPhoto;
  String get hostFirstName => hostName.split(' ').first;

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      hostId: json['hostId'] as String,
      hostName: json['host']?['firstName'] as String? ?? 'Unknown',
      hostPhoto: json['host']?['profilePhoto'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      groupType: GroupSettings._parseGroupType(
        json['conversation']?['groupSettings']?['groupType'] as String? ??
            'STANDARD',
      ),
      status: _parseStatus(json['status'] as String),
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      requireApproval: json['requireApproval'] as bool? ?? true,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static LiveSessionStatus _parseStatus(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return LiveSessionStatus.active;
      case 'ENDED':
        return LiveSessionStatus.ended;
      default:
        return LiveSessionStatus.waiting;
    }
  }
}

class JoinRequest {
  final String id;
  final String liveSessionId;
  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;
  final int? requesterAge;
  final String? message;
  final JoinRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  const JoinRequest({
    required this.id,
    required this.liveSessionId,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhoto,
    this.requesterAge,
    this.message,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'] as Map<String, dynamic>?;
    return JoinRequest(
      id: json['id'] as String,
      liveSessionId: json['liveSessionId'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: requester != null
          ? '${requester['firstName']} ${requester['lastName']}'
          : 'Unknown',
      requesterPhoto: requester?['profilePhoto'] as String?,
      requesterAge: requester?['age'] as int?,
      message: json['requestMessage'] as String?,
      status: _parseRequestStatus(json['status'] as String),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  static JoinRequestStatus _parseRequestStatus(String value) {
    switch (value.toUpperCase()) {
      case 'ACCEPTED':
      case 'APPROVED':
        return JoinRequestStatus.approved;
      case 'REJECTED':
        return JoinRequestStatus.rejected;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

/// Group message model
class GroupMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String? senderFirstName;
  final String? senderLastName;
  final String? senderProfilePhoto;
  final String content;
  final String type;
  final DateTime timestamp;
  final String status;
  final String? tempId;
  final ReplyToMessage? replyTo;
  final Map<String, dynamic>? metadata;
  final List<MessageReaction> reactions;
  final List<String> readBy;
  final List<String> deliveredTo;

  const GroupMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    this.senderFirstName,
    this.senderLastName,
    this.senderProfilePhoto,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.tempId,
    this.replyTo,
    this.metadata,
    this.reactions = const [],
    this.readBy = const [],
    this.deliveredTo = const [],
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderUsername: json['senderUsername'] as String,
      senderFirstName: json['senderFirstName'] as String?,
      senderLastName: json['senderLastName'] as String?,
      senderProfilePhoto: json['senderProfilePhoto'] as String?,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String? ?? 'sent',
      tempId: json['tempId'] as String?,
      replyTo: json['replyTo'] != null
          ? ReplyToMessage.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
      readBy: json['readBy'] != null
          ? List<String>.from(json['readBy'] as List)
          : [],
      deliveredTo: json['deliveredTo'] != null
          ? List<String>.from(json['deliveredTo'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderFirstName': senderFirstName,
      'senderLastName': senderLastName,
      'senderProfilePhoto': senderProfilePhoto,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'tempId': tempId,
      'replyTo': replyTo?.toJson(),
      'metadata': metadata,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'readBy': readBy,
      'deliveredTo': deliveredTo,
    };
  }

  /// Copy with method for updating message properties
  GroupMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderUsername,
    String? senderFirstName,
    String? senderLastName,
    String? senderProfilePhoto,
    String? content,
    String? type,
    DateTime? timestamp,
    String? status,
    String? tempId,
    ReplyToMessage? replyTo,
    Map<String, dynamic>? metadata,
    List<MessageReaction>? reactions,
    List<String>? readBy,
    List<String>? deliveredTo,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderFirstName: senderFirstName ?? this.senderFirstName,
      senderLastName: senderLastName ?? this.senderLastName,
      senderProfilePhoto: senderProfilePhoto ?? this.senderProfilePhoto,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      tempId: tempId ?? this.tempId,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
    );
  }
}

/// Reply-to message model
class ReplyToMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderUsername;

  const ReplyToMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderUsername,
  });

  factory ReplyToMessage.fromJson(Map<String, dynamic> json) {
    return ReplyToMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      senderUsername: json['senderUsername'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'senderUsername': senderUsername,
    };
  }
}

/// Message reaction model
class MessageReaction {
  final String emoji;
  final String userId;
  final String username;
  final DateTime timestamp;

  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.username,
    required this.timestamp,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'userId': userId,
      'username': username,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Blocked user model for group moderation
class BlockedUser {
  final String id;
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? reason;
  final DateTime blockedAt;
  final String blockedBy;

  const BlockedUser({
    required this.id,
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.reason,
    required this.blockedAt,
    required this.blockedBy,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      reason: json['reason'] as String?,
      blockedAt: DateTime.parse(json['blockedAt'] as String),
      blockedBy: json['blockedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (reason != null) 'reason': reason,
      'blockedAt': blockedAt.toIso8601String(),
      'blockedBy': blockedBy,
    };
  }
}

/// Reported content model for content moderation
class ReportedContent {
  final String id;
  final String messageId;
  final String reportedBy;
  final String reporterUsername;
  final String? reporterPhotoUrl;
  final String reason;
  final String? description;
  final DateTime reportedAt;
  final String status; // pending, reviewed, dismissed, action_taken
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final GroupMessage? message;

  const ReportedContent({
    required this.id,
    required this.messageId,
    required this.reportedBy,
    required this.reporterUsername,
    this.reporterPhotoUrl,
    required this.reason,
    this.description,
    required this.reportedAt,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.message,
  });

  factory ReportedContent.fromJson(Map<String, dynamic> json) {
    return ReportedContent(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      reportedBy: json['reportedBy'] as String,
      reporterUsername: json['reporterUsername'] as String,
      reporterPhotoUrl: json['reporterPhotoUrl'] as String?,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      status: json['status'] as String,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewNotes: json['reviewNotes'] as String?,
      message: json['message'] != null
          ? GroupMessage.fromJson(json['message'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'reportedBy': reportedBy,
      'reporterUsername': reporterUsername,
      if (reporterPhotoUrl != null) 'reporterPhotoUrl': reporterPhotoUrl,
      'reason': reason,
      if (description != null) 'description': description,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      if (reviewNotes != null) 'reviewNotes': reviewNotes,
      if (message != null) 'message': message!.toJson(),
    };
  }
}

