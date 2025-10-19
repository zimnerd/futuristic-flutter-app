import 'package:equatable/equatable.dart';

/// Base event for live streaming feature
abstract class LiveStreamingEvent extends Equatable {
  const LiveStreamingEvent();

  @override
  List<Object?> get props => [];
}

/// Load live streams list
class LoadLiveStreams extends LiveStreamingEvent {
  final String? category;
  final int page;
  final int limit;

  const LoadLiveStreams({this.category, this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [category, page, limit];
}

/// Search live streams
class SearchStreams extends LiveStreamingEvent {
  final String query;
  final String? category;
  final int page;
  final int limit;

  const SearchStreams({
    required this.query,
    this.category,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [query, category, page, limit];
}

/// Update stream viewer count (real-time)
class UpdateStreamViewers extends LiveStreamingEvent {
  final String streamId;
  final int viewerCount;

  const UpdateStreamViewers({
    required this.streamId,
    required this.viewerCount,
  });

  @override
  List<Object> get props => [streamId, viewerCount];
}

/// Start a new live stream
class StartLiveStream extends LiveStreamingEvent {
  final String title;
  final String description;
  final String? category;
  final Map<String, dynamic>? settings;

  const StartLiveStream({
    required this.title,
    required this.description,
    this.category,
    this.settings,
  });

  @override
  List<Object?> get props => [title, description, category, settings];
}

/// Join a live stream
class JoinLiveStream extends LiveStreamingEvent {
  final String streamId;

  const JoinLiveStream(this.streamId);

  @override
  List<Object> get props => [streamId];
}

/// Leave a live stream
class LeaveLiveStream extends LiveStreamingEvent {
  final String streamId;

  const LeaveLiveStream(this.streamId);

  @override
  List<Object> get props => [streamId];
}

/// End live stream (for streamers)
class EndLiveStream extends LiveStreamingEvent {
  final String streamId;

  const EndLiveStream(this.streamId);

  @override
  List<Object> get props => [streamId];
}

/// Send message in live stream chat
class SendStreamMessage extends LiveStreamingEvent {
  final String streamId;
  final String message;

  const SendStreamMessage({required this.streamId, required this.message});

  @override
  List<Object> get props => [streamId, message];
}

/// Send gift to streamer
class SendStreamGift extends LiveStreamingEvent {
  final String streamId;
  final String giftId;
  final int quantity;

  const SendStreamGift({
    required this.streamId,
    required this.giftId,
    this.quantity = 1,
  });

  @override
  List<Object> get props => [streamId, giftId, quantity];
}

/// Follow/unfollow a streamer
class ToggleFollowStreamer extends LiveStreamingEvent {
  final String streamerId;
  final bool isFollowing;

  const ToggleFollowStreamer({
    required this.streamerId,
    required this.isFollowing,
  });

  @override
  List<Object> get props => [streamerId, isFollowing];
}

/// Get stream analytics (for streamers)
class GetStreamAnalytics extends LiveStreamingEvent {
  final String streamId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetStreamAnalytics({
    required this.streamId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [streamId, startDate, endDate];
}

/// Update stream settings
class UpdateStreamSettings extends LiveStreamingEvent {
  final String streamId;
  final Map<String, dynamic> settings;

  const UpdateStreamSettings({required this.streamId, required this.settings});

  @override
  List<Object> get props => [streamId, settings];
}

/// Load followed streamers
class LoadFollowedStreamers extends LiveStreamingEvent {
  const LoadFollowedStreamers();
}

/// Load streaming history
class LoadStreamingHistory extends LiveStreamingEvent {
  final int page;
  final int limit;

  const LoadStreamingHistory({this.page = 1, this.limit = 20});

  @override
  List<Object> get props => [page, limit];
}

/// Schedule a future live stream
class ScheduleLiveStream extends LiveStreamingEvent {
  final String title;
  final String? description;
  final DateTime scheduledStartTime;
  final String type;
  final int maxViewers;
  final String? thumbnailUrl;
  final List<String>? tags;
  final bool isAdultsOnly;

  const ScheduleLiveStream({
    required this.title,
    this.description,
    required this.scheduledStartTime,
    required this.type,
    this.maxViewers = 100,
    this.thumbnailUrl,
    this.tags,
    this.isAdultsOnly = false,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    scheduledStartTime,
    type,
    maxViewers,
    thumbnailUrl,
    tags,
    isAdultsOnly,
  ];
}

/// Load scheduled streams
class LoadScheduledStreams extends LiveStreamingEvent {
  const LoadScheduledStreams();
}

/// Load my scheduled streams
class LoadMyScheduledStreams extends LiveStreamingEvent {
  const LoadMyScheduledStreams();
}

/// Cancel a scheduled stream
class CancelScheduledStream extends LiveStreamingEvent {
  final String streamId;

  const CancelScheduledStream(this.streamId);

  @override
  List<Object> get props => [streamId];
}

/// Update a scheduled stream
class UpdateScheduledStream extends LiveStreamingEvent {
  final String streamId;
  final String? title;
  final String? description;
  final DateTime? scheduledStartTime;
  final String? type;
  final int? maxViewers;
  final String? thumbnailUrl;
  final List<String>? tags;
  final bool? isAdultsOnly;

  const UpdateScheduledStream({
    required this.streamId,
    this.title,
    this.description,
    this.scheduledStartTime,
    this.type,
    this.maxViewers,
    this.thumbnailUrl,
    this.tags,
    this.isAdultsOnly,
  });

  @override
  List<Object?> get props => [
    streamId,
    title,
    description,
    scheduledStartTime,
    type,
    maxViewers,
    thumbnailUrl,
    tags,
    isAdultsOnly,
  ];
}
