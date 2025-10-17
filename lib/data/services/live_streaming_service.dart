import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';

/// Service for live streaming feature
class LiveStreamingService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  LiveStreamingService(this._apiClient);

  /// Start a live stream
  Future<Map<String, dynamic>?> startLiveStream({
    required String title,
    required String description,
    List<String>? tags,
    bool isPrivate = false,
    Map<String, dynamic>? streamSettings,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/streams',
        data: {
          'title': title,
          'description': description,
          'tags': tags ?? [],
          'isPrivate': isPrivate,
          'streamSettings': streamSettings ?? {},
          'startedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Successfully started live stream: ${response.data['streamId']}');
        return response.data;
      } else {
        _logger.e('Failed to start live stream: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error starting live stream: $e');
      return null;
    }
  }

  /// Update a live stream
  Future<Map<String, dynamic>?> updateLiveStream({
    required String streamId,
    String? title,
    String? description,
    List<String>? tags,
    bool? isPrivate,
    Map<String, dynamic>? streamSettings,
  }) async {
    try {
      final data = <String, dynamic>{
        'streamId': streamId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (tags != null) data['tags'] = tags;
      if (isPrivate != null) data['isPrivate'] = isPrivate;
      if (streamSettings != null) data['streamSettings'] = streamSettings;

      final response = await _apiClient.patch(
        '/api/v1/live-streaming/streams/$streamId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Successfully updated live stream: $streamId');
        return response.data;
      } else {
        _logger.e('Failed to update live stream: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error updating live stream: $e');
      return null;
    }
  }

  /// End a live stream
  Future<bool> endLiveStream(String streamId) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/live-streaming/streams/$streamId/end',
        data: {
          'streamId': streamId,
          'endedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully ended live stream: $streamId');
        return true;
      } else {
        _logger.e('Failed to end live stream: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error ending live stream: $e');
      return false;
    }
  }

  /// Join a live stream as viewer
  Future<Map<String, dynamic>?> joinStream(String streamId) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/streams/$streamId/join',
        data: {
          'streamId': streamId,
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Successfully joined live stream: $streamId');
        return response.data;
      } else {
        _logger.e('Failed to join live stream: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error joining live stream: $e');
      return null;
    }
  }

  /// Leave a live stream
  Future<bool> leaveStream(String streamId) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/streams/$streamId/leave',
        data: {
          'streamId': streamId,
          'leftAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully left live stream: $streamId');
        return true;
      } else {
        _logger.e('Failed to leave live stream: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error leaving live stream: $e');
      return false;
    }
  }

  /// Get active live streams
  Future<List<Map<String, dynamic>>> getActiveStreams({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/live-streaming/streams',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (category != null) 'category': category,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['streams'] ?? [];
        final streams = data.map((stream) => Map<String, dynamic>.from(stream)).toList();
        
        _logger.d('Retrieved ${streams.length} active live streams');
        return streams;
      } else {
        _logger.e('Failed to get active streams: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting active streams: $e');
      return [];
    }
  }

  /// Search live streams
  Future<List<Map<String, dynamic>>> searchStreams({
    required String query,
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/live-streaming/streams/search',
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
          if (category != null) 'category': category,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['streams'] ?? [];
        final streams = data
            .map((stream) => Map<String, dynamic>.from(stream))
            .toList();

        _logger.d('Search found ${streams.length} streams for query: "$query"');
        return streams;
      } else {
        _logger.e('Failed to search streams: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error searching streams: $e');
      return [];
    }
  }

  /// Send message in live stream chat
  Future<bool> sendChatMessage({
    required String streamId,
    required String message,
    String? messageType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/chat',
        data: {
          'streamId': streamId,
          'message': message,
          'messageType': messageType ?? 'text',
          'sentAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully sent chat message to stream: $streamId');
        return true;
      } else {
        _logger.e('Failed to send chat message: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending chat message: $e');
      return false;
    }
  }

  /// Send virtual gift to streamer
  Future<bool> sendGiftToStreamer({
    required String streamId,
    required String giftId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/gift',
        data: {
          'streamId': streamId,
          'giftId': giftId,
          'message': message,
          'sentAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully sent gift to streamer: $streamId');
        return true;
      } else {
        _logger.e('Failed to send gift to streamer: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending gift to streamer: $e');
      return false;
    }
  }

  /// Report inappropriate content in stream
  Future<bool> reportStream({
    required String streamId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/report',
        data: {
          'streamId': streamId,
          'reason': reason,
          'description': description,
          'reportedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully reported stream: $streamId');
        return true;
      } else {
        _logger.e('Failed to report stream: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error reporting stream: $e');
      return false;
    }
  }

  /// Get stream analytics (for streamers)
  Future<Map<String, dynamic>?> getStreamAnalytics(String streamId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/live-streaming/streams/$streamId/analytics',
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Retrieved analytics for stream: $streamId');
        return response.data;
      } else {
        _logger.e('Failed to get stream analytics: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting stream analytics: $e');
      return null;
    }
  }

  /// Get user's streaming history
  Future<List<Map<String, dynamic>>> getStreamingHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/live-streaming/my-streams',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['streams'] ?? [];
        final streams = data.map((stream) => Map<String, dynamic>.from(stream)).toList();
        
        _logger.d('Retrieved ${streams.length} streaming history records');
        return streams;
      } else {
        _logger.e('Failed to get streaming history: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting streaming history: $e');
      return [];
    }
  }

  /// Generate Agora RTC token for live streaming
  ///
  /// [streamId] - The ID of the stream to generate token for
  /// [role] - Either 'broadcaster' (for host) or 'audience' (for viewers)
  ///
  /// Returns a map containing:
  /// - token: The Agora RTC token
  /// - channelName: The channel name (stream_${streamId})
  /// - uid: The user ID
  /// - appId: The Agora app ID
  /// - expiresIn: Token expiration time in seconds
  /// - role: The role used for token generation
  /// - isBroadcaster: Boolean indicating if user is the broadcaster
  Future<Map<String, dynamic>?> generateStreamRtcToken({
    required String streamId,
    required String role, // 'broadcaster' or 'audience'
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/streams/$streamId/rtc-token',
        queryParameters: {'role': role},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        _logger.d(
          'Successfully generated RTC token for stream: $streamId as $role',
        );
        _logger.d(
          'Channel: ${data['channelName']}, UID: ${data['uid']}, Is Broadcaster: ${data['isBroadcaster']}',
        );
        return data;
      } else {
        _logger.e('Failed to generate RTC token: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error generating RTC token: $e');
      return null;
    }
  }

  /// Schedule a future live stream
  Future<Map<String, dynamic>?> scheduleStream({
    required String title,
    String? description,
    required DateTime scheduledStartTime,
    required String type,
    int maxViewers = 100,
    String? thumbnailUrl,
    List<String>? tags,
    bool isAdultsOnly = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/live-streaming/streams/schedule',
        data: {
          'title': title,
          'description': description,
          'scheduledStartTime': scheduledStartTime.toIso8601String(),
          'type': type,
          'maxViewers': maxViewers,
          'thumbnailUrl': thumbnailUrl,
          'tags': tags ?? [],
          'isAdultsOnly': isAdultsOnly,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        _logger.d('Successfully scheduled stream: ${response.data['id']}');
        return response.data['data'];
      } else {
        _logger.e('Failed to schedule stream: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error scheduling stream: $e');
      return null;
    }
  }

  /// Get all scheduled streams
  Future<List<Map<String, dynamic>>> getScheduledStreams() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/live-streaming/streams/scheduled',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          _logger.d('Successfully fetched ${data.length} scheduled streams');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['streams'] is List) {
          _logger.d(
            'Successfully fetched ${data['streams'].length} scheduled streams',
          );
          return List<Map<String, dynamic>>.from(data['streams']);
        }
        return [];
      } else {
        _logger.e('Failed to get scheduled streams: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting scheduled streams: $e');
      return [];
    }
  }

  /// Get my scheduled streams
  Future<List<Map<String, dynamic>>> getMyScheduledStreams() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/live-streaming/streams/scheduled/my',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          _logger.d('Successfully fetched ${data.length} my scheduled streams');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['streams'] is List) {
          _logger.d(
            'Successfully fetched ${data['streams'].length} my scheduled streams',
          );
          return List<Map<String, dynamic>>.from(data['streams']);
        }
        return [];
      } else {
        _logger.e(
          'Failed to get my scheduled streams: ${response.statusMessage}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error getting my scheduled streams: $e');
      return [];
    }
  }

  /// Cancel a scheduled stream
  Future<bool> cancelScheduledStream(String streamId) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/live-streaming/streams/$streamId/cancel',
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully canceled scheduled stream: $streamId');
        return true;
      } else {
        _logger.e('Failed to cancel stream: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error canceling stream: $e');
      return false;
    }
  }

  /// Update a scheduled stream
  Future<Map<String, dynamic>?> updateScheduledStream({
    required String streamId,
    String? title,
    String? description,
    DateTime? scheduledStartTime,
    String? type,
    int? maxViewers,
    String? thumbnailUrl,
    List<String>? tags,
    bool? isAdultsOnly,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (scheduledStartTime != null) {
        data['scheduledStartTime'] = scheduledStartTime.toIso8601String();
      }
      if (type != null) data['type'] = type;
      if (maxViewers != null) data['maxViewers'] = maxViewers;
      if (thumbnailUrl != null) data['thumbnailUrl'] = thumbnailUrl;
      if (tags != null) data['tags'] = tags;
      if (isAdultsOnly != null) data['isAdultsOnly'] = isAdultsOnly;

      final response = await _apiClient.patch(
        '/api/v1/live-streaming/streams/$streamId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Successfully updated scheduled stream: $streamId');
        return response.data['data'];
      } else {
        _logger.e('Failed to update stream: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error updating stream: $e');
      return null;
    }
  }

  /// Upload stream thumbnail
  /// Returns the URL of the uploaded thumbnail
  Future<String?> uploadThumbnail(String localFilePath) async {
    try {
      _logger.d('Uploading thumbnail from: $localFilePath');

      final response = await _apiClient.uploadMedia(
        filePath: localFilePath,
        type: 'stream_thumbnail',
        description: 'Live stream thumbnail',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['data']?['url'] ?? response.data['url'];
        _logger.d('Successfully uploaded thumbnail: $url');
        return url;
      } else {
        _logger.e('Failed to upload thumbnail: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error uploading thumbnail: $e');
      return null;
    }
  }
}
