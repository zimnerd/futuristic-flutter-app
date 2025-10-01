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
}
