import 'package:equatable/equatable.dart';

/// Base state for live streaming feature
abstract class LiveStreamingState extends Equatable {
  const LiveStreamingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LiveStreamingInitial extends LiveStreamingState {
  const LiveStreamingInitial();
}

/// Loading state
class LiveStreamingLoading extends LiveStreamingState {
  const LiveStreamingLoading();
}

/// Live streams loaded successfully
class LiveStreamsLoaded extends LiveStreamingState {
  final List<Map<String, dynamic>> streams;
  final bool hasMoreStreams;
  final int currentPage;

  const LiveStreamsLoaded({
    required this.streams,
    this.hasMoreStreams = false,
    this.currentPage = 1,
  });

  LiveStreamsLoaded copyWith({
    List<Map<String, dynamic>>? streams,
    bool? hasMoreStreams,
    int? currentPage,
  }) {
    return LiveStreamsLoaded(
      streams: streams ?? this.streams,
      hasMoreStreams: hasMoreStreams ?? this.hasMoreStreams,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [streams, hasMoreStreams, currentPage];
}

/// Live stream started successfully
class LiveStreamStarted extends LiveStreamingState {
  final Map<String, dynamic> streamInfo;

  const LiveStreamStarted(this.streamInfo);

  @override
  List<Object> get props => [streamInfo];
}

/// Joined live stream successfully
class LiveStreamJoined extends LiveStreamingState {
  final Map<String, dynamic> streamInfo;
  final List<Map<String, dynamic>> viewers;

  const LiveStreamJoined({
    required this.streamInfo,
    this.viewers = const [],
  });

  @override
  List<Object> get props => [streamInfo, viewers];
}

/// Left live stream
class LiveStreamLeft extends LiveStreamingState {
  final String streamId;

  const LiveStreamLeft(this.streamId);

  @override
  List<Object> get props => [streamId];
}

/// Live stream ended
class LiveStreamEnded extends LiveStreamingState {
  final String streamId;
  final Map<String, dynamic>? analytics;

  const LiveStreamEnded({
    required this.streamId,
    this.analytics,
  });

  @override
  List<Object?> get props => [streamId, analytics];
}

/// Stream message sent successfully
class StreamMessageSent extends LiveStreamingState {
  final String streamId;
  final String message;

  const StreamMessageSent({
    required this.streamId,
    required this.message,
  });

  @override
  List<Object> get props => [streamId, message];
}

/// Stream gift sent successfully
class StreamGiftSent extends LiveStreamingState {
  final String streamId;
  final String giftId;
  final int quantity;

  const StreamGiftSent({
    required this.streamId,
    required this.giftId,
    required this.quantity,
  });

  @override
  List<Object> get props => [streamId, giftId, quantity];
}

/// Streamer follow status updated
class StreamerFollowUpdated extends LiveStreamingState {
  final String streamerId;
  final bool isFollowing;

  const StreamerFollowUpdated({
    required this.streamerId,
    required this.isFollowing,
  });

  @override
  List<Object> get props => [streamerId, isFollowing];
}

/// Stream analytics loaded
class StreamAnalyticsLoaded extends LiveStreamingState {
  final String streamId;
  final Map<String, dynamic> analytics;

  const StreamAnalyticsLoaded({
    required this.streamId,
    required this.analytics,
  });

  @override
  List<Object> get props => [streamId, analytics];
}

/// Stream settings updated
class StreamSettingsUpdated extends LiveStreamingState {
  final String streamId;
  final Map<String, dynamic> settings;

  const StreamSettingsUpdated({
    required this.streamId,
    required this.settings,
  });

  @override
  List<Object> get props => [streamId, settings];
}

/// Followed streamers loaded
class FollowedStreamersLoaded extends LiveStreamingState {
  final List<Map<String, dynamic>> streamers;

  const FollowedStreamersLoaded(this.streamers);

  @override
  List<Object> get props => [streamers];
}

/// Streaming history loaded
class StreamingHistoryLoaded extends LiveStreamingState {
  final List<Map<String, dynamic>> history;
  final bool hasMoreHistory;
  final int currentPage;

  const StreamingHistoryLoaded({
    required this.history,
    this.hasMoreHistory = false,
    this.currentPage = 1,
  });

  StreamingHistoryLoaded copyWith({
    List<Map<String, dynamic>>? history,
    bool? hasMoreHistory,
    int? currentPage,
  }) {
    return StreamingHistoryLoaded(
      history: history ?? this.history,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [history, hasMoreHistory, currentPage];
}

/// Error state
class LiveStreamingError extends LiveStreamingState {
  final String message;

  const LiveStreamingError(this.message);

  @override
  List<Object> get props => [message];
}
