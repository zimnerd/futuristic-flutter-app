import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

/// Consolidated API client for all backend communication
///
/// This is the unified API client that replaces all scattered API services
/// with a single, comprehensive client that matches the actual backend
/// implementation endpoints.
///
/// Features:
/// - Centralized authentication handling
/// - Automatic token refresh
/// - Consistent error handling
/// - Request/response logging
/// - Type-safe response handling
/// - Complete endpoint coverage for all app features
/// - Singleton pattern for consistent state management
class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();
  String? _authToken;

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  ApiClient._() {
    _setupDio();
    _setupInterceptors();
  }

  // Allow creating instances for testing
  ApiClient.forTesting({String? baseUrl}) {
    _setupDio(baseUrl: baseUrl);
    _setupInterceptors();
  }

  void _setupDio({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
          'X-Platform': 'mobile-flutter',
          'X-App-Version': '1.0.0',
      },
      ),
    );
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
          _logger.e(
            '❌ ${error.response?.statusCode} ${error.requestOptions.uri}',
          );
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

  /// Get current authentication token
  String? get authToken => _authToken;

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
      data: {'email': email, 'password': password},
    );
  }

  /// Refresh authentication token
  Future<Response> refreshToken(String refreshToken) async {
    return await _dio.post(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
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
      data: {'sessionId': sessionId, 'code': code, 'email': email},
    );
  }

  /// Request password reset
  Future<Response> requestPasswordReset(String email) async {
    return await _dio.post('/auth/password-reset', data: {'email': email});
  }

  /// Reset password with token
  Future<Response> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _dio.post(
      '/auth/password-reset/confirm',
      data: {'token': token, 'newPassword': newPassword},
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

  /// Update user location
  Future<Response> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    return await _dio.patch(
      '/users/location',
      data: {'latitude': latitude, 'longitude': longitude},
    );
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
  Future<Response> getMatches({int limit = 20, int offset = 0}) async {
    return await _dio.get(
      '/matching/matches',
      queryParameters: {'limit': limit, 'offset': offset},
    );
  }

  /// Like a user
  Future<Response> likeUser(String userId) async {
    return await _dio.post('/matching/like', data: {'targetUserId': userId});
  }

  /// Pass on a user
  Future<Response> passUser(String userId) async {
    return await _dio.post('/matching/pass', data: {'targetUserId': userId});
  }

  /// Super like a user
  Future<Response> superLikeUser(String userId) async {
    return await _dio.post(
      '/matching/super-like',
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
  Future<Response> updateMatchPreferences(
    Map<String, dynamic> preferences,
  ) async {
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
  Future<Response> getConversations({int limit = 50, int offset = 0}) async {
    return await _dio.get(
      '/messaging/conversations',
      queryParameters: {'limit': limit, 'offset': offset},
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
      queryParameters: {'limit': limit, if (before != null) 'before': before},
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
    return await _dio.post('/users/block', data: {'userId': userId});
  }

  /// Unblock a user
  Future<Response> unblockUser(String userId) async {
    return await _dio.post('/users/unblock', data: {'userId': userId});
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
    return await _dio.post(
      '/ai-matching/profile-generation',
      data: profileData,
    );
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

  /// Get premium plans
  Future<Response> getPremiumPlans() async {
    return await _dio.get('/premium/plans');
  }

  /// Purchase premium subscription
  Future<Response> purchasePremium({
    required String planId,
    required Map<String, dynamic> paymentData,
  }) async {
    return await _dio.post(
      '/premium/purchase',
      data: {'planId': planId, 'paymentData': paymentData},
    );
  }

  /// Cancel premium subscription
  Future<Response> cancelPremium() async {
    return await _dio.post('/premium/cancel');
  }

  /// Get premium usage statistics
  Future<Response> getPremiumUsage() async {
    return await _dio.get('/premium/usage');
  }

  // ===========================================
  // NOTIFICATIONS ENDPOINTS
  // ===========================================

  /// Get user notifications
  Future<Response> getNotifications({int limit = 50, int offset = 0}) async {
    return await _dio.get(
      '/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
  }

  /// Get unread notifications count
  Future<Response> getUnreadNotificationsCount() async {
    return await _dio.get('/notifications/unread-count');
  }

  /// Mark notification as read
  Future<Response> markNotificationAsRead(String notificationId) async {
    return await _dio.patch('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<Response> markAllNotificationsAsRead() async {
    return await _dio.post('/notifications/mark-all-read');
  }

  /// Delete notification
  Future<Response> deleteNotification(String notificationId) async {
    return await _dio.delete('/notifications/$notificationId');
  }

  /// Update push notification settings
  Future<Response> updatePushSettings(Map<String, dynamic> settings) async {
    return await _dio.post('/notifications/push-settings', data: settings);
  }

  /// Get notification preferences
  Future<Response> getNotificationPreferences() async {
    return await _dio.get('/notifications/preferences');
  }

  /// Update notification preferences
  Future<Response> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    return await _dio.post('/notifications/preferences', data: preferences);
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
      data: {'participantIds': participantIds, 'type': type},
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

  /// Get call history
  Future<Response> getCallHistory({int limit = 50, int offset = 0}) async {
    return await _dio.get(
      '/webrtc/calls/history',
      queryParameters: {'limit': limit, 'offset': offset},
    );
  }

  // ===========================================
  // SOCIAL GAMING ENDPOINTS
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
      data: {'gameId': gameId, 'participantIds': participantIds},
    );
  }

  /// Join a game session
  Future<Response> joinGameSession(String sessionId) async {
    return await _dio.post('/social-gaming/sessions/$sessionId/join');
  }

  /// End a game session
  Future<Response> endGameSession(String sessionId) async {
    return await _dio.post('/social-gaming/sessions/$sessionId/end');
  }

  /// Get game leaderboard
  Future<Response> getGameLeaderboard(String gameId) async {
    return await _dio.get('/social-gaming/games/$gameId/leaderboard');
  }

  /// Submit game score
  Future<Response> submitGameScore({
    required String sessionId,
    required int score,
    Map<String, dynamic>? metadata,
  }) async {
    return await _dio.post(
      '/social-gaming/sessions/$sessionId/score',
      data: {'score': score, if (metadata != null) 'metadata': metadata},
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

  /// Delete media file
  Future<Response> deleteMedia(String mediaId) async {
    return await _dio.delete('/media/$mediaId');
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

  /// Get app usage statistics
  Future<Response> getUsageStats() async {
    return await _dio.get('/analytics/usage');
  }

  // ===========================================
  // PAYMENT ENDPOINTS
  // ===========================================

  /// Get payment methods
  Future<Response> getPaymentMethods() async {
    return await _dio.get('/payments/methods');
  }

  /// Add payment method
  Future<Response> addPaymentMethod(Map<String, dynamic> paymentData) async {
    return await _dio.post('/payments/methods', data: paymentData);
  }

  /// Remove payment method
  Future<Response> removePaymentMethod(String paymentMethodId) async {
    return await _dio.delete('/payments/methods/$paymentMethodId');
  }

  /// Process payment
  Future<Response> processPayment({
    required String paymentMethodId,
    required double amount,
    required String currency,
    String? description,
  }) async {
    return await _dio.post(
      '/payments/process',
      data: {
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        if (description != null) 'description': description,
      },
    );
  }

  /// Get payment history
  Future<Response> getPaymentHistory({int limit = 50, int offset = 0}) async {
    return await _dio.get(
      '/payments/history',
      queryParameters: {'limit': limit, 'offset': offset},
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('GET request failed: $e');
      rethrow;
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('PUT request failed: $e');
      rethrow;
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('PATCH request failed: $e');
      rethrow;
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('DELETE request failed: $e');
      rethrow;
    }
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      _logger.e('File upload failed: $e');
      rethrow;
    }
  }

  /// Health check endpoint
  Future<Response> healthCheck() async {
    return await _dio.get('/health');
  }

  /// Dispose the client
  void dispose() {
    _dio.close();
    _instance = null;
  }
}
