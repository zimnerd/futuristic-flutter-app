import '../../domain/entities/conversation.dart';

/// Data model for Conversation with JSON serialization
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.otherUserId,
    required super.otherUserName,
    required super.otherUserAvatar,
    required super.lastMessage,
    required super.lastMessageTime,
    super.unreadCount = 0,
    super.isOnline = false,
    super.lastSeen,
    super.isBlocked = false,
    super.isMuted = false,
    super.isPinned = false,
    super.matchedAt,
  });

  /// Convert from JSON
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String,
      otherUserAvatar: json['otherUserAvatar'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      matchedAt: json['matchedAt'] != null 
          ? DateTime.parse(json['matchedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'isBlocked': isBlocked,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'matchedAt': matchedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Conversation toEntity() {
    return Conversation(
      id: id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isOnline: isOnline,
      lastSeen: lastSeen,
      isBlocked: isBlocked,
      isMuted: isMuted,
      isPinned: isPinned,
      matchedAt: matchedAt,
    );
  }

  /// Create from domain entity
  factory ConversationModel.fromEntity(Conversation entity) {
    return ConversationModel(
      id: entity.id,
      otherUserId: entity.otherUserId,
      otherUserName: entity.otherUserName,
      otherUserAvatar: entity.otherUserAvatar,
      lastMessage: entity.lastMessage,
      lastMessageTime: entity.lastMessageTime,
      unreadCount: entity.unreadCount,
      isOnline: entity.isOnline,
      lastSeen: entity.lastSeen,
      isBlocked: entity.isBlocked,
      isMuted: entity.isMuted,
      isPinned: entity.isPinned,
      matchedAt: entity.matchedAt,
    );
  }
}
