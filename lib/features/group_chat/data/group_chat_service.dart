import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models.dart';

class GroupChatService {
  final String baseUrl;
  final String? accessToken;

  GroupChatService({
    required this.baseUrl,
    this.accessToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

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
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/create'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'groupType': groupType.name.toUpperCase(),
        'participantUserIds': participantUserIds,
        'maxParticipants': maxParticipants,
        'allowParticipantInvite': allowParticipantInvite,
        'requireApproval': requireApproval,
        'autoAcceptFriends': autoAcceptFriends,
        'enableVoiceChat': enableVoiceChat,
        'enableVideoChat': enableVideoChat,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return GroupConversation.fromJson(data['data']);
    } else {
      throw Exception('Failed to create group: ${response.body}');
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
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/live-session/create'),
      headers: _headers,
      body: jsonEncode({
        'conversationId': conversationId,
        'title': title,
        'description': description,
        'maxParticipants': maxParticipants,
        'requireApproval': requireApproval,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return LiveSession.fromJson(data['data']);
    } else {
      throw Exception('Failed to create live session: ${response.body}');
    }
  }

  /// Get all active live sessions
  Future<List<LiveSession>> getActiveLiveSessions({GroupType? groupType}) async {
    final queryParams = groupType != null
        ? '?groupType=${groupType.name.toUpperCase()}'
        : '';
    
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/live-sessions/active$queryParams'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sessions = data['data'] as List;
      return sessions.map((s) => LiveSession.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load live sessions: ${response.body}');
    }
  }

  /// Request to join a live session
  Future<JoinRequest> requestToJoinSession({
    required String liveSessionId,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/live-session/join'),
      headers: _headers,
      body: jsonEncode({
        'liveSessionId': liveSessionId,
        'requestMessage': message,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return JoinRequest.fromJson(data['data']);
    } else {
      throw Exception('Failed to request join: ${response.body}');
    }
  }

  /// Get pending join requests for a live session (host only)
  Future<List<JoinRequest>> getPendingJoinRequests(String liveSessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/live-session/$liveSessionId/join-requests'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final requests = data['data'] as List;
      return requests.map((r) => JoinRequest.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load join requests: ${response.body}');
    }
  }

  /// Approve a join request (host only)
  Future<void> approveJoinRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/join-request/$requestId/approve'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve request: ${response.body}');
    }
  }

  /// Reject a join request (host only)
  Future<void> rejectJoinRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/join-request/$requestId/reject'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }

  /// Get all groups the user belongs to
  Future<List<GroupConversation>> getUserGroups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/user-groups'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final groups = data['data'] as List;
      return groups.map((g) => GroupConversation.fromJson(g)).toList();
    } else {
      throw Exception('Failed to load user groups: ${response.body}');
    }
  }

  /// Get group details
  Future<GroupConversation> getGroupDetails(String conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupConversation.fromJson(data['data']);
    } else {
      throw Exception('Failed to load group details: ${response.body}');
    }
  }

  /// Add participant to group (admin only)
  Future<void> addParticipant({
    required String conversationId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/add-participant'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'role': role.name.toUpperCase(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add participant: ${response.body}');
    }
  }

  /// Remove participant from group (admin only)
  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/remove-participant'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove participant: ${response.body}');
    }
  }

  /// Report a user in group chat
  Future<void> reportUser({
    required String conversationId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/report'),
      headers: _headers,
      body: jsonEncode({
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to report user: ${response.body}');
    }
  }

  /// Get messages for a conversation
  Future<List<GroupMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/group-chat/conversations/$conversationId/messages?limit=$limit&offset=$offset',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data['data'] as List;
      return messages.map((m) => GroupMessage.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/group-chat/conversations/$conversationId/messages/$messageId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  /// Add reaction to a message
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversations/$conversationId/messages/$messageId/reactions'),
      headers: _headers,
      body: jsonEncode({'emoji': emoji}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add reaction: ${response.body}');
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/group-chat/conversations/$conversationId/messages/$messageId/reactions/$emoji'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove reaction: ${response.body}');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversations/$conversationId/messages/$messageId/read'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark message as read: ${response.body}');
    }
  }

  /// Search messages in a conversation
  Future<List<GroupMessage>> searchMessages({
    required String conversationId,
    required String query,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/conversations/$conversationId/messages/search?q=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data['data'] as List;
      return messages.map((m) => GroupMessage.fromJson(m)).toList();
    } else {
      throw Exception('Failed to search messages: ${response.body}');
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
    final response = await http.patch(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/settings'),
      headers: _headers,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (allowParticipantInvite != null)
          'allowParticipantInvite': allowParticipantInvite,
        if (requireApproval != null) 'requireApproval': requireApproval,
        if (autoAcceptFriends != null) 'autoAcceptFriends': autoAcceptFriends,
        if (enableVoiceChat != null) 'enableVoiceChat': enableVoiceChat,
        if (enableVideoChat != null) 'enableVideoChat': enableVideoChat,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupConversation.fromJson(data['data']);
    } else {
      throw Exception('Failed to update group settings: ${response.body}');
    }
  }

  /// Change a participant's role in the group (owner only)
  Future<void> changeParticipantRole({
    required String conversationId,
    required String targetUserId,
    required ParticipantRole role,
    String? reason,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/group-chat/conversation/$conversationId/participants/$targetUserId/role',
      ),
      headers: _headers,
      body: jsonEncode({
        'role': role.name.toUpperCase(),
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to change participant role: ${response.body}');
    }
  }

  /// Leave a group conversation
  Future<void> leaveGroup({
    required String conversationId,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/leave'),
      headers: _headers,
      body: jsonEncode({
        if (message != null) 'message': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave group: ${response.body}');
    }
  }

  /// Delete a group conversation (owner only)
  Future<void> deleteGroup({
    required String conversationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/delete'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete group: ${response.body}');
    }
  }

  /// Upload group photo
  Future<String> uploadGroupPhoto({
    required String conversationId,
    required String imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/photo'),
    );

    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('photo', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['photoUrl'] as String;
    } else {
      throw Exception('Failed to upload group photo: ${response.body}');
    }
  }

  /// Remove group photo
  Future<void> removeGroupPhoto({
    required String conversationId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/photo'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove group photo: ${response.body}');
    }
  }

  /// Get blocked users in a conversation
  Future<List<BlockedUser>> getBlockedUsers({
    required String conversationId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/blocked-users'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = data['data'] as List;
      return users.map((u) => BlockedUser.fromJson(u)).toList();
    } else {
      throw Exception('Failed to get blocked users: ${response.body}');
    }
  }

  /// Block a user in a conversation
  Future<void> blockUser({
    required String conversationId,
    required String userId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/block-user'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to block user: ${response.body}');
    }
  }

  /// Unblock a user in a conversation
  Future<void> unblockUser({
    required String conversationId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/unblock-user'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unblock user: ${response.body}');
    }
  }

  /// Get reported content in a conversation
  Future<List<ReportedContent>> getReportedContent({
    required String conversationId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-chat/conversation/$conversationId/reports'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reports = data['data'] as List;
      return reports.map((r) => ReportedContent.fromJson(r)).toList();
    } else {
      throw Exception('Failed to get reported content: ${response.body}');
    }
  }
}

