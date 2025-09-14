import 'package:equatable/equatable.dart';

/// Model representing a video/audio call
class CallModel extends Equatable {
  const CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.type,
    required this.status,
    this.channelName,
    this.token,
    this.startedAt,
    this.endedAt,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallType type;
  final CallStatus status;
  final String? channelName;
  final String? token;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration; // Duration in seconds
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'],
      callerId: json['callerId'],
      callerName: json['callerName'],
      callerAvatar: json['callerAvatar'],
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      receiverAvatar: json['receiverAvatar'],
      type: CallType.values.byName(json['type']),
      status: CallStatus.values.byName(json['status']),
      channelName: json['channelName'],
      token: json['token'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'])
          : null,
      duration: json['duration'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'type': type.name,
      'status': status.name,
      'channelName': channelName,
      'token': token,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    CallType? type,
    CallStatus? status,
    String? channelName,
    String? token,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      type: type ?? this.type,
      status: status ?? this.status,
      channelName: channelName ?? this.channelName,
      token: token ?? this.token,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        callerId,
        callerName,
        callerAvatar,
        receiverId,
        receiverName,
        receiverAvatar,
        type,
        status,
        channelName,
        token,
        startedAt,
        endedAt,
        duration,
        createdAt,
        updatedAt,
      ];
}

/// Enum representing call types
enum CallType { audio, video }

/// Enum representing call status
enum CallStatus { 
  initiating, 
  ringing, 
  connected, 
  ended, 
  declined, 
  missed, 
  failed 
}

/// Model for call signaling data
class CallSignalModel extends Equatable {
  const CallSignalModel({
    required this.callId,
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    this.data,
  });

  final String callId;
  final CallSignalType type;
  final String fromUserId;
  final String toUserId;
  final Map<String, dynamic>? data;

  factory CallSignalModel.fromJson(Map<String, dynamic> json) {
    return CallSignalModel(
      callId: json['callId'],
      type: CallSignalType.values.byName(json['type']),
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'type': type.name,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [callId, type, fromUserId, toUserId, data];
}

/// Enum for call signaling types
enum CallSignalType {
  offer,
  answer,
  iceCandidate,
  hangup,
  reject,
  accept,
  mute,
  unmute,
  cameraOn,
  cameraOff,
}