import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/event.dart';

/// Service for event API integration with NestJS backend
/// 
/// Now uses the centralized ApiClient for all HTTP operations,
/// ensuring proper authentication, error handling, and logging.
class EventService {
  static EventService? _instance;
  static EventService get instance => _instance ??= EventService._();
  EventService._();

  final ApiClient _apiClient = ApiClient.instance;

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
        final List<dynamic> data = response.data;
        return data.map((json) => Event.fromJson(json)).toList();
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
        final List<dynamic> data = response.data;
        return data.map((json) => Event.fromJson(json)).toList();
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
  Future<List<String>> getEventCategories() async {
    try {
      final response = await _apiClient.getEventCategories();

      if (response.statusCode == 200) {
        return List<String>.from(response.data);
      } else {
        final error = response.data;
        throw EventServiceException(
          error['message'] ?? 'Failed to load event categories',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event categories: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
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