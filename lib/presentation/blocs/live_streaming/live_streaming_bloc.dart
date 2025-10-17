import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/services/live_streaming_service.dart';
import 'live_streaming_event.dart';
import 'live_streaming_state.dart';

/// BLoC for managing live streaming feature
class LiveStreamingBloc extends Bloc<LiveStreamingEvent, LiveStreamingState> {
  final LiveStreamingService _liveStreamingService;
  final Logger _logger = Logger();
  static const String _tag = 'LiveStreamingBloc';

  LiveStreamingBloc(this._liveStreamingService) : super(const LiveStreamingInitial()) {
    on<LoadLiveStreams>(_onLoadLiveStreams);
    on<SearchStreams>(_onSearchStreams);
    on<UpdateStreamViewers>(_onUpdateStreamViewers);
    on<StartLiveStream>(_onStartLiveStream);
    on<JoinLiveStream>(_onJoinLiveStream);
    on<LeaveLiveStream>(_onLeaveLiveStream);
    on<EndLiveStream>(_onEndLiveStream);
    on<SendStreamMessage>(_onSendStreamMessage);
    on<SendStreamGift>(_onSendStreamGift);
    on<ToggleFollowStreamer>(_onToggleFollowStreamer);
    on<GetStreamAnalytics>(_onGetStreamAnalytics);
    on<UpdateStreamSettings>(_onUpdateStreamSettings);
    on<LoadFollowedStreamers>(_onLoadFollowedStreamers);
    on<LoadStreamingHistory>(_onLoadStreamingHistory);
    on<ScheduleLiveStream>(_onScheduleLiveStream);
    on<LoadScheduledStreams>(_onLoadScheduledStreams);
    on<LoadMyScheduledStreams>(_onLoadMyScheduledStreams);
    on<CancelScheduledStream>(_onCancelScheduledStream);
    on<UpdateScheduledStream>(_onUpdateScheduledStream);
  }

  Future<void> _onLoadLiveStreams(
    LoadLiveStreams event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(const LiveStreamingLoading());
      }
      
      _logger.d('$_tag: Loading live streams (page: ${event.page}, limit: ${event.limit})');

      final streams = await _liveStreamingService.getActiveStreams(
        category: event.category,
        page: event.page,
        limit: event.limit,
      );

      final hasMoreStreams = streams.length == event.limit;

      if (state is LiveStreamsLoaded && event.page > 1) {
        final currentState = state as LiveStreamsLoaded;
        final allStreams = [...currentState.streams, ...streams];
        emit(LiveStreamsLoaded(
          streams: allStreams,
          hasMoreStreams: hasMoreStreams,
          currentPage: event.page,
        ));
      } else {
        emit(LiveStreamsLoaded(
          streams: streams,
          hasMoreStreams: hasMoreStreams,
          currentPage: event.page,
        ));
      }

      _logger.d('$_tag: Loaded ${streams.length} live streams');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load live streams', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to load live streams: ${e.toString()}'));
    }
  }

  Future<void> _onSearchStreams(
    SearchStreams event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(const LiveStreamingLoading());
      }

      _logger.d(
        '$_tag: Searching streams with query: "${event.query}" (page: ${event.page}, limit: ${event.limit})',
      );

      final streams = await _liveStreamingService.searchStreams(
        query: event.query,
        category: event.category,
        page: event.page,
        limit: event.limit,
      );

      final hasMoreStreams = streams.length == event.limit;

      if (state is LiveStreamsLoaded && event.page > 1) {
        final currentState = state as LiveStreamsLoaded;
        final allStreams = [...currentState.streams, ...streams];
        emit(
          LiveStreamsLoaded(
            streams: allStreams,
            hasMoreStreams: hasMoreStreams,
            currentPage: event.page,
          ),
        );
      } else {
        emit(
          LiveStreamsLoaded(
            streams: streams,
            hasMoreStreams: hasMoreStreams,
            currentPage: event.page,
          ),
        );
      }

      _logger.d('$_tag: Found ${streams.length} streams matching query');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to search streams',
        error: e,
        stackTrace: stackTrace,
      );
      emit(LiveStreamingError('Failed to search streams: ${e.toString()}'));
    }
  }

  void _onUpdateStreamViewers(
    UpdateStreamViewers event,
    Emitter<LiveStreamingState> emit,
  ) {
    try {
      // Only update if we have streams loaded
      if (state is LiveStreamsLoaded) {
        final currentState = state as LiveStreamsLoaded;

        // Find and update the stream with matching ID
        final updatedStreams = currentState.streams.map((stream) {
          if (stream['id'] == event.streamId ||
              stream['streamId'] == event.streamId) {
            return {
              ...stream,
              'viewerCount': event.viewerCount,
              'currentViewers': event.viewerCount,
            };
          }
          return stream;
        }).toList();

        // Emit updated state
        emit(
          LiveStreamsLoaded(
            streams: updatedStreams,
            hasMoreStreams: currentState.hasMoreStreams,
            currentPage: currentState.currentPage,
          ),
        );

        _logger.d(
          '$_tag: Updated viewer count for stream ${event.streamId}: ${event.viewerCount}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to update stream viewers',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onStartLiveStream(
    StartLiveStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Starting live stream: ${event.title}');

      final streamInfo = await _liveStreamingService.startLiveStream(
        title: event.title,
        description: event.description,
        tags: event.category != null ? [event.category!] : null,
        streamSettings: event.settings,
      );

      if (streamInfo != null) {
        emit(LiveStreamStarted(streamInfo));
        _logger.d('$_tag: Live stream started successfully');
      } else {
        emit(const LiveStreamingError('Failed to start live stream'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to start live stream', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to start live stream: ${e.toString()}'));
    }
  }

  Future<void> _onJoinLiveStream(
    JoinLiveStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Joining live stream: ${event.streamId}');

      final result = await _liveStreamingService.joinStream(event.streamId);

      if (result != null) {
        emit(LiveStreamJoined(
          streamInfo: result['streamInfo'] ?? {},
          viewers: (result['viewers'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [],
        ));
        _logger.d('$_tag: Joined live stream successfully');
      } else {
        emit(const LiveStreamingError('Failed to join live stream'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to join live stream', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to join live stream: ${e.toString()}'));
    }
  }

  Future<void> _onLeaveLiveStream(
    LeaveLiveStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      _logger.d('$_tag: Leaving live stream: ${event.streamId}');

      final success = await _liveStreamingService.leaveStream(event.streamId);

      if (success) {
        emit(LiveStreamLeft(event.streamId));
        _logger.d('$_tag: Left live stream successfully');
      } else {
        emit(const LiveStreamingError('Failed to leave live stream'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to leave live stream', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to leave live stream: ${e.toString()}'));
    }
  }

  Future<void> _onEndLiveStream(
    EndLiveStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Ending live stream: ${event.streamId}');

      final success = await _liveStreamingService.endLiveStream(event.streamId);

      emit(LiveStreamEnded(
        streamId: event.streamId,
        analytics: success ? {} : null, // Service returns bool, not analytics
      ));
      _logger.d('$_tag: Live stream ended successfully');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to end live stream', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to end live stream: ${e.toString()}'));
    }
  }

  Future<void> _onSendStreamMessage(
    SendStreamMessage event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      _logger.d('$_tag: Sending message in stream: ${event.streamId}');

      final success = await _liveStreamingService.sendChatMessage(
        streamId: event.streamId,
        message: event.message,
      );

      if (success) {
        emit(StreamMessageSent(
          streamId: event.streamId,
          message: event.message,
        ));
        _logger.d('$_tag: Stream message sent successfully');
      } else {
        emit(const LiveStreamingError('Failed to send message'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to send stream message', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> _onSendStreamGift(
    SendStreamGift event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      _logger.d('$_tag: Sending gift in stream: ${event.streamId}');

      final success = await _liveStreamingService.sendGiftToStreamer(
        streamId: event.streamId,
        giftId: event.giftId,
      );

      if (success) {
        emit(StreamGiftSent(
          streamId: event.streamId,
          giftId: event.giftId,
          quantity: event.quantity,
        ));
        _logger.d('$_tag: Stream gift sent successfully');
      } else {
        emit(const LiveStreamingError('Failed to send gift'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to send stream gift', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to send gift: ${e.toString()}'));
    }
  }

  Future<void> _onToggleFollowStreamer(
    ToggleFollowStreamer event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      _logger.d('$_tag: ${event.isFollowing ? 'Following' : 'Unfollowing'} streamer: ${event.streamerId}');

      // Note: Service doesn't have follow/unfollow methods
      // This would typically be handled by a separate follow/user service
      emit(LiveStreamingError('Follow/unfollow not implemented in streaming service'));
      return;
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to update follow status', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to update follow status: ${e.toString()}'));
    }
  }

  Future<void> _onGetStreamAnalytics(
    GetStreamAnalytics event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Getting analytics for stream: ${event.streamId}');

      final analytics = await _liveStreamingService.getStreamAnalytics(event.streamId);

      if (analytics != null) {
        emit(StreamAnalyticsLoaded(
          streamId: event.streamId,
          analytics: analytics,
        ));
        _logger.d('$_tag: Stream analytics loaded successfully');
      } else {
        emit(const LiveStreamingError('Failed to load stream analytics'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load stream analytics', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to load analytics: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStreamSettings(
    UpdateStreamSettings event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      _logger.d('$_tag: Updating settings for stream: ${event.streamId}');

      // Note: Service doesn't have updateStreamSettings method
      // This would need to be implemented in the backend first
      emit(LiveStreamingError('Stream settings update not implemented in service'));
      return;
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to update stream settings', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to update settings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadFollowedStreamers(
    LoadFollowedStreamers event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Loading followed streamers');

      // Note: Service doesn't have getFollowedStreamers method
      // Using empty list as placeholder
      final streamers = <Map<String, dynamic>>[];

      emit(FollowedStreamersLoaded(streamers));
      _logger.d('$_tag: Loaded ${streamers.length} followed streamers');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load followed streamers', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to load followed streamers: ${e.toString()}'));
    }
  }

  Future<void> _onLoadStreamingHistory(
    LoadStreamingHistory event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(const LiveStreamingLoading());
      }
      
      _logger.d('$_tag: Loading streaming history (page: ${event.page})');

      final history = await _liveStreamingService.getStreamingHistory(
        page: event.page,
        limit: event.limit,
      );

      final hasMoreHistory = history.length == event.limit;

      if (state is StreamingHistoryLoaded && event.page > 1) {
        final currentState = state as StreamingHistoryLoaded;
        final allHistory = [...currentState.history, ...history];
        emit(StreamingHistoryLoaded(
          history: allHistory,
          hasMoreHistory: hasMoreHistory,
          currentPage: event.page,
        ));
      } else {
        emit(StreamingHistoryLoaded(
          history: history,
          hasMoreHistory: hasMoreHistory,
          currentPage: event.page,
        ));
      }

      _logger.d('$_tag: Loaded ${history.length} streaming history items');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load streaming history', error: e, stackTrace: stackTrace);
      emit(LiveStreamingError('Failed to load streaming history: ${e.toString()}'));
    }
  }

  Future<void> _onScheduleLiveStream(
    ScheduleLiveStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const SchedulingStream());
      _logger.d('$_tag: Scheduling live stream: ${event.title}');

      final scheduledStream = await _liveStreamingService.scheduleStream(
        title: event.title,
        description: event.description,
        scheduledStartTime: event.scheduledStartTime,
        type: event.type,
        maxViewers: event.maxViewers,
        thumbnailUrl: event.thumbnailUrl,
        tags: event.tags,
        isAdultsOnly: event.isAdultsOnly,
      );

      if (scheduledStream != null) {
        emit(StreamScheduled(scheduledStream));
        _logger.d('$_tag: Stream scheduled successfully');
      } else {
        emit(const LiveStreamingError('Failed to schedule stream'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to schedule stream',
        error: e,
        stackTrace: stackTrace,
      );
      emit(LiveStreamingError('Failed to schedule stream: ${e.toString()}'));
    }
  }

  Future<void> _onLoadScheduledStreams(
    LoadScheduledStreams event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Loading scheduled streams');

      final scheduledStreams = await _liveStreamingService
          .getScheduledStreams();

      emit(ScheduledStreamsLoaded(scheduledStreams));
      _logger.d('$_tag: Loaded ${scheduledStreams.length} scheduled streams');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load scheduled streams',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        LiveStreamingError('Failed to load scheduled streams: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLoadMyScheduledStreams(
    LoadMyScheduledStreams event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Loading my scheduled streams');

      final myScheduledStreams = await _liveStreamingService
          .getMyScheduledStreams();

      emit(ScheduledStreamsLoaded(myScheduledStreams));
      _logger.d(
        '$_tag: Loaded ${myScheduledStreams.length} my scheduled streams',
      );
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load my scheduled streams',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        LiveStreamingError(
          'Failed to load my scheduled streams: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCancelScheduledStream(
    CancelScheduledStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Canceling scheduled stream: ${event.streamId}');

      final success = await _liveStreamingService.cancelScheduledStream(
        event.streamId,
      );

      if (success) {
        emit(ScheduledStreamCanceled(event.streamId));
        _logger.d('$_tag: Stream canceled successfully');
      } else {
        emit(const LiveStreamingError('Failed to cancel stream'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to cancel stream',
        error: e,
        stackTrace: stackTrace,
      );
      emit(LiveStreamingError('Failed to cancel stream: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateScheduledStream(
    UpdateScheduledStream event,
    Emitter<LiveStreamingState> emit,
  ) async {
    try {
      emit(const LiveStreamingLoading());
      _logger.d('$_tag: Updating scheduled stream: ${event.streamId}');

      final updatedStream = await _liveStreamingService.updateScheduledStream(
        streamId: event.streamId,
        title: event.title,
        description: event.description,
        scheduledStartTime: event.scheduledStartTime,
        type: event.type,
        maxViewers: event.maxViewers,
        thumbnailUrl: event.thumbnailUrl,
        tags: event.tags,
        isAdultsOnly: event.isAdultsOnly,
      );

      if (updatedStream != null) {
        emit(
          ScheduledStreamUpdated(
            streamId: event.streamId,
            updatedStream: updatedStream,
          ),
        );
        _logger.d('$_tag: Stream updated successfully');
      } else {
        emit(const LiveStreamingError('Failed to update stream'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to update stream',
        error: e,
        stackTrace: stackTrace,
      );
      emit(LiveStreamingError('Failed to update stream: ${e.toString()}'));
    }
  }
}
