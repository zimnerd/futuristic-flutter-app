import '../../core/utils/logger.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_message.dart';
import '../database/events_database.dart';

/// Service for event API integration with NestJS backend
/// 
/// Now uses the centralized ApiClient for all HTTP operations,
/// ensuring proper authentication, error handling, and logging.
class EventService {
  static EventService? _instance;
  static EventService get instance => _instance ??= EventService._();
  EventService._();

  final ApiClient _apiClient = ApiClient.instance;
  final EventsDatabase _eventsDb = EventsDatabase.instance;

  /// Get events with optional location and category filtering
  Future<List<Event>> getEvents({
    double? latitude,
    double? longitude,
    double? radiusKm = 50.0,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.getEvents(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        category: category,
        page: page,
        limit: limit,
      );

      if (response.statusCode == 200) {
        // Handle both direct array response and structured response
        dynamic data = response.data;
        List<dynamic> eventsList;

        if (data is Map<String, dynamic>) {
          // Structured response format
          if (data['success'] == true && data['data'] != null) {
            eventsList = data['data'] as List<dynamic>;
          } else {
            throw EventServiceException(
              data['message'] ?? 'Failed to load events',
              statusCode: data['statusCode'] ?? response.statusCode,
            );
          }
        } else if (data is List) {
          // Direct array response
          eventsList = data;
        } else {
          throw EventServiceException(
            'Invalid response format',
            statusCode: response.statusCode,
          );
        }

        return eventsList.map((json) => Event.fromJson(json)).toList();
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load events',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get events: $e');
      if (e is EventServiceException) rethrow;
      
      // Handle DioException specifically
      if (e.toString().contains('500')) {
        throw EventServiceException(
          'Server error: The events service is currently unavailable. Please try again later.',
          statusCode: 500,
        );
      }
      
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get nearby events
  Future<List<Event>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final response = await _apiClient.getNearbyEvents(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      if (response.statusCode == 200) {
        // Handle both direct array response and structured response
        dynamic data = response.data;
        List<dynamic> eventsList;

        if (data is Map<String, dynamic>) {
          // Structured response format
          if (data['success'] == true && data['data'] != null) {
            eventsList = data['data'] as List<dynamic>;
          } else {
            throw EventServiceException(
              data['message'] ?? 'Failed to load nearby events',
              statusCode: data['statusCode'] ?? response.statusCode,
            );
          }
        } else if (data is List) {
          // Direct array response
          eventsList = data;
        } else {
          throw EventServiceException(
            'Invalid response format',
            statusCode: response.statusCode,
          );
        }

        return eventsList.map((json) => Event.fromJson(json)).toList();
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load nearby events',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get nearby events: $e');
      if (e is EventServiceException) rethrow;
      
      // Handle DioException specifically
      if (e.toString().contains('500')) {
        throw EventServiceException(
          'Server error: The nearby events service is currently unavailable. Please try again later.',
          statusCode: 500,
        );
      }
      
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get event by ID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await _apiClient.getEventById(eventId);

      if (response.statusCode == 200) {
        return Event.fromJson(response.data);
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event by ID: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Create a new event
  Future<Event> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required double latitude,
    required double longitude,
    int? maxParticipants,
    String? category,
    String? image,
  }) async {
    try {
      final response = await _apiClient.createEvent(
        title: title,
        description: description,
        location: location,
        dateTime: dateTime,
        latitude: latitude,
        longitude: longitude,
        maxParticipants: maxParticipants,
        category: category,
        image: image,
      );

      if (response.statusCode == 201) {
        return Event.fromJson(response.data);
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to create event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to create event: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Update an event
  Future<Event> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? location,
    DateTime? dateTime,
    double? latitude,
    double? longitude,
    int? maxParticipants,
    String? category,
    String? image,
  }) async {
    try {
      final response = await _apiClient.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        location: location,
        dateTime: dateTime,
        latitude: latitude,
        longitude: longitude,
        maxParticipants: maxParticipants,
        category: category,
        image: image,
      );

      if (response.statusCode == 200) {
        return Event.fromJson(response.data);
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to update event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update event: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      final response = await _apiClient.deleteEvent(eventId);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to delete event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to delete event: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Join an event
  Future<void> joinEvent(String eventId) async {
    try {
      final response = await _apiClient.joinEvent(eventId);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to join event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to join event: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Leave an event
  Future<void> leaveEvent(String eventId) async {
    try {
      final response = await _apiClient.leaveEvent(eventId);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to leave event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to leave event: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get event participants
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
    try {
      final response = await _apiClient.getEventParticipants(eventId);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load event participants',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event participants: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get user's events
  Future<List<Event>> getUserEvents() async {
    try {
      final response = await _apiClient.getUserEvents();

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load user events',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get user events: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Send event message
  Future<void> sendEventMessage({
    required String eventId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.sendEventMessage(
        eventId: eventId,
        content: content,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to send event message',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to send event message: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get event messages/chat history
  Future<List<EventMessage>> getEventMessages({
    required String eventId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.getEventMessages(
        eventId: eventId,
        page: page,
        limit: limit,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> messagesJson;

        // Handle both array response and structured response
        if (data is List) {
          messagesJson = data;
        } else if (data is Map && data.containsKey('messages')) {
          messagesJson = data['messages'] ?? [];
        } else if (data is Map && data.containsKey('data')) {
          final dataContent = data['data'];
          if (dataContent is List) {
            messagesJson = dataContent;
          } else if (dataContent is Map &&
              dataContent.containsKey('messages')) {
            messagesJson = dataContent['messages'] ?? [];
          } else {
            messagesJson = [];
          }
        } else {
          messagesJson = [];
        }

        // Get current user ID for 'isMe' flag
        final currentUserId = await _apiClient.getCurrentUserId();

        return messagesJson
            .map((json) => EventMessage.fromJson(json, currentUserId))
            .toList();
      } else if (response.statusCode == 404) {
        throw EventServiceException(
          'Event messages not found',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        throw EventServiceException(
          'Authentication required to view messages',
          statusCode: response.statusCode,
        );
      } else {
        throw EventServiceException(
          'Failed to fetch event messages',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event messages: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Update RSVP status
  Future<void> updateEventRSVP({
    required String eventId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.updateEventRSVP(
        eventId: eventId,
        status: status,
      );

      if (response.statusCode != 200) {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to update RSVP',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update event RSVP: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get event categories
  /// Get all event categories from API
  /// Get event categories with intelligent caching
  /// 
  /// 1. Check local cache first (1 hour freshness)
  /// 2. If cache is fresh, return cached data
  /// 3. If cache is stale or missing, fetch from API
  /// 4. Update cache with new data
  /// 5. Fallback to cached data if API fails
  Future<List<EventCategory>> getEventCategories({bool forceRefresh = false}) async {
    try {
      // Check cache first (unless forcing refresh)
      if (!forceRefresh) {
        final isCacheFresh = await _eventsDb.isCategoriesCacheFresh();
        if (isCacheFresh) {
          final cachedCategories = await _eventsDb.getCachedCategories();
          if (cachedCategories.isNotEmpty) {
            AppLogger.info('Using cached event categories (${cachedCategories.length} items)');
            return cachedCategories;
          }
        }
      }

      // Fetch from API
      AppLogger.info('Fetching event categories from API...');
      final response = await _apiClient.getEventCategories();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] is List) {
          final categories = (data['data'] as List)
              .map((categoryJson) => EventCategory.fromJson(categoryJson as Map<String, dynamic>))
              .toList();

          // Cache the fresh data
          await _eventsDb.cacheCategories(categories);
          AppLogger.info('Cached ${categories.length} event categories');
          
          return categories;
        } else {
          throw EventServiceException('Invalid response format for event categories');
        }
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load event categories',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event categories from API: $e');

      // Fallback to cached data (even if stale)
      try {
        final cachedCategories = await _eventsDb.getCachedCategories();
        if (cachedCategories.isNotEmpty) {
          AppLogger.info('Using stale cached categories as fallback (${cachedCategories.length} items)');
          return cachedCategories;
        }
      } catch (cacheError) {
        AppLogger.error('Failed to get cached categories: $cacheError');
      }

      // No cache available, rethrow original error
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Get events filtered by category slug (API-driven)
  Future<List<Event>> getEventsByCategory(String categorySlug) async {
    try {
      final response = await _apiClient.getEvents(category: categorySlug);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] is List) {
          return (data['data'] as List)
              .map(
                (eventJson) =>
                    Event.fromJson(eventJson as Map<String, dynamic>),
              )
              .toList();
        } else {
          return [];
        }
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load events for category',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get events by category: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Clear event categories cache
  /// Useful for manual refresh or troubleshooting
  Future<void> clearCategoriesCache() async {
    try {
      await _eventsDb.clearCache();
      AppLogger.info('Event categories cache cleared');
    } catch (e) {
      AppLogger.error('Failed to clear categories cache: $e');
    }
  }

  /// Get cache statistics for debugging
  Future<Map<String, int>> getCacheStats() async {
    return await _eventsDb.getCacheStats();
  }

  /// Legacy method for backward compatibility
  /// TODO: Remove once all references are updated
  Future<List<String>> getEventCategorySlugs() async {
    final categories = await getEventCategories();
    return categories.map((category) => category.slug).toList();
  }

  /// Get popular events
  Future<List<Event>> getPopularEvents() async {
    try {
      final response = await _apiClient.getPopularEvents();

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load popular events',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get popular events: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }
}

/// Exception thrown by EventService operations
class EventServiceException implements Exception {
  final String message;
  final int? statusCode;

  const EventServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'EventServiceException: $message (status: $statusCode)';
}