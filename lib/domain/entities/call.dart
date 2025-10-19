import 'package:equatable/equatable.dart';
import 'user_profile.dart';

/// Call entity representing a video/audio call
class Call extends Equatable {
  const Call({
    required this.id,
    required this.callerId,
    required this.recipientId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.callerProfile,
    this.recipientProfile,
    this.duration,
    this.quality,
    this.endReason,
    this.signalingData,
  });

  final String id;
  final String callerId;
  final String recipientId;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final UserProfile? callerProfile;
  final UserProfile? recipientProfile;
  final Duration? duration;
  final CallQuality? quality;
  final CallEndReason? endReason;
  final Map<String, dynamic>? signalingData;

  /// Get the other participant's profile
  UserProfile? getOtherParticipant(String currentUserId) {
    if (callerId == currentUserId) {
      return recipientProfile;
    } else {
      return callerProfile;
    }
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    if (callerId == currentUserId) {
      return recipientId;
    } else {
      return callerId;
    }
  }

  /// Check if current user is the caller
  bool isCaller(String currentUserId) {
    return callerId == currentUserId;
  }

  /// Get formatted duration
  String get formattedDuration {
    if (duration == null) return '00:00';

    final hours = duration!.inHours;
    final minutes = duration!.inMinutes % 60;
    final seconds = duration!.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Check if call is active
  bool get isActive => [
    CallStatus.outgoing,
    CallStatus.incoming,
    CallStatus.connecting,
    CallStatus.connected,
  ].contains(status);

  /// Check if call has ended
  bool get hasEnded => [
    CallStatus.ended,
    CallStatus.failed,
    CallStatus.declined,
  ].contains(status);

  @override
  List<Object?> get props => [
    id,
    callerId,
    recipientId,
    type,
    status,
    createdAt,
    startedAt,
    endedAt,
    callerProfile,
    recipientProfile,
    duration,
    quality,
    endReason,
    signalingData,
  ];

  Call copyWith({
    String? id,
    String? callerId,
    String? recipientId,
    CallType? type,
    CallStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    UserProfile? callerProfile,
    UserProfile? recipientProfile,
    Duration? duration,
    CallQuality? quality,
    CallEndReason? endReason,
    Map<String, dynamic>? signalingData,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      callerProfile: callerProfile ?? this.callerProfile,
      recipientProfile: recipientProfile ?? this.recipientProfile,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      endReason: endReason ?? this.endReason,
      signalingData: signalingData ?? this.signalingData,
    );
  }

  /// Create Call from JSON
  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      recipientId: json['recipientId'] as String,
      type: CallType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CallType.video,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CallStatus.idle,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      callerProfile: json['callerProfile'] != null
          ? UserProfile.fromJson(json['callerProfile'] as Map<String, dynamic>)
          : null,
      recipientProfile: json['recipientProfile'] != null
          ? UserProfile.fromJson(
              json['recipientProfile'] as Map<String, dynamic>,
            )
          : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      quality: json['quality'] != null
          ? CallQuality.values.firstWhere(
              (e) => e.name == json['quality'],
              orElse: () => CallQuality.good,
            )
          : null,
      endReason: json['endReason'] != null
          ? CallEndReason.values.firstWhere(
              (e) => e.name == json['endReason'],
              orElse: () => CallEndReason.normal,
            )
          : null,
      signalingData: json['signalingData'] as Map<String, dynamic>?,
    );
  }

  /// Convert Call to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'recipientId': recipientId,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'callerProfile': callerProfile?.toJson(),
      'recipientProfile': recipientProfile?.toJson(),
      'duration': duration?.inSeconds,
      'quality': quality?.name,
      'endReason': endReason?.name,
      'signalingData': signalingData,
    };
  }
}

/// Enum for call types
enum CallType { video, audio }

/// Enum for call status
enum CallStatus {
  idle,
  outgoing,
  incoming,
  connecting,
  connected,
  ended,
  failed,
  declined,
}

/// Enum for call quality levels
enum CallQuality { poor, fair, good, excellent }

/// Enum for call connection states
enum CallConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Enum for call end reasons
enum CallEndReason {
  normal,
  declined,
  timeout,
  networkError,
  busy,
  cancelled,
  deviceError,
}
