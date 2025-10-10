import 'package:flutter/foundation.dart';
import '../../domain/entities/conversation.dart';
import '../../core/utils/logger.dart';

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

  /// Convert from backend API response
  /// [currentUserId] is needed to identify which participant is the "other" user
  factory ConversationModel.fromBackendJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Map backend fields to our model fields
    final participants = json['participants'] as List<dynamic>? ?? [];
    
    // Find the "other" participant (not the current user)
    Map<String, dynamic>? otherParticipant;
    
    if (participants.isNotEmpty) {
      try {
        // Convert participants to proper Map objects and validate
        final validParticipants = <Map<String, dynamic>>[];
        for (final participant in participants) {
          if (participant is Map<String, dynamic>) {
            validParticipants.add(participant);
          } else {
            debugPrint('Invalid participant type in fromBackendJson: ${participant.runtimeType}, value: $participant');
          }
        }
        
        if (validParticipants.isNotEmpty) {
          if (currentUserId != null) {
            // Find participant that is NOT the current user
            otherParticipant = validParticipants.firstWhere(
              (p) => p['userId'] != currentUserId,
              orElse: () => validParticipants.first,
            );
          } else {
            // Fallback: try to find the non-admin participant
            otherParticipant = validParticipants.firstWhere(
              (p) => p['role'] == 'member',
              orElse: () => validParticipants.first,
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing participants in fromBackendJson: $e');
        otherParticipant = null;
      }
    }

    // Handle lastMessage - use backend response structure
    String lastMessageContent = 'No messages yet';
    DateTime lastMessageTime;
    
    final lastMessageData = json['lastMessage'];
    
    if (lastMessageData != null) {
      // Backend provides lastMessage with this structure:
      // { id, content, type, senderUsername, createdAt }
      final content = lastMessageData['content'] as String? ?? '';
      final type = lastMessageData['type'] as String? ?? 'text';

      // Provide appropriate preview based on message type
      if (content.isNotEmpty) {
        lastMessageContent = content;
      } else if (type == 'image') {
        lastMessageContent = '📷 Photo';
      } else if (type == 'video') {
        lastMessageContent = '🎥 Video';
      } else if (type == 'audio' || type == 'voice') {
        lastMessageContent = '🎵 Voice message';
      } else if (type == 'file') {
        lastMessageContent = '📄 Attachment';
      } else {
        lastMessageContent = 'No content';
      }
      
      if (lastMessageData['createdAt'] != null) {
        try {
          lastMessageTime = DateTime.parse(lastMessageData['createdAt'] as String);
        } catch (e) {
          AppLogger.debug('Error parsing lastMessage createdAt: $e');
          // Fallback to conversation creation time or a reasonable past time
          lastMessageTime = json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now().subtract(const Duration(hours: 24));
        }
      } else {
        // Fallback to conversation creation time
        lastMessageTime = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now().subtract(const Duration(hours: 24));
      }
    } else {
      // No last message - use conversation creation time or updatedAt
      if (json['createdAt'] != null) {
        try {
          lastMessageTime = DateTime.parse(json['createdAt'] as String);
        } catch (e) {
          AppLogger.debug('Error parsing createdAt: $e');
          lastMessageTime = DateTime.now().subtract(const Duration(hours: 24));
        }
      } else if (json['updatedAt'] != null) {
        try {
          lastMessageTime = DateTime.parse(json['updatedAt'] as String);
        } catch (e) {
          AppLogger.debug('Error parsing updatedAt: $e');
          lastMessageTime = DateTime.now().subtract(const Duration(hours: 24));
        }
      } else {
        // Ultimate fallback - 24 hours ago instead of now
        lastMessageTime = DateTime.now().subtract(const Duration(hours: 24));
      }
    }

    // Construct other user's display name with better fallbacks
    String otherUserDisplayName = 'Unknown User';
    if (otherParticipant != null) {
      final firstName = otherParticipant['firstName'] as String? ?? '';
      final lastName = otherParticipant['lastName'] as String? ?? '';
      final username = otherParticipant['username'] as String? ?? '';
      
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        otherUserDisplayName = fullName;
      } else if (username.isNotEmpty) {
        otherUserDisplayName = username;
      }
    }

    return ConversationModel(
      id: json['id'] as String,
      otherUserId: otherParticipant?['userId'] as String? ?? '',
      otherUserName: otherUserDisplayName,
      otherUserAvatar: otherParticipant?['avatar'] as String? ?? '',
      lastMessage: lastMessageContent,
      lastMessageTime: lastMessageTime,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: otherParticipant?['isOnline'] as bool? ?? false,
      lastSeen: otherParticipant?['lastSeen'] != null
          ? DateTime.parse(otherParticipant!['lastSeen'] as String)
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
