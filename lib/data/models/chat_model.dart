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
      id: json['id'],
      type: ConversationType.values.byName(json['type']),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      settings: json['settings'] != null
          ? ConversationSettings.fromJson(json['settings'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
    required this.createdAt,
    required this.updatedAt,
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
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      senderAvatar: json['senderAvatar'],
      type: MessageType.values.byName(json['type']),
      content: json['content'],
      mediaUrls: json['mediaUrls'] != null
          ? List<String>.from(json['mediaUrls'])
          : null,
      metadata: json['metadata'],
      status: MessageStatus.values.byName(json['status']),
      replyTo: json['replyTo'] != null
          ? MessageModel.fromJson(json['replyTo'])
          : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : null,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFromConversationId: json['forwardedFromConversationId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        createdAt,
        updatedAt,
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