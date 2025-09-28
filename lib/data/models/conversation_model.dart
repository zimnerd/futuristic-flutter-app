import 'package:flutter/foundation.dart';
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

  /// Convert from backend API response
  factory ConversationModel.fromBackendJson(Map<String, dynamic> json) {
    // Map backend fields to our model fields
    final participants = json['participants'] as List<dynamic>? ?? [];
    
    // We need to find the "other" participant (not the current user)
    // For now, we'll take the first participant, but this should be improved
    // to find the participant who is NOT the current user
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
          otherParticipant = validParticipants.firstWhere(
            (p) => p['role'] == 'member', // Try to find the non-admin participant
            orElse: () => validParticipants.first, // Fallback to first participant
          );
        }
      } catch (e) {
        debugPrint('Error parsing participants in fromBackendJson: $e');
        otherParticipant = null;
      }
    }

    // Handle lastMessage - use backend response structure
    String lastMessageContent = 'No messages yet';
    DateTime lastMessageTime = DateTime.now();
    
    final lastMessageData = json['lastMessage'];
    
    if (lastMessageData != null) {
      // Backend provides lastMessage with this structure:
      // { id, content, type, senderUsername, createdAt }
      lastMessageContent = lastMessageData['content'] as String? ?? 'No content';
      
      if (lastMessageData['createdAt'] != null) {
        try {
          lastMessageTime = DateTime.parse(lastMessageData['createdAt'] as String);
        } catch (e) {
          print('Error parsing lastMessage createdAt: $e');
        }
      }
    } else {
      // Check if there's an updatedAt field we can use for timing
      if (json['updatedAt'] != null) {
        try {
          lastMessageTime = DateTime.parse(json['updatedAt'] as String);
        } catch (e) {
          print('Error parsing updatedAt: $e');
        }
      }
    }

    return ConversationModel(
      id: json['id'] as String,
      otherUserId: otherParticipant?['userId'] as String? ?? '',
      otherUserName:
          '${otherParticipant?['firstName'] ?? ''} ${otherParticipant?['lastName'] ?? ''}'
              .trim()
              .isEmpty
          ? (otherParticipant?['username'] as String? ?? 'Unknown')
          : '${otherParticipant?['firstName'] ?? ''} ${otherParticipant?['lastName'] ?? ''}'
                .trim(),
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
