/// Type of call being made
enum CallType {
  audio,
  video;

  String toJson() => name;
  
  static CallType fromJson(String value) {
    return CallType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallType.audio,
    );
  }
}

/// Status of a call invitation
enum CallInvitationStatus {
  pending,
  accepted,
  rejected,
  timeout,
  busy,
  cancelled;

  String toJson() => name;
  
  static CallInvitationStatus fromJson(String value) {
    return CallInvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallInvitationStatus.pending,
    );
  }
}

/// Reason for call rejection
enum CallRejectionReason {
  userDeclined,
  busy,
  timeout,
  networkError,
  userOffline;

  String toJson() => name;
  
  static CallRejectionReason fromJson(String value) {
    return CallRejectionReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallRejectionReason.userDeclined,
    );
  }
}

/// Represents a call invitation sent between users
class CallInvitation {
  /// Unique identifier for this call (UUID v4)
  final String callId;

  /// ID of the user initiating the call
  final String callerId;

  /// Name of the caller
  final String callerName;

  /// Profile photo URL of the caller
  final String? callerPhoto;

  /// ID of the user receiving the call
  final String recipientId;

  /// Type of call (audio or video)
  final CallType callType;

  /// Current status of the invitation
  final CallInvitationStatus status;

  /// Conversation/Channel ID for the call
  final String? conversationId;

  /// Group ID if this is a group call
  final String? groupId;

  /// Agora RTC token for the call
  final String? rtcToken;

  /// Channel name for Agora RTC
  final String? channelName;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Timestamp when invitation was created
  final DateTime createdAt;

  /// Timestamp when invitation expires (30 seconds default)
  final DateTime expiresAt;

  CallInvitation({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.recipientId,
    required this.callType,
    required this.status,
    this.conversationId,
    this.groupId,
    this.rtcToken,
    this.channelName,
    this.metadata,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Factory constructor from JSON
  factory CallInvitation.fromJson(Map<String, dynamic> json) {
    return CallInvitation(
      callId: json['callId'] as String,
      callerId: json['callerId'] as String,
      callerName: json['callerName'] as String,
      callerPhoto: json['callerPhoto'] as String?,
      recipientId: json['recipientId'] as String,
      callType: CallType.fromJson(json['callType'] as String),
      status: CallInvitationStatus.fromJson(json['status'] as String),
      conversationId: json['conversationId'] as String?,
      groupId: json['groupId'] as String?,
      rtcToken: json['rtcToken'] as String?,
      channelName: json['channelName'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'recipientId': recipientId,
      'callType': callType.toJson(),
      'status': status.toJson(),
      'conversationId': conversationId,
      'groupId': groupId,
      'rtcToken': rtcToken,
      'channelName': channelName,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Copy with new values
  CallInvitation copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerPhoto,
    String? recipientId,
    CallType? callType,
    CallInvitationStatus? status,
    String? conversationId,
    String? groupId,
    String? rtcToken,
    String? channelName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return CallInvitation(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhoto: callerPhoto ?? this.callerPhoto,
      recipientId: recipientId ?? this.recipientId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      groupId: groupId ?? this.groupId,
      rtcToken: rtcToken ?? this.rtcToken,
      channelName: channelName ?? this.channelName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if invitation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invitation is still pending
  bool get isPending => status == CallInvitationStatus.pending && !isExpired;

  /// Get display text for call type
  String get callTypeDisplay =>
      callType == CallType.video ? 'Video Call' : 'Voice Call';

  /// Get emoji for call type
  String get callTypeEmoji => callType == CallType.video ? '📹' : '🎤';
}

/// Represents the current state of the calling system
class CallState {
  /// Whether user is currently in an active call
  final bool isInCall;

  /// Current call invitation (if any)
  final CallInvitation? currentInvitation;

  /// Outgoing call invitation (if any)
  final CallInvitation? outgoingInvitation;

  /// Whether user is available for calls
  final bool isAvailable;

  /// List of missed calls
  final List<CallInvitation> missedCalls;

  const CallState({
    this.isInCall = false,
    this.currentInvitation,
    this.outgoingInvitation,
    this.isAvailable = true,
    this.missedCalls = const [],
  });

  /// Copy with new values
  CallState copyWith({
    bool? isInCall,
    CallInvitation? currentInvitation,
    CallInvitation? outgoingInvitation,
    bool? isAvailable,
    List<CallInvitation>? missedCalls,
  }) {
    return CallState(
      isInCall: isInCall ?? this.isInCall,
      currentInvitation: currentInvitation ?? this.currentInvitation,
      outgoingInvitation: outgoingInvitation ?? this.outgoingInvitation,
      isAvailable: isAvailable ?? this.isAvailable,
      missedCalls: missedCalls ?? this.missedCalls,
    );
  }

  /// Whether user can receive calls
  bool get canReceiveCalls => isAvailable && !isInCall;

  /// Number of missed calls
  int get missedCallCount => missedCalls.length;
}
