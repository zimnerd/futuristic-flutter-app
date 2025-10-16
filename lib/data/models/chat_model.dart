import 'package:equatable/equatable.dart';

import '../../domain/entities/message.dart';

/// Model representing a chat conversation
class ConversationModel extends Equatable {
  const ConversationModel({
    required this.id,
    required this.type,
    required this.participantIds,
    this.name,
    this.description,
    this.imageUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final String? name;
  final String? description;
  final String? imageUrl;
  final MessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ConversationSettings? settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: ConversationType.values.byName(json['type'] as String),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      settings: json['settings'] != null
          ? ConversationSettings.fromJson(json['settings'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Factory method for backend API response format
  factory ConversationModel.fromBackendJson(Map<String, dynamic> json) {
    // Backend sends participants as objects, extract user IDs
    final participants = json['participants'] as List<dynamic>? ?? [];
    final participantIds = participants
        .map((p) => p['userId'] as String? ?? p['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    return ConversationModel(
      id: json['id']?.toString() ?? '',
      type: ConversationType.values.byName(json['type']?.toString() ?? 'direct'),
      participantIds: participantIds,
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromConversationSummary(json['lastMessage'])
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      settings: json['settings'] != null
          ? ConversationSettings.fromJson(json['settings'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'participantIds': participantIds,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'lastMessage': lastMessage?.toJson(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'settings': settings?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    List<String>? participantIds,
    String? name,
    String? description,
    String? imageUrl,
    MessageModel? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    ConversationSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        participantIds,
        name,
        description,
        imageUrl,
        lastMessage,
        lastMessageAt,
        unreadCount,
        settings,
        createdAt,
        updatedAt,
      ];
}

/// Model representing a chat message
class MessageModel extends Equatable {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    this.senderAvatar,
    required this.type,
    this.content,
    this.mediaUrls,
    this.metadata,
    required this.status,
    this.replyTo,
    this.reactions,
    this.editedAt,
    this.isForwarded = false,
    this.forwardedFromConversationId,
    this.isBookmarked = false,
    required this.createdAt,
    required this.updatedAt,
    this.tempId, // Temporary ID for optimistic message correlation
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String? senderAvatar;
  final MessageType type;
  final String? content;
  final List<String>? mediaUrls;
  final Map<String, dynamic>? metadata;
  final MessageStatus status;
  final MessageModel? replyTo;
  final List<MessageReaction>? reactions;
  final DateTime? editedAt;
  final bool isForwarded;
  final String? forwardedFromConversationId;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? tempId; // Temporary ID for optimistic message correlation

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderUsername: json['senderUsername'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      type: MessageType.values.byName(json['type'] as String),
      content: json['content'] as String?,
      mediaUrls: json['mediaUrls'] != null
          ? List<String>.from(json['mediaUrls'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: MessageStatus.values.byName(json['status'] as String),
      replyTo: json['replyTo'] != null
          ? MessageModel.fromJson(json['replyTo'])
          : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : null,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      isForwarded: json['isForwarded'] as bool? ?? false,
      forwardedFromConversationId:
          json['forwardedFromConversationId'] as String?,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tempId: json['tempId'] as String?,
    );
  }

  // Lightweight factory for lastMessage in conversation summaries  
  factory MessageModel.fromConversationSummary(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: '', // Not provided in summary
      senderId: '', // Not provided in summary 
      senderUsername: json['senderUsername']?.toString() ?? '',
      senderAvatar: null,
      type: _parseMessageType(json['type']),
      content: json['content']?.toString() ?? '',
      mediaUrls: null,
      metadata: null,
      status: MessageStatus.sent,
      replyTo: null,
      reactions: null,
      editedAt: null,
      isForwarded: false,
      forwardedFromConversationId: null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tempId: json['tempId'],
    );
  }

  // Backend-specific factory for API responses
  factory MessageModel.fromBackendJson(Map<String, dynamic> json) {
    // Defensive null handling for all fields
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderUsername: json['senderUsername']?.toString() ?? '',
      senderAvatar: json['senderAvatar']?.toString(),
      type: _parseMessageType(json['type']),
      content: json['content']?.toString() ?? '',
      mediaUrls: json['mediaUrls'] != null
          ? List<String>.from(json['mediaUrls'])
          : null,
      metadata: json['metadata'],
      status: _parseMessageStatus(json['status']),
      replyTo: json['replyTo'] != null
          ? MessageModel.fromBackendJson(json['replyTo'])
          : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : null,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'].toString())
          : null,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFromConversationId: json['forwardedFromConversationId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Helper methods for safe enum parsing
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    try {
      return MessageType.values.byName(type.toString());
    } catch (e) {
      return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    try {
      return MessageStatus.values.byName(status.toString());
    } catch (e) {
      return MessageStatus.sent;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'content': content,
      'mediaUrls': mediaUrls,
      'metadata': metadata,
      'status': status.name,
      'replyTo': replyTo?.toJson(),
      'reactions': reactions?.map((r) => r.toJson()).toList(),
      'editedAt': editedAt?.toIso8601String(),
      'isForwarded': isForwarded,
      'forwardedFromConversationId': forwardedFromConversationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderUsername,
    String? senderAvatar,
    MessageType? type,
    String? content,
    List<String>? mediaUrls,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
    MessageModel? replyTo,
    List<MessageReaction>? reactions,
    DateTime? editedAt,
    bool? isForwarded,
    String? forwardedFromConversationId,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tempId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      editedAt: editedAt ?? this.editedAt,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFromConversationId: forwardedFromConversationId ?? this.forwardedFromConversationId,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tempId: tempId ?? this.tempId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderUsername,
        senderAvatar,
        type,
        content,
        mediaUrls,
        metadata,
        status,
        replyTo,
        reactions,
        editedAt,
        isForwarded,
        forwardedFromConversationId,
        isBookmarked,
        createdAt,
        updatedAt,
    tempId,
      ];
}

/// Supporting classes
enum ConversationType { direct, group, channel }

enum MessageStatus { sending, sent, delivered, read, failed }

class ConversationSettings extends Equatable {
  const ConversationSettings({
    this.isPrivate = false,
    this.allowMediaSharing = true,
    this.allowCalls = true,
    this.messageRetention = 30,
  });

  final bool isPrivate;
  final bool allowMediaSharing;
  final bool allowCalls;
  final int messageRetention; // days

  factory ConversationSettings.fromJson(Map<String, dynamic> json) {
    return ConversationSettings(
      isPrivate: json['isPrivate'] ?? false,
      allowMediaSharing: json['allowMediaSharing'] ?? true,
      allowCalls: json['allowCalls'] ?? true,
      messageRetention: json['messageRetention'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPrivate': isPrivate,
      'allowMediaSharing': allowMediaSharing,
      'allowCalls': allowCalls,
      'messageRetention': messageRetention,
    };
  }

  @override
  List<Object?> get props => [isPrivate, allowMediaSharing, allowCalls, messageRetention];
}

class MessageReaction extends Equatable {
  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.username,
    required this.createdAt,
  });

  final String emoji;
  final String userId;
  final String username;
  final DateTime createdAt;

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'],
      userId: json['userId'],
      username: json['username'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'userId': userId,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [emoji, userId, username, createdAt];
}