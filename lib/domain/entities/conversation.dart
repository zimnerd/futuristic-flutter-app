import 'package:equatable/equatable.dart';
import 'user_profile.dart';

/// Conversation entity for messaging
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.otherUserAvatarBlurhash, // 🎯 Add blurhash for progressive avatar loading
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.isBlocked = false,
    this.isMuted = false,
    this.isPinned = false,
    this.matchedAt,
    this.otherUser,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String? otherUserAvatarBlurhash;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBlocked;
  final bool isMuted;
  final bool isPinned;
  final DateTime? matchedAt;
  final UserProfile? otherUser;

  /// Get display name for conversation
  String get displayName => otherUserName;

  /// Get formatted last message time
  String get formattedLastMessageTime {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  /// Get online status text
  String get onlineStatusText {
    if (isOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      final difference = DateTime.now().difference(lastSeen!);
      if (difference.inDays > 0) {
        return 'Last seen ${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else {
        return 'Last seen recently';
      }
    } else {
      return 'Offline';
    }
  }

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Check if it's a new match (within 24 hours)
  bool get isNewMatch {
    if (matchedAt == null) return false;
    final difference = DateTime.now().difference(matchedAt!);
    return difference.inHours < 24;
  }

  Conversation copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserAvatarBlurhash,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isBlocked,
    bool? isMuted,
    bool? isPinned,
    DateTime? matchedAt,
    UserProfile? otherUser,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      otherUserAvatarBlurhash:
          otherUserAvatarBlurhash ?? this.otherUserAvatarBlurhash,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isBlocked: isBlocked ?? this.isBlocked,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      matchedAt: matchedAt ?? this.matchedAt,
      otherUser: otherUser ?? this.otherUser,
    );
  }

  @override
  List<Object?> get props => [
    id,
    otherUserId,
    otherUserName,
    otherUserAvatar,
    otherUserAvatarBlurhash,
    lastMessage,
    lastMessageTime,
    unreadCount,
    isOnline,
    lastSeen,
    isBlocked,
    isMuted,
    isPinned,
    matchedAt,
    otherUser,
  ];
}
