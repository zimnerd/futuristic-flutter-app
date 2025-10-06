import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../data/models.dart';

/// Group chat service using centralized ApiClient for all API calls
/// ✅ Automatic auth token injection
/// ✅ Automatic token refresh on 401
/// ✅ Centralized logging and error handling
/// ✅ Consistent with rest of codebase
class GroupChatService {
  final ApiClient _apiClient = ApiClient.instance;
  final Logger _logger = Logger();

  /// Create a new group conversation
  Future<GroupConversation> createGroup({
    required String title,
    required GroupType groupType,
    required List<String> participantUserIds,
    int maxParticipants = 50,
    bool allowParticipantInvite = true,
    bool requireApproval = false,
    bool autoAcceptFriends = true,
    bool enableVoiceChat = true,
    bool enableVideoChat = false,
  }) async {
    try {
      final response = await _apiClient.createGroup(
        title: title,
        groupType: groupType.name.toUpperCase(),
        participantUserIds: participantUserIds,
        maxParticipants: maxParticipants,
        allowParticipantInvite: allowParticipantInvite,
        requireApproval: requireApproval,
        autoAcceptFriends: autoAcceptFriends,
        enableVoiceChat: enableVoiceChat,
        enableVideoChat: enableVideoChat,
      );

      if (response.statusCode == 201) {
        return GroupConversation.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create group: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error creating group: $e');
      rethrow;
    }
  }

  /// Create a live session (Monkey.app style)
  Future<LiveSession> createLiveSession({
    required String conversationId,
    required String title,
    String? description,
    int? maxParticipants,
    bool requireApproval = true,
  }) async {
    try {
      final response = await _apiClient.createLiveSession(
        conversationId: conversationId,
        title: title,
        description: description,
        maxParticipants: maxParticipants,
        requireApproval: requireApproval,
      );

      if (response.statusCode == 201) {
        return LiveSession.fromJson(response.data['data']);
      } else {
        throw Exception(
          'Failed to create live session: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error creating live session: $e');
      rethrow;
    }
  }

  /// Get all active live sessions
  Future<List<LiveSession>> getActiveLiveSessions({GroupType? groupType}) async {
    try {
      final response = await _apiClient.getActiveLiveSessions(
        groupType: groupType?.name.toUpperCase(),
      );

      if (response.statusCode == 200) {
        final sessions = response.data['data'] as List;
        return sessions.map((s) => LiveSession.fromJson(s)).toList();
      } else {
        throw Exception(
          'Failed to load live sessions: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error loading live sessions: $e');
      rethrow;
    }
  }

  /// Request to join a live session
  Future<JoinRequest> requestToJoinSession({
    required String liveSessionId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.joinLiveSession(
        sessionId: liveSessionId,
        message: message,
      );

      if (response.statusCode == 201) {
        return JoinRequest.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to request join: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error requesting to join session: $e');
      rethrow;
    }
  }

  /// Get pending join requests for a live session (host only)
  Future<List<JoinRequest>> getPendingJoinRequests(String liveSessionId) async {
    try {
      final response = await _apiClient.getPendingJoinRequests(liveSessionId);

      if (response.statusCode == 200) {
        final requests = response.data['data'] as List;
        return requests.map((r) => JoinRequest.fromJson(r)).toList();
      } else {
        throw Exception(
          'Failed to load join requests: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error loading join requests: $e');
      rethrow;
    }
  }

  /// Approve a join request (host only)
  Future<void> approveJoinRequest(String requestId) async {
    try {
      final response = await _apiClient.approveJoinRequest(requestId);

      if (response.statusCode != 200) {
        throw Exception('Failed to approve request: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error approving join request: $e');
      rethrow;
    }
  }

  /// Reject a join request (host only)
  Future<void> rejectJoinRequest(String requestId) async {
    try {
      final response = await _apiClient.rejectJoinRequest(requestId: requestId);

      if (response.statusCode != 200) {
        throw Exception('Failed to reject request: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error rejecting join request: $e');
      rethrow;
    }
  }

  /// Get all groups the user belongs to
  Future<List<GroupConversation>> getUserGroups() async {
    try {
      final response = await _apiClient.getUserGroups();

      if (response.statusCode == 200) {
        final groups = response.data['data'] as List;
        return groups.map((g) => GroupConversation.fromJson(g)).toList();
      } else {
        throw Exception(
          'Failed to load user groups: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error loading user groups: $e');
      rethrow;
    }
  }

  /// Get group details
  Future<GroupConversation> getGroupDetails(String conversationId) async {
    try {
      final response = await _apiClient.getGroupDetails(conversationId);

      if (response.statusCode == 200) {
        return GroupConversation.fromJson(response.data['data']);
      } else {
        throw Exception(
          'Failed to load group details: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error loading group details: $e');
      rethrow;
    }
  }

  /// Add participant to group (admin only)
  Future<void> addParticipant({
    required String conversationId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
  }) async {
    try {
      final response = await _apiClient.addGroupParticipant(
        conversationId: conversationId,
        userId: userId,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add participant: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error adding participant: $e');
      rethrow;
    }
  }

  /// Remove participant from group (admin only)
  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.removeGroupParticipant(
        targetUserId: userId,
        conversationId: conversationId,
        reason: reason,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove participant: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error removing participant: $e');
      rethrow;
    }
  }

  /// Report a user in group chat
  Future<void> reportUser({
    required String conversationId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _apiClient.reportGroup(
        reportedContentId: reportedUserId,
        reportType: 'USER',
        reason: reason,
        details: description,
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to report user: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error reporting user: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation
  Future<List<GroupMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Use ApiClient's underlying Dio for requests without dedicated methods
      // Still benefits from auto auth token, interceptors, logging
      final response = await _apiClient.dio.get(
        '/group-chat/conversations/$conversationId/messages',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final messages = response.data['data'] as List;
        return messages.map((m) => GroupMessage.fromJson(m)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error loading messages: $e');
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '/group-chat/conversations/$conversationId/messages/$messageId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error deleting message: $e');
      rethrow;
    }
  }

  /// Add reaction to a message
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversations/$conversationId/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add reaction: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '/group-chat/conversations/$conversationId/messages/$messageId/reactions/$emoji',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove reaction: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error removing reaction: $e');
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversations/$conversationId/messages/$messageId/read',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark message as read: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error marking message as read: $e');
      rethrow;
    }
  }

  /// Search messages in a conversation
  Future<List<GroupMessage>> searchMessages({
    required String conversationId,
    required String query,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/group-chat/conversations/$conversationId/messages/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final messages = response.data['data'] as List;
        return messages.map((m) => GroupMessage.fromJson(m)).toList();
      } else {
        throw Exception('Failed to search messages: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error searching messages: $e');
      rethrow;
    }
  }

  /// Update group settings
  Future<GroupConversation> updateGroupSettings({
    required String conversationId,
    String? title,
    String? description,
    bool? allowParticipantInvite,
    bool? requireApproval,
    bool? autoAcceptFriends,
    bool? enableVoiceChat,
    bool? enableVideoChat,
    int? maxParticipants,
  }) async {
    try {
      final settings = <String, dynamic>{};
      if (title != null) settings['title'] = title;
      if (description != null) settings['description'] = description;
      if (allowParticipantInvite != null) {
        settings['allowParticipantInvite'] = allowParticipantInvite;
      }
      if (requireApproval != null) {
        settings['requireApproval'] = requireApproval;
      }
      if (autoAcceptFriends != null) {
        settings['autoAcceptFriends'] = autoAcceptFriends;
      }
      if (enableVoiceChat != null) {
        settings['enableVoiceChat'] = enableVoiceChat;
      }
      if (enableVideoChat != null) {
        settings['enableVideoChat'] = enableVideoChat;
      }
      if (maxParticipants != null) {
        settings['maxParticipants'] = maxParticipants;
      }

      final response = await _apiClient.updateGroupSettings(
        conversationId: conversationId,
        settings: settings,
      );

      if (response.statusCode == 200) {
        return GroupConversation.fromJson(response.data['data']);
      } else {
        throw Exception(
          'Failed to update group settings: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error updating group settings: $e');
      rethrow;
    }
  }

  /// Change a participant's role in the group (owner only)
  Future<void> changeParticipantRole({
    required String conversationId,
    required String targetUserId,
    required ParticipantRole role,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.changeParticipantRole(
        conversationId: conversationId,
        targetUserId: targetUserId,
        role: role.name.toUpperCase(),
        reason: reason,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to change participant role: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error changing participant role: $e');
      rethrow;
    }
  }

  /// Leave a group conversation
  Future<void> leaveGroup({
    required String conversationId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.leaveGroup(conversationId);

      if (response.statusCode != 200) {
        throw Exception('Failed to leave group: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error leaving group: $e');
      rethrow;
    }
  }

  /// Delete a group conversation (owner only)
  Future<void> deleteGroup({required String conversationId}) async {
    try {
      final response = await _apiClient.deleteGroup(conversationId);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete group: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error deleting group: $e');
      rethrow;
    }
  }

  /// Upload group photo
  Future<String> uploadGroupPhoto({
    required String conversationId,
    required String imagePath,
  }) async {
    try {
      // Use FormData for file uploads with Dio
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiClient.dio.post(
        '/group-chat/conversation/$conversationId/photo',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['data']['photoUrl'] as String;
      } else {
        throw Exception(
          'Failed to upload group photo: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error uploading group photo: $e');
      rethrow;
    }
  }

  /// Remove group photo
  Future<void> removeGroupPhoto({required String conversationId}) async {
    try {
      final response = await _apiClient.dio.delete(
        '/group-chat/conversation/$conversationId/photo',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove group photo: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error removing group photo: $e');
      rethrow;
    }
  }

  /// Get blocked users in a conversation
  Future<List<BlockedUser>> getBlockedUsers({
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/group-chat/conversation/$conversationId/blocked-users',
      );

      if (response.statusCode == 200) {
        final users = response.data['data'] as List;
        return users.map((u) => BlockedUser.fromJson(u)).toList();
      } else {
        throw Exception(
          'Failed to get blocked users: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error getting blocked users: $e');
      rethrow;
    }
  }

  /// Block a user in a conversation
  Future<void> blockUser({
    required String conversationId,
    required String userId,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversation/$conversationId/block-user',
        data: {'userId': userId, if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to block user: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user in a conversation
  Future<void> unblockUser({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversation/$conversationId/unblock-user',
        data: {'userId': userId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unblock user: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Get reported content in a conversation
  Future<List<ReportedContent>> getReportedContent({
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/group-chat/conversation/$conversationId/reports',
      );

      if (response.statusCode == 200) {
        final reports = response.data['data'] as List;
        return reports.map((r) => ReportedContent.fromJson(r)).toList();
      } else {
        throw Exception(
          'Failed to get reported content: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error getting reported content: $e');
      rethrow;
    }
  }

  /// Search users to add to group
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.searchUsersForGroup(
        conversationId: conversationId,
        query: query,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Failed to search users: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error searching users: $e');
      rethrow;
    }
  }

  /// Review/moderate a report
  Future<void> reviewReport({
    required String conversationId,
    required String reportId,
    required String action,
    String? reviewNotes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversation/$conversationId/reports/$reportId/review',
        data: {
          'action': action,
          if (reviewNotes != null) 'reviewNotes': reviewNotes,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to review report: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error reviewing report: $e');
      rethrow;
    }
  }

  /// Toggle call recording
  Future<void> toggleRecording({
    required String conversationId,
    required bool enabled,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversation/$conversationId/recording',
        data: {'enabled': enabled},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to toggle recording: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error toggling recording: $e');
      rethrow;
    }
  }

  /// Enable/disable screen sharing
  Future<void> toggleScreenSharing({
    required String conversationId,
    required bool enabled,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/conversation/$conversationId/screen-sharing',
        data: {'enabled': enabled},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to toggle screen sharing: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error toggling screen sharing: $e');
      rethrow;
    }
  }

  /// Upload media file (image, video, or audio)
  Future<Map<String, dynamic>> uploadMedia({
    required String filePath,
    required String mediaType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'mediaType': mediaType,
        if (metadata != null) 'metadata': metadata,
      });

      final response = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to upload media: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error uploading media: $e');
      rethrow;
    }
  }

  /// Report a message
  Future<Map<String, dynamic>> reportMessage({
    required String messageId,
    required String reason,
    String? details,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/chat/messages/$messageId/report',
        data: {'reason': reason, if (details != null) 'details': details,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to report message: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error reporting message: $e');
      rethrow;
    }
  }

  /// Get conversation media gallery
  Future<List<Map<String, dynamic>>> getConversationMedia({
    required String conversationId,
    String? mediaType, // 'image', 'video', 'audio', 'file'
    int limit = 50,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'limit': limit};
      if (mediaType != null) {
        queryParameters['type'] = mediaType;
      }

      final response = await _apiClient.dio.get(
        '/chat/conversations/$conversationId/media',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final messages = response.data['data']['messages'] as List;
        return List<Map<String, dynamic>>.from(messages);
      } else {
        throw Exception(
          'Failed to get conversation media: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error getting conversation media: $e');
      rethrow;
    }
  }

  /// Report a group
  Future<Map<String, dynamic>> reportGroup({
    required String conversationId,
    required String reason,
    String? details,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/group-chat/report',
        data: {
          'conversationId': conversationId,
          'reason': reason,
          if (details != null) 'details': details,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to report group: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error reporting group: $e');
      rethrow;
    }
  }
}
