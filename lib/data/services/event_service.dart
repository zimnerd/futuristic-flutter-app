import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/event.dart';

/// Service for event API integration with NestJS backend
class EventService {
  static EventService? _instance;
  static EventService get instance => _instance ??= EventService._();
  EventService._();

  String? _authToken;

  /// Set authentication token
  void setAuthToken(String authToken) {
    _authToken = authToken;
  }

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
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (latitude != null) queryParams['lat'] = latitude.toString();
      if (longitude != null) queryParams['lng'] = longitude.toString();
      if (radiusKm != null) queryParams['radius'] = radiusKm.toString();
      if (category != null && category.isNotEmpty) queryParams['category'] = category;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
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
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radiusKm.toString(),
      };

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/nearby')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
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

  /// Get event details by ID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Event.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw EventServiceException(
          error['message'] ?? 'Failed to load event details',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event details: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Create a new event
  Future<Event> createEvent(CreateEventRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/events'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Event.fromJson(data);
      } else {
        final error = json.decode(response.body);
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

  /// Update an existing event
  Future<Event> updateEvent(String eventId, CreateEventRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Event.fromJson(data);
      } else {
        final error = json.decode(response.body);
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
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
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

  /// Attend an event
  Future<void> attendEvent(String eventId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId/attend'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw EventServiceException(
          error['message'] ?? 'Failed to attend event',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to attend event: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }

  /// Leave an event
  Future<void> leaveEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId/attend'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
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

  /// Get event attendees
  Future<List<EventAttendance>> getEventAttendees(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId/attendees'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventAttendance.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw EventServiceException(
          error['message'] ?? 'Failed to load event attendees',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get event attendees: $e');
      if (e is EventServiceException) rethrow;
      throw EventServiceException('Network error: $e');
    }
  }
}

/// Exception class for event service errors
class EventServiceException implements Exception {
  final String message;
  final int? statusCode;

  const EventServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'EventServiceException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}