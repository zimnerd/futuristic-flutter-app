import 'package:equatable/equatable.dart';

/// Message entity for chat functionality
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.replyToMessageId,
    this.isDelivered = false,
    this.isRead = false,
    this.isOptimistic = false,
    this.mediaUrl,
    this.mediaType,
    this.mediaDuration,
    this.reactions = const [],
    this.status = MessageStatus.sent,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? replyToMessageId;
  final bool isDelivered;
  final bool isRead;
  final bool isOptimistic; // For optimistic UI updates
  final String? mediaUrl;
  final String? mediaType;
  final int? mediaDuration; // For audio/video messages
  final List<MessageReaction> reactions;
  final MessageStatus status;
  final DateTime? createdAt;

  /// Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  /// Check if message has media content
  bool get hasMedia {
    return type != MessageType.text && mediaUrl != null;
  }

  /// Get reaction count for specific emoji
  int getReactionCount(String emoji) {
    return reactions.where((r) => r.emoji == emoji).length;
  }

  /// Check if user has reacted with specific emoji
  bool hasUserReacted(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? replyToMessageId,
    bool? isDelivered,
    bool? isRead,
    bool? isOptimistic,
    String? mediaUrl,
    String? mediaType,
    int? mediaDuration,
    List<MessageReaction>? reactions,
    MessageStatus? status,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      replyToMessageId: json['replyToMessageId'] as String?,
      isDelivered: json['isDelivered'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      isOptimistic: json['isOptimistic'] as bool? ?? false,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      mediaDuration: json['mediaDuration'] as int?,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map(
                (reaction) =>
                    MessageReaction.fromJson(reaction as Map<String, dynamic>),
              )
              .toList() ??
          [],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'replyToMessageId': replyToMessageId,
      'isDelivered': isDelivered,
      'isRead': isRead,
      'isOptimistic': isOptimistic,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'mediaDuration': mediaDuration,
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        type,
        timestamp,
        replyToMessageId,
        isDelivered,
        isRead,
        isOptimistic,
        mediaUrl,
        mediaType,
        mediaDuration,
        reactions,
    status,
    createdAt,
      ];
}

/// Message type enumeration
enum MessageType {
  text,
  image,
  video,
  audio,
  gif,
  sticker,
  location,
  contact,
  file,
  system,
  call, // WhatsApp-style call messages
}

/// Message status enumeration
enum MessageStatus { sending, sent, delivered, read, failed,
}

/// Message reaction entity
class MessageReaction extends Equatable {
  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime timestamp;

  MessageReaction copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? emoji,
    DateTime? timestamp,
  }) {
    return MessageReaction(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Create MessageReaction from JSON
  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      emoji: json['emoji'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert MessageReaction to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'userId': userId,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, messageId, userId, emoji, timestamp];
}
