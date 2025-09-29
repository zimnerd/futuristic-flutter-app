import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart' show MessageType, MessageStatus;
import 'user.dart';

/// Message model for messaging
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final User? sender;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final Message? replyTo;
  final List<String>? attachments;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Temporary ID for optimistic message correlation
  final String? tempId;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    this.metadata,
    this.replyToId,
    this.replyTo,
    this.attachments,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.tempId,
  });

  /// Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle both full message and lastMessage formats
    final String messageId = json['id'] as String;
    final String conversationId = json['conversationId'] as String? ?? '';
    final String senderId =
        json['senderId'] as String? ?? json['senderUsername'] as String? ?? '';
    final String content = json['content'] as String;
    final String createdAtStr = json['createdAt'] as String;
    final String updatedAtStr = json['updatedAt'] as String? ?? createdAtStr;

    return Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      sender: json['sender'] != null
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      content: content,
      type: _parseMessageType(json['type'] as String?),
      status: _parseMessageStatus(json['status'] as String?),
      metadata: json['metadata'] as Map<String, dynamic>?,
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] != null
          ? Message.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List?)?.cast<String>(),
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: DateTime.parse(updatedAtStr),
      tempId: json['tempId'] as String?,
    );
  }

  /// Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'sender': sender?.toJson(),
      'content': content,
      'type': type.name,
      'status': status.name,
      'metadata': metadata,
      'replyToId': replyToId,
      'replyTo': replyTo?.toJson(),
      'attachments': attachments,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tempId': tempId,
    };
  }

  /// Parse message type from string
  static MessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'sticker':
        return MessageType.sticker;
      case 'gif':
        return MessageType.gif;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Parse message status from string
  static MessageStatus _parseMessageStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  /// Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Check if message has attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  /// Check if message is a reply
  bool get isReply => replyToId != null;

  /// Check if message is a media message
  bool get isMedia => type == MessageType.image || 
                     type == MessageType.video || 
                     type == MessageType.audio;

  /// Get display content (handles deleted/edited messages)
  String get displayContent {
    if (isDeleted) return 'This message was deleted';
    return content;
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

  /// Copy with method for immutable updates
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    User? sender,
    String? content,
    MessageType? type,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    String? replyToId,
    Message? replyTo,
    List<String>? attachments,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tempId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      attachments: attachments ?? this.attachments,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
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
        sender,
        content,
        type,
        status,
        metadata,
        replyToId,
        replyTo,
        attachments,
        isEdited,
        editedAt,
        isDeleted,
        deletedAt,
        createdAt,
        updatedAt,
        tempId,
      ];
}

/// Message delivery update model for real-time status updates
class MessageDeliveryUpdate extends Equatable {
  final String messageId;
  final MessageStatus status;
  final DateTime timestamp;

  const MessageDeliveryUpdate({
    required this.messageId,
    required this.status,
    required this.timestamp,
  });

  factory MessageDeliveryUpdate.fromJson(Map<String, dynamic> json) {
    return MessageDeliveryUpdate(
      messageId: (json['messageId'] ?? '').toString(),
      status: MessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [messageId, status, timestamp];
}

/// Message read update model for real-time read status updates
class MessageReadUpdate extends Equatable {
  final String messageId;
  final String conversationId;
  final String userId;
  final DateTime timestamp;

  const MessageReadUpdate({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.timestamp,
  });

  factory MessageReadUpdate.fromJson(Map<String, dynamic> json) {
    return MessageReadUpdate(
      messageId: (json['messageId'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [messageId, conversationId, userId, timestamp];
}
