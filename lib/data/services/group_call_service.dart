import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service_impl.dart';
import '../../core/constants/api_constants.dart';

/// Service for managing group video calls and participants
class GroupCallService {
  static GroupCallService? _instance;
  static GroupCallService get instance => _instance ??= GroupCallService._();

  GroupCallService._();

  final ApiServiceImpl _apiService = ApiServiceImpl();

  // Stream controllers for group call events
  final StreamController<List<CallParticipant>> _participantsController =
      StreamController.broadcast();
  final StreamController<GroupCallSettings> _settingsController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _moderationController =
      StreamController.broadcast();

  // Public streams
  Stream<List<CallParticipant>> get onParticipantsChanged =>
      _participantsController.stream;
  Stream<GroupCallSettings> get onSettingsChanged => _settingsController.stream;
  Stream<Map<String, dynamic>> get onModerationEvent =>
      _moderationController.stream;

  /// Update group call settings
  Future<bool> updateGroupCallSettings({
    required String callId,
    required GroupCallSettings settings,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.webrtc}/calls/$callId/group-settings',
        data: settings.toJson(),
      );

      if (response.data['success'] == true) {
        _settingsController.add(settings);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating group call settings: $e');
      return false;
    }
  }

  /// Add participant to group call
  Future<bool> addParticipant({
    required String callId,
    required String userId,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.webrtc}/calls/$callId/participants/$userId',
        data: {},
      );

      if (response.data['success'] == true) {
        // Refresh participants list
        await getCallParticipants(callId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error adding participant: $e');
      return false;
    }
  }

  /// Remove participant from group call
  Future<bool> removeParticipant({
    required String callId,
    required String userId,
  }) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.webrtc}/calls/$callId/participants/$userId',
      );

      if (response.data['success'] == true) {
        // Refresh participants list
        await getCallParticipants(callId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error removing participant: $e');
      return false;
    }
  }

  /// Update participant role (HOST, MODERATOR, PARTICIPANT)
  Future<bool> updateParticipantRole({
    required String callId,
    required String userId,
    required String role,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.webrtc}/calls/$callId/participants/$userId/role',
        data: {'role': role},
      );

      if (response.data['success'] == true) {
        // Refresh participants list
        await getCallParticipants(callId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating participant role: $e');
      return false;
    }
  }

  /// Bulk invite participants to group call
  Future<List<String>> bulkInviteParticipants({
    required String callId,
    required List<String> userIds,
    String? inviteMessage,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.webrtc}/calls/$callId/bulk-invite',
        data: {
          'userIds': userIds,
          'inviteMessage': inviteMessage ?? 'Join our group video call!',
        },
      );

      if (response.data['success'] == true) {
        final results = response.data['data']['results'] as List;
        final successfulInvites = results
            .where((r) => r['success'] == true)
            .map((r) => r['userId'] as String)
            .toList();

        // Refresh participants list
        await getCallParticipants(callId);
        return successfulInvites;
      }

      return [];
    } catch (e) {
      debugPrint('Error bulk inviting participants: $e');
      return [];
    }
  }

  /// Apply moderation actions (mute all, kick participant, etc.)
  Future<bool> applyModerationAction({
    required String callId,
    required GroupModerationAction action,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.webrtc}/calls/$callId/moderation',
        data: action.toJson(),
      );

      if (response.data['success'] == true) {
        _moderationController.add({
          'action': action.action,
          'targetUserId': action.targetUserId,
          'data': response.data['data'],
        });
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error applying moderation action: $e');
      return false;
    }
  }

  /// End group call
  Future<bool> endCall(String callId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.webrtc}/calls/$callId',
      );

      if (response.data['success'] == true) {
        // Notify all listeners that call ended
        _moderationController.add({
          'action': 'CALL_ENDED',
          'callId': callId,
          'data': response.data['data'],
        });
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error ending call: $e');
      return false;
    }
  }

  /// Get call participants list
  Future<List<CallParticipant>> getCallParticipants(String callId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.webrtc}/calls/$callId/participants',
      );

      if (response.data['success'] == true) {
        final List<dynamic> participantsData = response.data['data'] ?? [];
        final participants = participantsData
            .map((p) => CallParticipant.fromJson(p))
            .toList();

        _participantsController.add(participants);
        return participants;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting call participants: $e');
      return [];
    }
  }

  /// Get group call analytics
  Future<GroupCallAnalytics?> getCallAnalytics(String callId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.webrtc}/calls/$callId/analytics',
      );

      if (response.data['success'] == true) {
        return GroupCallAnalytics.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting call analytics: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _participantsController.close();
    _settingsController.close();
    _moderationController.close();
  }
}

/// Group Call Settings model
class GroupCallSettings {
  final int maxParticipants;
  final bool requireApproval;
  final bool allowScreenShare;
  final bool recordingEnabled;
  final String joinMode;
  final Map<String, dynamic> moderationSettings;

  GroupCallSettings({
    this.maxParticipants = 4,
    this.requireApproval = false,
    this.allowScreenShare = true,
    this.recordingEnabled = false,
    this.joinMode = 'OPEN',
    this.moderationSettings = const {},
  });

  factory GroupCallSettings.fromJson(Map<String, dynamic> json) {
    return GroupCallSettings(
      maxParticipants: json['maxParticipants'] ?? 4,
      requireApproval: json['requireApproval'] ?? false,
      allowScreenShare: json['allowScreenShare'] ?? true,
      recordingEnabled: json['recordingEnabled'] ?? false,
      joinMode: json['joinMode'] ?? 'OPEN',
      moderationSettings: Map<String, dynamic>.from(
        json['moderationSettings'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxParticipants': maxParticipants,
      'requireApproval': requireApproval,
      'allowScreenShare': allowScreenShare,
      'recordingEnabled': recordingEnabled,
      'joinMode': joinMode,
      'moderationSettings': moderationSettings,
    };
  }
}

/// Call Participant model
class CallParticipant {
  final String id;
  final String userId;
  final String role;
  final String status;
  final String connectionStatus;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final DateTime? joinedAt;
  final String? displayName;
  final String? avatarUrl;

  CallParticipant({
    required this.id,
    required this.userId,
    required this.role,
    required this.status,
    required this.connectionStatus,
    this.isMuted = false,
    this.isVideoEnabled = true,
    this.isScreenSharing = false,
    this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'PARTICIPANT',
      status: json['status'] ?? 'INVITED',
      connectionStatus: json['connectionStatus'] ?? 'CONNECTING',
      isMuted: json['isMuted'] ?? false,
      isVideoEnabled: json['isVideoEnabled'] ?? true,
      isScreenSharing: json['isScreenSharing'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : null,
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'role': role,
      'status': status,
      'connectionStatus': connectionStatus,
      'isMuted': isMuted,
      'isVideoEnabled': isVideoEnabled,
      'isScreenSharing': isScreenSharing,
      'joinedAt': joinedAt?.toIso8601String(),
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}

/// Group Moderation Action model
class GroupModerationAction {
  final String action;
  final String? targetUserId;
  final Map<String, dynamic> settings;

  GroupModerationAction({
    required this.action,
    this.targetUserId,
    this.settings = const {},
  });

  factory GroupModerationAction.muteAll() {
    return GroupModerationAction(action: 'MUTE_ALL');
  }

  factory GroupModerationAction.kickParticipant(String userId) {
    return GroupModerationAction(action: 'KICK', targetUserId: userId);
  }

  factory GroupModerationAction.lockCall() {
    return GroupModerationAction(action: 'LOCK_CALL');
  }

  factory GroupModerationAction.enableWaitingRoom() {
    return GroupModerationAction(action: 'ENABLE_WAITING_ROOM');
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'targetUserId': targetUserId,
      'settings': settings,
    };
  }
}

/// Group Call Analytics model
class GroupCallAnalytics {
  final String callId;
  final int totalParticipants;
  final int activeParticipants;
  final int averageDuration;
  final String callStatus;
  final bool isGroup;
  final List<ParticipantStats> participantStats;
  final DateTime generatedAt;

  GroupCallAnalytics({
    required this.callId,
    required this.totalParticipants,
    required this.activeParticipants,
    required this.averageDuration,
    required this.callStatus,
    required this.isGroup,
    required this.participantStats,
    required this.generatedAt,
  });

  factory GroupCallAnalytics.fromJson(Map<String, dynamic> json) {
    return GroupCallAnalytics(
      callId: json['callId'] ?? '',
      totalParticipants: json['totalParticipants'] ?? 0,
      activeParticipants: json['activeParticipants'] ?? 0,
      averageDuration: json['averageDuration'] ?? 0,
      callStatus: json['callStatus'] ?? 'UNKNOWN',
      isGroup: json['isGroup'] ?? false,
      participantStats: (json['participantStats'] as List? ?? [])
          .map((p) => ParticipantStats.fromJson(p))
          .toList(),
      generatedAt: DateTime.parse(
        json['generatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// Participant Statistics model
class ParticipantStats {
  final String userId;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int? duration;

  ParticipantStats({
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    this.leftAt,
    this.duration,
  });

  factory ParticipantStats.fromJson(Map<String, dynamic> json) {
    return ParticipantStats(
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'PARTICIPANT',
      status: json['status'] ?? 'UNKNOWN',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : null,
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
      duration: json['duration'],
    );
  }
}
