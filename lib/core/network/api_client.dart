import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../../data/services/token_service.dart';
import '../../data/services/global_auth_handler.dart';

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
  final TokenService _tokenService = TokenService();
  String? _authToken;

  // ✅ Track refresh attempts to prevent infinite loops
  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  /// Get current user ID from stored token or user data
  Future<String?> getCurrentUserId() async {
    try {
      // Try to get user ID from stored user data first
      final userData = await _tokenService.getUserData();
      if (userData != null && userData.containsKey('id')) {
        return userData['id']?.toString();
      }

      // Fallback to extracting from access token
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        return _tokenService.extractUserIdFromToken(token);
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get current user ID: $e');
      return null;
    }
  }

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
    // Use longer timeouts - 120 seconds for both dev and production to handle slow networks
    // This is especially important for OTP sending which may take longer
    const connectTimeout = Duration(seconds: 120);
    const receiveTimeout = Duration(seconds: 120);
    const sendTimeout = Duration(seconds: 120);

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
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
            _logger.i(
              '🔑 Auth token added to request: ${_authToken!.substring(0, 20)}...',
            );
          } else {
            _logger.w('⚠️ No auth token available for request');
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

    // Token refresh interceptor with global 401 handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Skip 401 handling for logout endpoint - logout failure is expected when auth is invalid
            if (error.requestOptions.path.contains('/auth/logout')) {
              _logger.d(
                '🔓 401 on logout endpoint - this is expected, not triggering auth failure',
              );
              handler.next(error);
              return;
            }

            // ✅ CRITICAL FIX: Skip refresh attempts for the refresh endpoint itself to prevent infinite loop
            if (error.requestOptions.path.contains('/auth/refresh')) {
              _logger.e(
                '🚫 401 on refresh endpoint - token is invalid, forcing logout',
              );
              _refreshAttempts = 0; // Reset counter
              
              await GlobalAuthHandler.instance.handleAuthenticationFailure(
                reason: 'Refresh token is invalid or expired',
                clearTokens: true,
              );

              return handler.resolve(
                Response(
                  requestOptions: error.requestOptions,
                  statusCode: 401,
                  data: {
                    'success': false,
                    'message':
                        'Your session has expired. Please log in again.',
                    'errors': [],
                  },
                ),
              );
            }

            // ✅ CRITICAL FIX: Limit refresh attempts to prevent infinite loops
            if (_refreshAttempts >= _maxRefreshAttempts) {
              _logger.e(
                '🚫 Maximum refresh attempts ($_maxRefreshAttempts) reached, forcing logout',
              );
              _refreshAttempts = 0; // Reset counter
              
              await GlobalAuthHandler.instance.handleAuthenticationFailure(
                reason: 'Maximum token refresh attempts exceeded',
                clearTokens: true,
              );

              return handler.resolve(
                Response(
                  requestOptions: error.requestOptions,
                  statusCode: 401,
                  data: {
                    'success': false,
                    'message':
                        'Unable to refresh your session. Please log in again.',
                    'errors': [],
                  },
                ),
              );
            }

            // Try to refresh token if we have one
            if (_authToken != null) {
              try {
                _refreshAttempts++; // ✅ Increment counter
                _logger.i('🔄 Attempting token refresh for 401 error (attempt $_refreshAttempts/$_maxRefreshAttempts)...');
                await _attemptTokenRefresh();
                
                _refreshAttempts = 0; // ✅ Reset counter on success

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
                _logger.e('❌ Token refresh failed: $refreshError');

                // Token refresh failed - trigger global logout
                await GlobalAuthHandler.instance.handleAuthenticationFailure(
                  reason: 'Token refresh failed after 401 response',
                  clearTokens: true,
                );

                // Return user-friendly error instead of technical details
                return handler.resolve(
                  Response(
                    requestOptions: error.requestOptions,
                    statusCode: 401,
                    data: {
                      'success': false,
                      'message':
                          'Your session has expired. Please log in again.',
                      'errors': [],
                    },
                  ),
                );
              }
            } else {
              // No auth token available - trigger global logout
              _logger.w('⚠️ 401 error with no auth token - triggering logout');
              await GlobalAuthHandler.instance.handleAuthenticationFailure(
                reason: 'Received 401 with no authentication token',
                clearTokens: true,
              );

              // Return user-friendly error instead of technical details
              return handler.resolve(
                Response(
                  requestOptions: error.requestOptions,
                  statusCode: 401,
                  data: {
                    'success': false,
                    'message': 'Your session has expired. Please log in again.',
                    'errors': [],
                  },
                ),
              );
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

  /// Initialize auth token from storage
  Future<void> initializeAuthToken() async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        // Check if token is expired
        if (!_tokenService.isTokenExpired(token)) {
          _authToken = token;
          _logger.i('🔐 Auth token loaded from storage');
        } else {
          _logger.w('⚠️ Stored token is expired, attempting refresh...');
          await _attemptTokenRefresh();
        }
      }
    } catch (e) {
      _logger.e('❌ Failed to initialize auth token: $e');
      await _tokenService.clearTokens();
    }
  }

  /// Get current authentication token
  String? get authToken => _authToken;

  Future<void> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      _logger.i('🔄 Attempting token refresh...');

      // Call the refresh endpoint
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String?;

        // Store new tokens
        await _tokenService.storeTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );

        // Update the current auth token
        _authToken = newAccessToken;

        _logger.i('✅ Token refresh successful');
      } else {
        throw Exception(
          'Token refresh failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('❌ Token refresh failed: $e');
      // Clear tokens on refresh failure
      await _tokenService.clearTokens();
      _authToken = null;
      rethrow;
    }
  }

  // ===========================================
  // AUTHENTICATION ENDPOINTS
  // ===========================================

  /// Register a new user
  Future<Response> register({
    required String email,
    required String password,
    required String username,
    String? phone,
    String? firstName,
    String? lastName,
    String? birthdate,
    String? gender,
    String? location,
  }) async {
    return await _dio.post(
      ApiConstants.authRegister,
      data: {
        'email': email,
        'password': password,
        'username': username,
        if (phone != null) 'phone': phone,
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
      ApiConstants.authLogin,
      data: {'email': email, 'password': password},
    );
  }

  /// Refresh authentication token
  Future<Response> refreshToken(String refreshToken) async {
    return await _dio.post(
      ApiConstants.authRefresh,
      data: {'refreshToken': refreshToken},
    );
  }

  /// Logout current user
  /// This method gracefully handles cases where the auth token is invalid or missing
  Future<Response?> logout() async {
    try {
      // Check if we have an auth token
      if (_authToken == null || _authToken!.isEmpty) {
        _logger.w(
          '🔓 No auth token available for logout - skipping server call',
        );
        return null;
      }

      return await _dio.post(ApiConstants.authLogout);
    } catch (e) {
      // If logout fails (e.g., 401), don't throw - just log and continue
      // The local cleanup will still happen
      _logger.w(
        '⚠️ Server logout failed (this is expected if token is invalid): $e',
      );
      return null;
    }
  }

  /// Send OTP for verification
  Future<Response> sendOTP({
    String? email,
    String? phoneNumber,
    String? countryCode,
    required String type,
    String? preferredMethod,
  }) async {
    return await _dio.post(
      ApiConstants.authSendOTP,
      data: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (countryCode != null) 'countryCode': countryCode,
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
    // Determine if email is actually a phone number
    final isPhone = email.startsWith('+') || RegExp(r'^\d+$').hasMatch(email);

    return await _dio.post(
      ApiConstants.authVerifyOTP,
      data: {
        'sessionId': sessionId,
        'code': code,
        if (isPhone) 'phoneNumber': email else 'email': email,
      },
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

    return await _dio.post('/media/upload', data: formData);
  }

  /// Delete profile photo
  Future<Response> deleteProfilePhoto(String photoId) async {
    return await _dio.delete('/media/$photoId');
  }

  /// Confirm/finalize profile enrichment after setup is complete
  /// This tells the backend that the user has completed all required profile sections
  /// and is ready to access the main app features
  Future<Response> confirmProfileEnrichment() async {
    return await _dio.post('/users/me/profile/confirm');
  }

  /// Update user location
  Future<Response> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    return await _dio.put(
      // Fixed: was PATCH, now PUT to match backend
      '/users/me/location', // Fixed: was /users/location, now /me/location
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }

  // ===========================================
  // INTERESTS ENDPOINTS
  // ===========================================

  /// Get all interest categories with nested interests
  Future<Response> getInterestCategories() async {
    return await _dio.get('/interests/categories');
  }

  /// Get all interests with category information
  Future<Response> getAllInterests() async {
    return await _dio.get('/interests');
  }

  /// Get just the interest names (backward compatibility)
  Future<Response> getInterestNames() async {
    return await _dio.get('/interests/names');
  }

  // ===========================================
  // PREFERENCES ENDPOINTS
  // ===========================================

  /// Get all available occupations
  Future<Response> getOccupations() async {
    return await _dio.get('/preferences/occupations');
  }

  /// Get all available relationship types
  Future<Response> getRelationshipTypes() async {
    return await _dio.get('/preferences/relationship-types');
  }

  /// Get all available languages
  Future<Response> getLanguages() async {
    return await _dio.get('/preferences/languages');
  }

  /// Get all available education levels
  Future<Response> getEducationLevels() async {
    return await _dio.get('/preferences/education-levels');
  }

  /// Get all available body types
  Future<Response> getBodyTypes() async {
    return await _dio.get('/preferences/body-types');
  }

  /// Get all available drinking options
  Future<Response> getDrinkingOptions() async {
    return await _dio.get('/preferences/drinking-options');
  }

  /// Get all available smoking options
  Future<Response> getSmokingOptions() async {
    return await _dio.get('/preferences/smoking-options');
  }

  /// Get all available exercise frequency options
  Future<Response> getExerciseOptions() async {
    return await _dio.get('/preferences/exercise-options');
  }

  /// Get all preferences in a single call (optional convenience method)
  Future<Response> getAllPreferences() async {
    return await _dio.get('/preferences/all');
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
    bool excludeWithConversations = false,
  }) async {
    final queryParams = {
      'limit': limit,
      'offset': offset,
      'excludeWithConversations': excludeWithConversations.toString(),
    };

    _logger.d('🔍 Getting matches with params: $queryParams');

    final response = await _dio.get(
      '/matching/matches',
      queryParameters: queryParams,
    );

    _logger.d('🔍 Matches response: ${response.data}');

    return response;
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
      '/reports',
      data: {
        'reportedUserId': userId,
        'type': 'profile',
        'reason': reason,
        if (details != null) 'description': details,
      },
    );
  }

  /// Report an event
  Future<Response> reportEvent({
    required String eventId,
    required String reason,
    String? description,
  }) async {
    return await _dio.post(
      '/reports',
      data: {
        'eventId': eventId,
        'type': 'event',
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
  }

  // ===========================================
  // MESSAGING ENDPOINTS
  // ===========================================

  /// Create a new conversation
  Future<Response> createConversation({
    required String participantId,
    String? title,
    bool isGroup = false,
    String? initialMessage,
  }) async {
    return await _dio.post(
      '/messaging/conversations',
      data: {
        'participantId': participantId,
        if (title != null) 'title': title,
        'isGroup': isGroup,
        if (initialMessage != null) 'initialMessage': initialMessage,
      },
    );
  }

  /// Get all conversations
  Future<Response> getConversations({int limit = 50, int offset = 0}) async {
    return await _dio.get(
      '/chat/conversations',
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
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'limit': limit, if (before != null) 'before': before},
    );
  }

  /// Search messages across conversations
  Future<Response> searchMessages({
    required String query,
    String? conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dio.get(
      '/chat/search/messages',
      queryParameters: {
        'query': query,
        if (conversationId != null) 'conversationId': conversationId,
        'limit': limit,
        'offset': offset,
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

  /// Create a call message entry (WhatsApp-style)
  Future<Response> createCallMessage({
    required String conversationId,
    required String callType, // 'audio' or 'video'
    required int duration, // in seconds
    required bool isIncoming,
    bool isMissed = false,
  }) async {
    return await _dio.post(
      '/chat/conversations/$conversationId/call-message',
      data: {
        'callType': callType,
        'duration': duration,
        'isIncoming': isIncoming,
        'isMissed': isMissed,
      },
    );
  }

  /// Mark messages as read
  Future<Response> markMessagesAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    return await _dio.post(
      '/chat/conversations/$conversationId/read',
      data: {'messageIds': messageIds},
    );
  }

  /// Mark conversation as read
  Future<Response> markConversationAsRead(String conversationId) async {
    return await _dio.patch('/chat/conversations/$conversationId/read');
  }

  /// Get unread message count
  Future<Response> getUnreadMessageCount() async {
    return await _dio.get('/messaging/unread-count');
  }

  /// Mark all conversations as read
  Future<Response> markAllConversationsAsRead() async {
    return await _dio.post('/messaging/mark-all-read');
  }

  /// Delete conversation
  Future<Response> deleteConversation(String conversationId) async {
    return await _dio.delete('/chat/conversations/$conversationId');
  }

  /// Block a user
  Future<Response> blockUser(String userId) async {
    return await _dio.post('/users/block', data: {'userId': userId});
  }

  /// Unblock a user
  Future<Response> unblockUser(String userId) async {
    return await _dio.delete('/users/block/$userId');
  }

  /// Report conversation
  Future<Response> reportConversation({
    required String conversationId,
    required String reason,
    String? description,
  }) async {
    return await _dio.post(
      '/reports',
      data: {
        'conversationId': conversationId,
        'type': 'conversation',
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
      '/chat/conversations/start-from-match',
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
  // NEW AI SERVICES ENDPOINTS
  // ===========================================

  /// Analyze conversation health and sentiment
  Future<Response> analyzeConversation({
    required List<String> messages,
    String? targetUserId,
    String? analysisType,
  }) async {
    return await _dio.post(
      ApiConstants.aiConversationAnalyze,
      data: {
        'messages': messages,
        if (targetUserId != null) 'targetUserId': targetUserId,
        if (analysisType != null) 'analysisType': analysisType,
      },
    );
  }

  /// Analyze user profile for improvements
  Future<Response> analyzeProfile({
    required String profileId,
    String? analysisType,
    String? targetProfileId,
    List<String>? images,
    Map<String, dynamic>? context,
  }) async {
    return await _dio.post(
      ApiConstants.aiProfileAnalyze,
      data: {
        'profileId': profileId,
        if (analysisType != null) 'analysisType': analysisType,
        if (targetProfileId != null) 'targetProfileId': targetProfileId,
        if (images != null) 'images': images,
        if (context != null) 'context': context,
      },
    );
  }

  /// Get AI-generated conversation starters for a profile
  Future<Response> getProfileConversationStarters({
    required String profileId,
    String? analysisType,
    Map<String, dynamic>? context,
  }) async {
    return await _dio.post(
      ApiConstants.aiProfileConversationStarters,
      data: {
        'profileId': profileId,
        if (analysisType != null) 'analysisType': analysisType,
        if (context != null) 'context': context,
      },
    );
  }

  /// Analyze compatibility between profiles
  Future<Response> analyzeProfileCompatibility({
    required String profileId,
    String? analysisType,
    Map<String, dynamic>? context,
  }) async {
    return await _dio.post(
      ApiConstants.aiProfileCompatibility,
      data: {
        'profileId': profileId,
        if (analysisType != null) 'analysisType': analysisType,
        if (context != null) 'context': context,
      },
    );
  }

  /// Analyze photos for conversation ideas
  Future<Response> analyzePhotos({
    required List<String> photoUrls,
    String? analysisType,
  }) async {
    return await _dio.post(
      ApiConstants.aiPhotosAnalyze,
      data: {
        'photoUrls': photoUrls,
        if (analysisType != null) 'analysisType': analysisType,
      },
    );
  }

  /// Get comprehensive AI chat assistance
  Future<Response> getChatAssistance({
    required String assistanceType,
    required String conversationId,
    required String userRequest,
    Map<String, dynamic>? contextOptions,
    String? specificMessage,
    String? tone,
    int? suggestionCount,
  }) async {
    return await _dio.post(
      ApiConstants.aiChatAssistance,
      data: {
        'assistanceType': assistanceType,
        'conversationId': conversationId,
        'userRequest': userRequest,
        if (contextOptions != null) 'contextOptions': contextOptions,
        if (specificMessage != null) 'specificMessage': specificMessage,
        if (tone != null) 'tone': tone,
        if (suggestionCount != null) 'suggestionCount': suggestionCount,
      },
    );
  }

  /// Submit feedback for AI suggestions
  Future<Response> submitAiFeedback({
    required String aiResponseId,
    required String featureType,
    String? suggestionId,
    required int rating,
    String? comment,
    bool? helpful,
    bool? implemented,
    Map<String, dynamic>? context,
  }) async {
    return await _dio.post(
      ApiConstants.aiFeedback,
      data: {
        'aiResponseId': aiResponseId,
        'featureType': featureType,
        if (suggestionId != null) 'suggestionId': suggestionId,
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (helpful != null) 'helpful': helpful,
        if (implemented != null) 'implemented': implemented,
        if (context != null) 'context': context,
      },
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
    return await _dio.put('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<Response> markAllNotificationsAsRead() async {
    return await _dio.patch('/notifications/mark-all-read');
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

  /// Get Agora RTC token for a call
  Future<Response> getCallToken({
    required String callId,
    bool audioOnly = false,
  }) async {
    return await _dio.post(
      '/webrtc/calls/$callId/token',
      queryParameters: {'audioOnly': audioOnly.toString()},
    );
  }

  /// ⚠️ DEPRECATED: Use CallInvitationService.sendCallInvitation() instead
  ///
  /// This REST API endpoint is deprecated because it generates Agora tokens
  /// immediately and causes premature "Connected" status before the other
  /// user accepts. Please migrate to WebSocket-based CallInvitationService.
  ///
  /// See: CALL_SYSTEM_COMPLETE_MIGRATION.md for migration guide
  @Deprecated(
    'Use CallInvitationService.sendCallInvitation() instead. '
    'This REST API call will be removed in a future version.',
  )
  Future<Response> initiateCall({
    required List<String> participantIds,
    required String type, // 'audio' or 'video'
  }) async {
    _logger.w(
      '⚠️ DEPRECATED: initiateCall() REST API called\n'
      'Please migrate to CallInvitationService.sendCallInvitation()\n'
      'See: CALL_SYSTEM_COMPLETE_MIGRATION.md',
    );
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

  /// Accept an incoming call
  Future<Response> acceptCall(String callId) async {
    return await _dio.post('/webrtc/calls/$callId/accept');
  }

  /// Reject an incoming call
  Future<Response> rejectCall(String callId, {String? reason}) async {
    return await _dio.post(
      '/webrtc/calls/$callId/reject',
      data: {'reason': reason ?? 'User declined'},
    );
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
      '/analytics/track/event',
      data: {
        'eventName': eventName,
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get user insights
  Future<Response> getUserInsights() async {
    return await _dio.get('/analytics/user/behavior');
  }

  /// Get app usage statistics
  Future<Response> getUsageStats() async {
    return await _dio.get('/analytics/app/usage');
  }

  // ===========================================
  // PAYMENT ENDPOINTS
  // ===========================================

  /// Get payment methods
  Future<Response> getPaymentMethods() async {
    return await _dio.get('/payment/methods');
  }

  /// Add payment method
  Future<Response> addPaymentMethod(Map<String, dynamic> paymentData) async {
    return await _dio.post('/payment/methods', data: paymentData);
  }

  /// Remove payment method
  Future<Response> removePaymentMethod(String paymentMethodId) async {
    return await _dio.delete('/payment/methods/$paymentMethodId');
  }

  /// Create payment intent (replaces process payment)
  Future<Response> createPaymentIntent({
    required double amount,
    required String currency,
    String? description,
  }) async {
    return await _dio.post(
      '/payment/create-intent',
      data: {
        'amount': amount,
        'currency': currency,
        if (description != null) 'description': description,
      },
    );
  }

  /// Get payment history
  Future<Response> getPaymentHistory({int limit = 20, int offset = 0}) async {
    return await _dio.get(
      '/payment/history',
      queryParameters: {'limit': limit, 'offset': offset},
    );
  }

  // ===========================================
  // HTTP UTILITY METHODS
  // ===========================================

  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Generic HEAD request
  Future<Response<T>> head<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.head<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Download file
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) async {
    return await _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      options: options,
    );
  }

  /// Send FormData (for file uploads)
  Future<Response<T>> postFormData<T>(
    String path,
    FormData formData, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.post<T>(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;

  // ============================================================================
  // GENERIC HTTP METHODS
  // ============================================================================
  // For backwards compatibility with existing code that uses generic endpoints

  /// Generic GET request - exposed for backwards compatibility
  Future<Response<T>> rawGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic POST request - exposed for backwards compatibility
  Future<Response<T>> rawPost<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic PUT request - exposed for backwards compatibility
  Future<Response<T>> rawPut<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic PATCH request - exposed for backwards compatibility
  Future<Response<T>> rawPatch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Generic DELETE request - exposed for backwards compatibility
  Future<Response<T>> rawDelete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ===========================================
  // EVENTS ENDPOINTS
  // ===========================================

  /// Get events with optional location and category filtering
  Future<Response> getEvents({
    double? latitude,
    double? longitude,
    double? radiusKm = 50.0,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (latitude != null) queryParams['lat'] = latitude;
    if (longitude != null) queryParams['lng'] = longitude;
    if (radiusKm != null) queryParams['radius'] = radiusKm;
    if (category != null && category.isNotEmpty)
      {
      queryParams['category'] = category;
    }

    return await _dio.get('/events', queryParameters: queryParams);
  }

  /// Get nearby events
  Future<Response> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    return await _dio.get(
      '/events/nearby',
      queryParameters: {'lat': latitude, 'lng': longitude, 'radius': radiusKm},
    );
  }

  /// Get event by ID
  Future<Response> getEventById(String eventId) async {
    return await _dio.get('/events/$eventId');
  }

  /// Create a new event
  Future<Response> createEvent({
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
    return await _dio.post(
      '/events',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'dateTime': dateTime.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
        if (category != null) 'category': category,
        if (image != null) 'image': image,
      },
    );
  }

  /// Update an event
  Future<Response> updateEvent({
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
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (location != null) data['location'] = location;
    if (dateTime != null) data['dateTime'] = dateTime.toIso8601String();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (maxParticipants != null) data['maxParticipants'] = maxParticipants;
    if (category != null) data['category'] = category;
    if (image != null) data['image'] = image;

    return await _dio.put('/events/$eventId', data: data);
  }

  /// Delete an event
  Future<Response> deleteEvent(String eventId) async {
    return await _dio.delete('/events/$eventId');
  }

  /// Join a regular event
  Future<Response> joinEvent(String eventId) async {
    return await _dio.post('/events/$eventId/attend');
  }

  /// Join a speed dating event
  Future<Response> joinSpeedDatingEvent(String eventId) async {
    return await _dio.post('/speed-dating/events/$eventId/join');
  }

  /// Leave a regular event
  Future<Response> leaveEvent(String eventId) async {
    return await _dio.delete('/events/$eventId/attend');
  }

  /// Leave a speed dating event
  Future<Response> leaveSpeedDatingEvent(String eventId) async {
    return await _dio.delete('/speed-dating/events/$eventId/join');
  }

  /// Get event participants
  Future<Response> getEventParticipants(String eventId) async {
    return await _dio.get('/events/$eventId/participants');
  }

  /// Get user's events
  Future<Response> getUserEvents() async {
    return await _dio.get('/events/my-events');
  }

  /// Send event message
  Future<Response> sendEventMessage({
    required String eventId,
    required String content,
  }) async {
    return await _dio.post(
      '/events/$eventId/messages',
      data: {'content': content},
    );
  }

  /// Get event messages/chat history
  Future<Response> getEventMessages({
    required String eventId,
    int page = 1,
    int limit = 50,
  }) async {
    return await _dio.get(
      '/events/$eventId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// Update RSVP status
  Future<Response> updateEventRSVP({
    required String eventId,
    required String status,
  }) async {
    return await _dio.patch('/events/$eventId/rsvp', data: {'status': status});
  }

  /// Get event categories
  Future<Response> getEventCategories() async {
    return await _dio.get('/events/categories');
  }

  /// Get popular events
  Future<Response> getPopularEvents() async {
    return await _dio.get('/events/popular');
  }

  // ==================== GROUP CHAT ENDPOINTS ====================

  /// Create a new group conversation
  Future<Response> createGroup({
    required String name,
    String? description,
    required String groupType,
    required List<String> participantIds,
    required String joinPolicy,
  }) async {
    return await _dio.post(
      '/group-chat/create',
      data: {
        'name': name,
        if (description != null) 'description': description,
        'groupType': groupType,
        'participantIds': participantIds,
        'joinPolicy': joinPolicy,
      },
    );
  }

  /// Get all groups the current user belongs to
  Future<Response> getUserGroups() async {
    return await _dio.get('/group-chat/user-groups');
  }

  /// Get group details
  Future<Response> getGroupDetails(String conversationId) async {
    return await _dio.get('/group-chat/$conversationId');
  }

  /// Create a live session (Monkey.app style)
  /// Backend automatically creates a conversation, no conversationId needed
  Future<Response> createLiveSession({
    required String title,
    String? description,
    int? maxParticipants,
    bool requireApproval = true,
    String sessionType = 'CASUAL_CHAT',
    int durationMinutes = 30,
    bool allowVideo = true,
    bool allowAudio = true,
  }) async {
    return await _dio.post(
      '/group-chat/live-session/create',
      data: {
        'title': title,
        if (description != null) 'description': description,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
        'requireApproval': requireApproval,
        'sessionType': sessionType,
        'durationMinutes': durationMinutes,
        'allowVideo': allowVideo,
        'allowAudio': allowAudio,
      },
    );
  }

  /// Get all active live sessions
  Future<Response> getActiveLiveSessions({String? groupType}) async {
    return await _dio.get(
      '/group-chat/live-sessions/active',
      queryParameters: groupType != null ? {'groupType': groupType} : null,
    );
  }

  /// Join a live session
  Future<Response> joinLiveSession({
    required String sessionId,
    String? message,
  }) async {
    return await _dio.post(
      '/group-chat/live-session/$sessionId/join',
      data: {if (message != null) 'message': message},
    );
  }

  /// Get pending join requests for a session (for host)
  Future<Response> getPendingJoinRequests(String sessionId) async {
    return await _dio.get('/group-chat/join-requests/pending/$sessionId');
  }

  /// Approve a join request
  Future<Response> approveJoinRequest(String requestId) async {
    return await _dio.patch('/group-chat/join-request/$requestId/approve');
  }

  /// Reject a join request
  Future<Response> rejectJoinRequest({
    required String requestId,
    String? reason,
  }) async {
    return await _dio.patch(
      '/group-chat/join-request/$requestId/reject',
      data: {if (reason != null) 'reason': reason},
    );
  }

  /// Add participant to group
  Future<Response> addGroupParticipant({
    required String conversationId,
    required String userId,
  }) async {
    return await _dio.post(
      '/group-chat/participants/add',
      data: {'conversationId': conversationId, 'userId': userId},
    );
  }

  /// Remove participant from group
  Future<Response> removeGroupParticipant({
    required String targetUserId,
    required String conversationId,
    String? reason,
  }) async {
    return await _dio.post(
      '/group-chat/participants/$targetUserId/remove',
      data: {
        'conversationId': conversationId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Update group settings
  Future<Response> updateGroupSettings({
    required String conversationId,
    required Map<String, dynamic> settings,
  }) async {
    return await _dio.patch(
      '/group-chat/conversation/$conversationId/settings',
      data: settings,
    );
  }

  /// Change participant role
  Future<Response> changeParticipantRole({
    required String conversationId,
    required String targetUserId,
    required String role,
    String? reason,
  }) async {
    return await _dio.patch(
      '/group-chat/conversation/$conversationId/participants/$targetUserId/role',
      data: {'role': role, if (reason != null) 'reason': reason},
    );
  }

  /// Leave a group
  Future<Response> leaveGroup(String conversationId) async {
    return await _dio.post('/group-chat/conversation/$conversationId/leave');
  }

  /// Delete a group (owner only)
  Future<Response> deleteGroup(String conversationId) async {
    return await _dio.post('/group-chat/conversation/$conversationId/delete');
  }

  /// Search users to add to group
  Future<Response> searchUsersForGroup({
    required String conversationId,
    required String query,
  }) async {
    return await _dio.get(
      '/group-chat/conversation/$conversationId/search-users',
      queryParameters: {'query': query},
    );
  }

  /// Report inappropriate behavior in group
  Future<Response> reportGroup({
    required String reportedContentId,
    required String reportType,
    required String reason,
    String? details,
  }) async {
    return await _dio.post(
      '/group-chat/report',
      data: {
        'reportedContentId': reportedContentId,
        'reportType': reportType,
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
  }

  /// Generate RTC token for live session video call
  Future<Response> generateLiveSessionRtcToken({
    required String sessionId,
    bool audioOnly = false,
  }) async {
    return await _dio.post(
      '/group-chat/live-session/$sessionId/rtc-token',
      queryParameters: {'audioOnly': audioOnly.toString()},
    );
  }
}
