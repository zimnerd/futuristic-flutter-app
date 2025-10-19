import 'dart:convert';

/// Database model for conversations with local caching support
class ConversationDbModel {
  final String id;
  final String type;
  final List<String> participantIds;
  final String? name;
  final String? description;
  final String? imageUrl;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  const ConversationDbModel({
    required this.id,
    required this.type,
    required this.participantIds,
    this.name,
    this.description,
    this.imageUrl,
    this.lastMessageId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'participant_ids': participantIds.join(','),
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'last_message_id': lastMessageId,
      'last_message_at': lastMessageAt?.millisecondsSinceEpoch,
      'unread_count': unreadCount,
      'settings': settings != null ? jsonEncode(settings) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }

  /// Create from database map
  factory ConversationDbModel.fromMap(Map<String, dynamic> map) {
    return ConversationDbModel(
      id: map['id'] as String,
      type: map['type'] as String,
      participantIds: (map['participant_ids'] as String).split(','),
      name: map['name'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      lastMessageId: map['last_message_id'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_message_at'] as int)
          : null,
      unreadCount: map['unread_count'] as int? ?? 0,
      settings: map['settings'] != null
          ? jsonDecode(map['settings'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      syncStatus: map['sync_status'] as String? ?? 'synced',
    );
  }

  /// Create updated copy
  ConversationDbModel copyWith({
    String? id,
    String? type,
    List<String>? participantIds,
    String? name,
    String? description,
    String? imageUrl,
    String? lastMessageId,
    DateTime? lastMessageAt,
    int? unreadCount,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return ConversationDbModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'ConversationDbModel(id: $id, type: $type, participantIds: $participantIds, name: $name, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount, syncStatus: $syncStatus)';
  }
}

/// Database model for messages with optimized storage
class MessageDbModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final String type;
  final String? content;
  final List<String>? mediaUrls;
  final Map<String, dynamic>? metadata;
  final String status;
  final Map<String, dynamic>? reactions;
  final String? replyToId;
  final String? tempId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  const MessageDbModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderUsername,
    this.senderAvatar,
    required this.type,
    this.content,
    this.mediaUrls,
    this.metadata,
    required this.status,
    this.reactions,
    this.replyToId,
    this.tempId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'sender_avatar': senderAvatar,
      'type': type,
      'content': content,
      'media_urls': mediaUrls?.join(','),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'status': status,
      'reactions': reactions != null ? jsonEncode(reactions) : null,
      'reply_to_id': replyToId,
      'temp_id': tempId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }

  /// Create from database map
  factory MessageDbModel.fromMap(Map<String, dynamic> map) {
    return MessageDbModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      senderUsername: map['sender_username'] as String?,
      senderAvatar: map['sender_avatar'] as String?,
      type: map['type'] as String,
      content: map['content'] as String?,
      mediaUrls: map['media_urls'] != null
          ? (map['media_urls'] as String).split(',')
          : null,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
      status: map['status'] as String,
      reactions: map['reactions'] != null
          ? jsonDecode(map['reactions'] as String) as Map<String, dynamic>
          : null,
      replyToId: map['reply_to_id'] as String?,
      tempId: map['temp_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      syncStatus: map['sync_status'] as String? ?? 'synced',
    );
  }

  /// Create updated copy
  MessageDbModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderUsername,
    String? senderAvatar,
    String? type,
    String? content,
    List<String>? mediaUrls,
    Map<String, dynamic>? metadata,
    String? status,
    Map<String, dynamic>? reactions,
    String? replyToId,
    String? tempId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return MessageDbModel(
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
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      tempId: tempId ?? this.tempId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'MessageDbModel(id: $id, conversationId: $conversationId, senderId: $senderId, type: $type, content: $content, status: $status, createdAt: $createdAt, syncStatus: $syncStatus)';
  }
}

/// Pagination metadata for efficient message loading
class PaginationMetadata {
  final String conversationId;
  final String? oldestMessageId;
  final bool hasMoreMessages;
  final DateTime? lastSyncAt;
  final int totalMessagesCount;

  const PaginationMetadata({
    required this.conversationId,
    this.oldestMessageId,
    this.hasMoreMessages = true,
    this.lastSyncAt,
    this.totalMessagesCount = 0,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'oldest_message_id': oldestMessageId,
      'has_more_messages': hasMoreMessages ? 1 : 0,
      'last_sync_at': lastSyncAt?.millisecondsSinceEpoch,
      'total_messages_count': totalMessagesCount,
    };
  }

  /// Create from database map
  factory PaginationMetadata.fromMap(Map<String, dynamic> map) {
    return PaginationMetadata(
      conversationId: map['conversation_id'] as String,
      oldestMessageId: map['oldest_message_id'] as String?,
      hasMoreMessages: (map['has_more_messages'] as int? ?? 1) == 1,
      lastSyncAt: map['last_sync_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_sync_at'] as int)
          : null,
      totalMessagesCount: map['total_messages_count'] as int? ?? 0,
    );
  }

  /// Create updated copy
  PaginationMetadata copyWith({
    String? conversationId,
    String? oldestMessageId,
    bool? hasMoreMessages,
    DateTime? lastSyncAt,
    int? totalMessagesCount,
  }) {
    return PaginationMetadata(
      conversationId: conversationId ?? this.conversationId,
      oldestMessageId: oldestMessageId ?? this.oldestMessageId,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      totalMessagesCount: totalMessagesCount ?? this.totalMessagesCount,
    );
  }

  @override
  String toString() {
    return 'PaginationMetadata(conversationId: $conversationId, oldestMessageId: $oldestMessageId, hasMoreMessages: $hasMoreMessages, totalMessagesCount: $totalMessagesCount)';
  }
}
