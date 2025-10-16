import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'user.dart';
import 'message.dart';

/// Conversation model for messaging
class Conversation extends Equatable {
  final String id;
  final String? title;
  final bool isGroup;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime? lastActivity;
  final int unreadCount;
  final bool isActive;
  final bool isBlocked;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    this.title,
    this.isGroup = false,
    required this.participants,
    this.lastMessage,
    this.lastActivity,
    this.unreadCount = 0,
    this.isActive = true,
    this.isBlocked = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Conversation from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    try {
      final String conversationId = json['id'] as String;
      final String? conversationTitle =
          json['title'] as String? ?? json['name'] as String?;
      
      return Conversation(
        id: conversationId,
        title: conversationTitle,
        isGroup: json['isGroup'] ?? false,
        participants:
            (json['participants'] as List?)?.map<User>((p) {
              try {
                // Transform participant data to match User format
                final participant = p as Map<String, dynamic>;

                // Extract participant fields with fallbacks
                final userId = participant['userId'] ?? participant['id'] ?? '';
                final email = participant['email'] ?? '';
                final username = participant['username'];
                final firstName = participant['firstName'];
                final lastName = participant['lastName'];
                final bio = participant['bio'];
                final age = participant['age'];
                final gender = participant['gender'];
                final avatar = participant['avatar'];
                final location = participant['location'];
                final interests = participant['interests'] ?? [];
                final photos = participant['photos'] ?? [];
                final isOnline = participant['isOnline'] ?? false;
                final lastSeen = participant['lastSeen'];
                final isVerified = participant['isVerified'] ?? false;
                final isPremium = participant['isPremium'] ?? false;
                final preferences = participant['preferences'];
                final metadata = participant['metadata'];
                final createdAt =
                    participant['createdAt'] ??
                    participant['joinedAt'] ??
                    DateTime.now().toIso8601String();
                final updatedAt =
                    participant['updatedAt'] ??
                    participant['lastReadAt'] ??
                    DateTime.now().toIso8601String();

                return User.fromJson({
                  'id': userId,
                  'email': email,
                  'username': username,
                  'firstName': firstName,
                  'lastName': lastName,
                  'bio': bio,
                  'age': age,
                  'gender': gender,
                  'profileImageUrl': avatar, // Map avatar to profileImageUrl
                  'location': location,
                  'interests': interests,
                  'photos': photos,
                  'isOnline': isOnline,
                  'lastSeen': lastSeen,
                  'isVerified': isVerified,
                  'isPremium': isPremium,
                  'preferences': preferences,
                  'metadata': metadata,
                  'createdAt': createdAt,
                  'updatedAt': updatedAt,
                });
              } catch (e) {
                // Fallback to a basic user if participant parsing fails
                debugPrint('Warning: Error parsing participant: $e');
                final participantMap = p as Map<String, dynamic>;
                return User.fromJson({
                  'id': participantMap['userId'] ?? '',
                  'username': participantMap['username'] ?? 'Unknown',
                  'email': '',
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                });
              }
            }).toList() ??
            [],
        lastMessage: json['lastMessage'] != null
            ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        lastActivity: json['lastActivity'] != null
            ? DateTime.parse(json['lastActivity'] as String)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        isBlocked: json['isBlocked'] as bool? ?? false,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    } catch (e) {
      debugPrint('Warning: Error in Conversation.fromJson: $e');
      rethrow;
    }
  }

  /// Convert Conversation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity?.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'isBlocked': isBlocked,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get other participant (for 1-on-1 conversations)
  User? get otherParticipant {
    if (participants.length == 2) {
      // Return the participant that's not the current user
      // Note: You'll need to pass current user ID to filter properly
      return participants.first;
    }
    return null;
  }

  /// Get avatar URL for conversation
  String get avatar {
    if (participants.isNotEmpty) {
      // For 1-on-1 conversations, use the other participant's avatar
      // For group conversations, use the first participant's avatar
      final targetUser = otherParticipant ?? participants.first;

      // First try profileImageUrl
      if (targetUser.profileImageUrl != null &&
          targetUser.profileImageUrl!.isNotEmpty) {
        debugPrint('🐛 Using profileImageUrl: ${targetUser.profileImageUrl}');
        return targetUser.profileImageUrl!;
      }

      // Fallback to first photo if available
      if (targetUser.photos.isNotEmpty) {
        final firstPhoto = targetUser.photos.first;
        // Photos are now Photo objects with url property
        debugPrint('🐛 Using first photo: ${firstPhoto.url}');
        return firstPhoto.url;
      }

      debugPrint('🐛 No avatar found for user: ${targetUser.name}');
    }
    return '';
  }

  /// Get display name for conversation
  String get displayName {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    
    if (participants.length == 1) {
      return participants.first.name;
    } else if (participants.length == 2) {
      return otherParticipant?.name ?? 'Chat';
    } else {
      return 'Group Chat (${participants.length})';
    }
  }

  /// Copy with method for immutable updates
  Conversation copyWith({
    String? id,
    String? title,
    List<User>? participants,
    Message? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isActive,
    bool? isBlocked,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
    isGroup,
        participants,
        lastMessage,
        lastActivity,
        unreadCount,
        isActive,
        isBlocked,
        metadata,
        createdAt,
        updatedAt,
      ];
}
