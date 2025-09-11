import 'package:equatable/equatable.dart';
import 'user.dart';
import 'message.dart';

/// Conversation model for messaging
class Conversation extends Equatable {
  final String id;
  final String? title;
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
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      participants: (json['participants'] as List?)
          ?.map((p) => User.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
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
