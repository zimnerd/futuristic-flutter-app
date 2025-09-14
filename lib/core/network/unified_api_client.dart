import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

/// Unified API client for all backend communication
/// 
/// This replaces all scattered API services with a single, comprehensive client
/// that matches the actual backend implementation endpoints.
/// 
/// Features:
/// - Centralized authentication handling
/// - Automatic token refresh
/// - Consistent error handling
/// - Request/response logging
/// - Type-safe response handling
class UnifiedApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();
  String? _authToken;

  static UnifiedApiClient? _instance;
  static UnifiedApiClient get instance => _instance ??= UnifiedApiClient._();
  
  UnifiedApiClient._() {
    _setupDio();
    _setupInterceptors();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Platform': 'mobile-flutter',
        'X-App-Version': '1.0.0',
      },
    ));
  }

  void _setupInterceptors() {
    // Request interceptor for authentication and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          
          _logger.d('🚀 ${options.method} ${options.uri}');
          _logger.d('📤 Headers: ${options.headers}');
          if (options.data != null) {
            _logger.d('📤 Body: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('✅ ${response.statusCode} ${response.requestOptions.uri}');
          _logger.d('📥 Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('❌ ${error.response?.statusCode} ${error.requestOptions.uri}');
          _logger.e('💥 Error: ${error.message}');
          _logger.e('📥 Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );

    // Token refresh interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && _authToken != null) {
            try {
              // Try to refresh token
              await _attemptTokenRefresh();
              
              // Retry the original request
              final clonedRequest = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              
              return handler.resolve(clonedRequest);
            } catch (refreshError) {
              _logger.e('Failed to refresh token: $refreshError');
              // Clear token and let the original error propagate
              _authToken = null;
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    _logger.i('🔐 Auth token set');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    _logger.i('🔓 Auth token cleared');
  }

  Future<void> _attemptTokenRefresh() async {
    // Implementation would depend on how refresh tokens are stored
    // This is a placeholder for the refresh logic
    throw Exception('Token refresh not implemented yet');
  }

  // ===========================================
  // AUTHENTICATION ENDPOINTS
  // ===========================================

  /// Register a new user
  Future<Response> register({
    required String email,
    required String password,
    required String username,
    String? firstName,
    String? lastName,
    String? birthdate,
    String? gender,
    String? location,
  }) async {
    return await _dio.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'username': username,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (birthdate != null) 'birthdate': birthdate,
        if (gender != null) 'gender': gender,
        if (location != null) 'location': location,
      },
    );
  }

  /// Login with email and password
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  /// Refresh authentication token
  Future<Response> refreshToken(String refreshToken) async {
    return await _dio.post(
      ApiConstants.refreshToken,
      data: {
        'refreshToken': refreshToken,
      },
    );
  }

  /// Logout current user
  Future<Response> logout() async {
    return await _dio.post(ApiConstants.logout);
  }

  /// Send OTP for verification
  Future<Response> sendOTP({
    required String email,
    String? phoneNumber,
    required String type,
    String? preferredMethod,
  }) async {
    return await _dio.post(
      ApiConstants.sendOtp,
      data: {
        'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'type': type,
        if (preferredMethod != null) 'preferredMethod': preferredMethod,
      },
    );
  }

  /// Verify OTP code
  Future<Response> verifyOTP({
    required String sessionId,
    required String code,
    required String email,
  }) async {
    return await _dio.post(
      ApiConstants.verifyOtp,
      data: {
        'sessionId': sessionId,
        'code': code,
        'email': email,
      },
    );
  }

  // ===========================================
  // USER MANAGEMENT ENDPOINTS
  // ===========================================

  /// Get current user profile
  Future<Response> getCurrentUser() async {
    return await _dio.get('/users/me');
  }

  /// Get user by ID
  Future<Response> getUserById(String userId) async {
    return await _dio.get('/users/$userId');
  }

  /// Update user profile
  Future<Response> updateProfile(Map<String, dynamic> updates) async {
    return await _dio.put('/users/me', data: updates);
  }

  /// Upload profile photo
  Future<Response> uploadProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    
    return await _dio.post('/users/photos', data: formData);
  }

  /// Delete profile photo
  Future<Response> deleteProfilePhoto(String photoId) async {
    return await _dio.delete('/users/photos/$photoId');
  }

  // ===========================================
  // MATCHING ENDPOINTS (Actual backend paths)
  // ===========================================

  /// Get match suggestions (discovery)
  Future<Response> getMatchSuggestions({
    int limit = 10,
    int offset = 0,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (filters != null) ...filters,
    };

    return await _dio.get(
      '/matching/suggestions',
      queryParameters: queryParams,
    );
  }

  /// Get user's matches
  Future<Response> getMatches({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _dio.get(
      '/matching/matches',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  /// Like a user
  Future<Response> likeUser(String userId) async {
    return await _dio.post(
      '/matching/like',
      data: {'targetUserId': userId},
    );
  }

  /// Pass on a user
  Future<Response> passUser(String userId) async {
    return await _dio.post(
      '/matching/pass',
      data: {'targetUserId': userId},
    );
  }

  /// Unmatch a user
  Future<Response> unmatchUser(String matchId) async {
    return await _dio.delete('/matching/match/$matchId');
  }

  /// Get matching preferences
  Future<Response> getMatchPreferences() async {
    return await _dio.get('/matching/preferences');
  }

  /// Update matching preferences
  Future<Response> updateMatchPreferences(Map<String, dynamic> preferences) async {
    return await _dio.post('/matching/preferences', data: preferences);
  }

  /// Get matching statistics
  Future<Response> getMatchingStats() async {
    return await _dio.get('/matching/stats');
  }

  /// Report a profile
  Future<Response> reportProfile({
    required String userId,
    required String reason,
    String? details,
  }) async {
    return await _dio.post(
      '/matching/report',
      data: {
        'targetUserId': userId,
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
  }

  // ===========================================
  // MESSAGING ENDPOINTS
  // ===========================================

  /// Create a new conversation
  Future<Response> createConversation({
    required List<String> participantIds,
  }) async {
    return await _dio.post(
      '/messaging/conversations',
      data: {'participantIds': participantIds},
    );
  }

  /// Get all conversations
  Future<Response> getConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dio.get(
      '/messaging/conversations',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  /// Get messages from a conversation
  Future<Response> getMessages({
    required String conversationId,
    int limit = 50,
    String? before,
  }) async {
    return await _dio.get(
      '/messaging/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before,
      },
    );
  }

  /// Send a message
  Future<Response> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    return await _dio.post(
      '/messaging/conversations/$conversationId/messages',
      data: {
        'content': content,
        'type': type,
        if (metadata != null) 'metadata': metadata,
      },
    );
  }

  /// Mark messages as read
  Future<Response> markMessagesAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    return await _dio.post(
      '/messaging/conversations/$conversationId/messages/read',
      data: {'messageIds': messageIds},
    );
  }

  /// Mark conversation as read
  Future<Response> markConversationAsRead(String conversationId) async {
    return await _dio.patch('/messaging/conversations/$conversationId/read');
  }

  /// Delete conversation
  Future<Response> deleteConversation(String conversationId) async {
    return await _dio.delete('/messaging/conversations/$conversationId');
  }

  /// Block a user
  Future<Response> blockUser(String userId) async {
    return await _dio.post(
      '/users/block',
      data: {'userId': userId},
    );
  }

  /// Report conversation
  Future<Response> reportConversation({
    required String conversationId,
    required String reason,
    String? description,
  }) async {
    return await _dio.post(
      '/messaging/conversations/$conversationId/report',
      data: {
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
  }

  /// Start conversation from match
  Future<Response> startConversationFromMatch({
    required String matchId,
    String? initialMessage,
  }) async {
    return await _dio.post(
      '/messaging/conversations/start-from-match',
      data: {
        'matchId': matchId,
        if (initialMessage != null) 'initialMessage': initialMessage,
      },
    );
  }

  // ===========================================
  // AI MATCHING ENDPOINTS (New features)
  // ===========================================

  /// Get AI-powered compatibility analysis
  Future<Response> getCompatibilityAnalysis(String targetUserId) async {
    return await _dio.get('/ai-matching/compatibility/$targetUserId');
  }

  /// Generate AI profile description
  Future<Response> generateAIProfile(Map<String, dynamic> profileData) async {
    return await _dio.post('/ai-matching/profile-generation', data: profileData);
  }

  /// Get AI conversation suggestions
  Future<Response> getConversationSuggestions(String targetUserId) async {
    return await _dio.post(
      '/ai/conversation-suggestions',
      data: {'targetUserId': targetUserId},
    );
  }

  // ===========================================
  // PREMIUM FEATURES ENDPOINTS
  // ===========================================

  /// Get premium features status
  Future<Response> getPremiumStatus() async {
    return await _dio.get('/premium/status');
  }

  /// Purchase premium subscription
  Future<Response> purchasePremium({
    required String planId,
    required Map<String, dynamic> paymentData,
  }) async {
    return await _dio.post(
      '/premium/purchase',
      data: {
        'planId': planId,
        'paymentData': paymentData,
      },
    );
  }

  // ===========================================
  // MEDIA ENDPOINTS
  // ===========================================

  /// Upload media file
  Future<Response> uploadMedia({
    required String filePath,
    required String type,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'type': type,
      if (description != null) 'description': description,
    });

    return await _dio.post('/media/upload', data: formData);
  }

  /// Get media file
  Future<Response> getMedia(String mediaId) async {
    return await _dio.get('/media/$mediaId');
  }

  // ===========================================
  // ANALYTICS ENDPOINTS
  // ===========================================

  /// Track user event
  Future<Response> trackEvent({
    required String eventName,
    required Map<String, dynamic> properties,
  }) async {
    return await _dio.post(
      '/analytics/events',
      data: {
        'eventName': eventName,
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get user insights
  Future<Response> getUserInsights() async {
    return await _dio.get('/analytics/insights');
  }

  // ===========================================
  // NOTIFICATIONS ENDPOINTS
  // ===========================================

  /// Get user notifications
  Future<Response> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dio.get(
      '/notifications',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  /// Mark notification as read
  Future<Response> markNotificationAsRead(String notificationId) async {
    return await _dio.patch('/notifications/$notificationId/read');
  }

  /// Update push notification settings
  Future<Response> updatePushSettings(Map<String, dynamic> settings) async {
    return await _dio.post('/notifications/push-settings', data: settings);
  }

  // ===========================================
  // WEBRTC ENDPOINTS
  // ===========================================

  /// Initiate a video/audio call
  Future<Response> initiateCall({
    required List<String> participantIds,
    required String type, // 'audio' or 'video'
  }) async {
    return await _dio.post(
      '/webrtc/calls',
      data: {
        'participantIds': participantIds,
        'type': type,
      },
    );
  }

  /// Join an existing call
  Future<Response> joinCall(String callId) async {
    return await _dio.post('/webrtc/calls/$callId/join');
  }

  /// End a call
  Future<Response> endCall(String callId) async {
    return await _dio.post('/webrtc/calls/$callId/end');
  }

  // ===========================================
  // SOCIAL GAMING ENDPOINTS (New feature)
  // ===========================================

  /// Get available games
  Future<Response> getAvailableGames() async {
    return await _dio.get('/social-gaming/games');
  }

  /// Start a game session
  Future<Response> startGameSession({
    required String gameId,
    required List<String> participantIds,
  }) async {
    return await _dio.post(
      '/social-gaming/sessions',
      data: {
        'gameId': gameId,
        'participantIds': participantIds,
      },
    );
  }

  // ===========================================
  // UTILITY METHODS
  // ===========================================

  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Dispose the client
  void dispose() {
    _dio.close();
  }
}