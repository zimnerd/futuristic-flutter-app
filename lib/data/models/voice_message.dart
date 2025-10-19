import 'package:equatable/equatable.dart';

/// Represents a voice message in a conversation
class VoiceMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String audioUrl;
  final int duration; // in seconds
  final List<double> waveformData;
  final bool isPlayed;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatarUrl;

  const VoiceMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.audioUrl,
    required this.duration,
    required this.waveformData,
    this.isPlayed = false,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    return VoiceMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      audioUrl: json['audioUrl'] as String,
      duration: json['duration'] as int,
      waveformData: (json['waveformData'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      isPlayed: json['isPlayed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'audioUrl': audioUrl,
      'duration': duration,
      'waveformData': waveformData,
      'isPlayed': isPlayed,
      'createdAt': createdAt.toIso8601String(),
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
    };
  }

  VoiceMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? audioUrl,
    int? duration,
    List<double>? waveformData,
    bool? isPlayed,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      waveformData: waveformData ?? this.waveformData,
      isPlayed: isPlayed ?? this.isPlayed,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    audioUrl,
    duration,
    waveformData,
    isPlayed,
    createdAt,
    senderName,
    senderAvatarUrl,
  ];
}

/// Represents the recording state for voice messages
enum VoiceRecordingState { idle, recording, paused, finished }

/// Represents the playback state for voice messages
enum VoicePlaybackState { stopped, playing, paused, loading }

/// Voice message recording session
class VoiceRecordingSession extends Equatable {
  final String sessionId;
  final VoiceRecordingState state;
  final int duration; // in seconds
  final List<double> waveformData;
  final String? filePath;

  const VoiceRecordingSession({
    required this.sessionId,
    required this.state,
    this.duration = 0,
    this.waveformData = const [],
    this.filePath,
  });

  VoiceRecordingSession copyWith({
    String? sessionId,
    VoiceRecordingState? state,
    int? duration,
    List<double>? waveformData,
    String? filePath,
  }) {
    return VoiceRecordingSession(
      sessionId: sessionId ?? this.sessionId,
      state: state ?? this.state,
      duration: duration ?? this.duration,
      waveformData: waveformData ?? this.waveformData,
      filePath: filePath ?? this.filePath,
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    state,
    duration,
    waveformData,
    filePath,
  ];
}
