import 'dart:async';
import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';

/// Speed dating event status
enum SpeedDatingEventStatus { upcoming, active, completed, cancelled }

/// Service for speed dating feature with real-time session management
class SpeedDatingService {
  static final SpeedDatingService _instance = SpeedDatingService._internal();
  factory SpeedDatingService() => _instance;
  SpeedDatingService._internal();

  final ApiClient _apiClient = ApiClient.instance;
  final Logger _logger = Logger();

  // Stream controllers for real-time updates
  final _currentSessionController =
      StreamController<Map<String, dynamic>?>.broadcast();
  final _timerController = StreamController<int>.broadcast();
  final _eventStatusController =
      StreamController<SpeedDatingEventStatus>.broadcast();
  final _matchesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>?> get onCurrentSessionChanged =>
      _currentSessionController.stream;
  Stream<int> get onTimerTick => _timerController.stream;
  Stream<SpeedDatingEventStatus> get onEventStatusChanged =>
      _eventStatusController.stream;
  Stream<List<Map<String, dynamic>>> get onMatchesChanged =>
      _matchesController.stream;

  // Current state
  Map<String, dynamic>? _currentEvent;
  Map<String, dynamic>? _currentSession;
  Timer? _sessionTimer;
  int _remainingSeconds = 0;

  /// Get all upcoming speed dating events
  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    try {
      _logger.d('Fetching upcoming speed dating events');
      final response = await _apiClient.get(
        '/speed-dating/events?status=upcoming',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> eventsData = response.data['data'] as List<dynamic>;
        return eventsData.map((data) => data as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching events: $e');
      return [];
    }
  }

  /// Get event details by ID
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      _logger.d('Fetching event details: $eventId');
      final response = await _apiClient.get('/speed-dating/events/$eventId');

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching event: $e');
      return null;
    }
  }

  /// Join a speed dating event
  Future<Map<String, dynamic>?> joinEvent(String eventId, String userId) async {
    try {
      _logger.d('Joining event $eventId as user $userId');
      final response = await _apiClient.post(
        '/speed-dating/events/$eventId/join',
        data: {'userId': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        // Refresh event details
        _currentEvent = await getEventById(eventId);
        if (_currentEvent != null) {
          final statusStr = _currentEvent!['status'] as String;
          _eventStatusController.add(_parseEventStatus(statusStr));
        }

        return response.data['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      _logger.e('Error joining event: $e');
      return null;
    }
  }

  /// Leave a speed dating event
  Future<bool> leaveEvent(String eventId, String userId) async {
    try {
      _logger.d('Leaving event $eventId as user $userId');
      final response = await _apiClient.post(
        '/speed-dating/events/$eventId/leave',
        data: {'userId': userId},
      );

      if (response.statusCode == 200) {
        _currentEvent = null;
        _currentSession = null;
        _stopTimer();
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error leaving event: $e');
      return false;
    }
  }

  /// Start an event (admin/organizer only)
  Future<Map<String, dynamic>?> startEvent(String eventId) async {
    try {
      _logger.d('Starting event $eventId');
      final response = await _apiClient.post(
        '/speed-dating/events/$eventId/start',
      );

      if (response.statusCode == 200 && response.data != null) {
        _currentEvent = await getEventById(eventId);
        _eventStatusController.add(SpeedDatingEventStatus.active);

        return response.data['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      _logger.e('Error starting event: $e');
      return null;
    }
  }

  /// Get current active session for user
  Future<Map<String, dynamic>?> getCurrentSession(
    String eventId,
    String userId,
  ) async {
    try {
      _logger.d('Fetching current session for event $eventId');
      final response = await _apiClient.get(
        '/speed-dating/events/$eventId/current-session?userId=$userId',
      );

      if (response.statusCode == 200 && response.data != null) {
        _currentSession = response.data['data'] as Map<String, dynamic>;
        _currentSessionController.add(_currentSession);

        // Start timer for this session
        if (_currentSession != null) {
          _startSessionTimer(_currentSession!);
        }

        return _currentSession;
      }

      _currentSession = null;
      _currentSessionController.add(null);
      return null;
    } catch (e) {
      _logger.e('Error fetching current session: $e');
      return null;
    }
  }

  /// Get next upcoming session for user
  Future<Map<String, dynamic>?> getNextSession(
    String eventId,
    String userId,
  ) async {
    try {
      _logger.d('Fetching next session for event $eventId');
      final response = await _apiClient.get(
        '/speed-dating/events/$eventId/next-session?userId=$userId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching next session: $e');
      return null;
    }
  }

  /// Rate a completed session
  Future<Map<String, dynamic>?> rateSession(
    String sessionId,
    String userId,
    int rating, {
    String? notes,
  }) async {
    try {
      _logger.d('Rating session $sessionId: $rating stars');
      final response = await _apiClient.post(
        '/speed-dating/sessions/$sessionId/rate',
        data: {
          'userId': userId,
          'rating': rating,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = response.data['data'] as Map<String, dynamic>;

        // Check for mutual match
        if (result['mutualInterest'] == true) {
          _logger.i('Mutual match detected! 🎉');
        }

        return result;
      }

      return null;
    } catch (e) {
      _logger.e('Error rating session: $e');
      return null;
    }
  }

  /// Get matches for user in an event (mutual 4+ ratings)
  Future<List<Map<String, dynamic>>> getEventMatches(
    String eventId,
    String userId,
  ) async {
    try {
      _logger.d('Fetching matches for event $eventId');
      final response = await _apiClient.get(
        '/speed-dating/events/$eventId/matches?userId=$userId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> matchesData =
            response.data['data'] as List<dynamic>;
        final matches = matchesData
            .map((data) => data as Map<String, dynamic>)
            .toList();

        _matchesController.add(matches);
        return matches;
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching matches: $e');
      return [];
    }
  }

  /// Get user's event participation history
  Future<List<Map<String, dynamic>>> getUserEvents(String userId) async {
    try {
      _logger.d('Fetching user events for $userId');
      final response = await _apiClient.get(
        '/speed-dating/users/$userId/events',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> eventsData = response.data['data'] as List<dynamic>;
        return eventsData.map((data) => data as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error fetching user events: $e');
      return [];
    }
  }

  /// Start countdown timer for a session (3 minutes default)
  void _startSessionTimer(Map<String, dynamic> session) {
    _stopTimer();

    final now = DateTime.now();
    final sessionStart = DateTime.parse(session['startTime'] as String);
    final sessionDurationSeconds = 3 * 60; // 3 minutes

    // Calculate remaining time
    final elapsedSeconds = now.difference(sessionStart).inSeconds;
    _remainingSeconds = sessionDurationSeconds - elapsedSeconds;

    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _timerController.add(0);
      return;
    }

    // Emit initial time
    _timerController.add(_remainingSeconds);

    // Start countdown
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _timerController.add(0);
        _stopTimer();
        _logger.i('Session time expired');
      } else {
        _timerController.add(_remainingSeconds);
      }
    });

    _logger.d('Started session timer: $_remainingSeconds seconds remaining');
  }

  /// Stop the session timer
  void _stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Parse event status string to enum
  SpeedDatingEventStatus _parseEventStatus(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return SpeedDatingEventStatus.upcoming;
      case 'active':
        return SpeedDatingEventStatus.active;
      case 'completed':
        return SpeedDatingEventStatus.completed;
      case 'cancelled':
        return SpeedDatingEventStatus.cancelled;
      default:
        return SpeedDatingEventStatus.upcoming;
    }
  }

  /// Get remaining time in current session
  int get remainingSeconds => _remainingSeconds;

  /// Get current event
  Map<String, dynamic>? get currentEvent => _currentEvent;

  /// Get current session
  Map<String, dynamic>? get currentSession => _currentSession;

  /// Set current event (for tracking)
  set currentEvent(Map<String, dynamic>? event) {
    _currentEvent = event;
  }

  /// Dispose of resources
  void dispose() {
    _stopTimer();
    _currentSessionController.close();
    _timerController.close();
    _eventStatusController.close();
    _matchesController.close();
  }
}
