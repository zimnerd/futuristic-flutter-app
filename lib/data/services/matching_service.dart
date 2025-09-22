import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/user_profile.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';

/// Service for matching operations that matches BLoC expectations
class MatchingService {
  final ApiClient _apiClient;

  MatchingService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get potential matches for current user
  Future<List<UserProfile>> getPotentialMatches({
    int limit = 10,
    int offset = 0,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (filters != null) ...filters,
      };

      final response = await _apiClient.get(
        ApiConstants.matchingSuggestions,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final suggestions = data['data'] as List<dynamic>;

      return suggestions
          .map(
            (suggestion) =>
                _userProfileFromSuggestion(suggestion as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Swipe on a profile (like or pass)
  Future<Map<String, dynamic>> swipeProfile({
    required String profileId,
    required bool isLike,
  }) async {
    try {
      final String endpoint;
      final Map<String, dynamic> data;

      if (isLike) {
        endpoint = ApiConstants.matchingLike; // Use /matching/like
        data = {'targetUserId': profileId, 'likeType': 'LIKE'};
      } else {
        endpoint = ApiConstants.matchingPass; // Use /matching/pass
        data = {'targetUserId': profileId};
      }
      
      final response = await _apiClient.post(endpoint, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get user's matches (legacy - returns UserProfile)
  Future<List<UserProfile>> getUserMatches({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.matchingMatches,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final matches = data['data'] as List<dynamic>?;

      if (matches == null) {
        return [];
      }

      return matches
          .map(
            (match) => _userProfileFromMatchJson(match as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a specific profile
  Future<UserProfile> getProfile(String profileId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.users}/$profileId');
      return _userProfileFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Report a profile
  Future<void> reportProfile({
    required String profileId,
    required String reason,
    String? description,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.reportsCreate,
        data: {
          'profileId': profileId,
          'reason': reason,
          'description': description,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Block a profile
  Future<void> blockProfile(String profileId) async {
    try {
      await _apiClient.post(
        ApiConstants.usersBlock,
        data: {'profileId': profileId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unblock a profile
  Future<void> unblockProfile(String profileId) async {
    try {
      await _apiClient.delete('${ApiConstants.usersBlock}/$profileId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convert JSON to UserProfile entity
  UserProfile _userProfileFromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bio: json['bio'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>?)
              ?.map((photo) => _profilePhotoFromJson(photo as Map<String, dynamic>))
              .toList() ??
          [],
      location: _userLocationFromJson(json['location'] as Map<String, dynamic>),
      isVerified: json['isVerified'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((interest) => interest as String)
              .toList() ??
          [],
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      height: json['height'] as int?,
      zodiacSign: json['zodiacSign'] as String?,
      lifestyle: json['lifestyle'] as Map<String, dynamic>? ?? {},
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      distanceKm: json['distanceKm']?.toDouble(),
    );
  }

  /// Convert suggestion JSON from API to UserProfile entity
  UserProfile _userProfileFromSuggestion(Map<String, dynamic> suggestion) {
    final user = suggestion['user'] as Map<String, dynamic>;
    final profile = user['profile'] as Map<String, dynamic>?;

    // Create a combined user object for the existing parser
    final combinedUser = <String, dynamic>{
      'id': user['id'],
      'name': '${user['firstName']} ${user['lastName']}'.trim(),
      'age': user['age'],
      'bio': user['bio'] ?? '',
      'photos':
          (user['photos'] as List<dynamic>?)
              ?.map(
                (photo) => {
                  'id': photo.hashCode.toString(),
                  'url': photo as String,
                  'order': 0,
                  'isVerified': false,
                },
              )
              .toList() ??
          [],
      'location': user['coordinates'] != null
          ? {
              'latitude': user['coordinates']['latitude'],
              'longitude': user['coordinates']['longitude'],
              'city': user['location']?.split(',').first?.trim(),
              'country': user['location']?.split(',').last?.trim(),
              'address': user['location'],
            }
          : {
              'latitude': 0.0,
              'longitude': 0.0,
              'city': user['location']?.split(',').first?.trim(),
              'country': user['location']?.split(',').last?.trim(),
              'address': user['location'],
            },
      'isVerified': user['verified'] ?? false,
      'interests': user['interests'] ?? [],
      'occupation': profile?['occupation'],
      'education': profile?['education'],
      'height': profile?['height'],
      'zodiacSign': null,
      'lifestyle': <String, dynamic>{},
      'preferences': <String, dynamic>{},
      'lastActiveAt': user['lastActive'],
      'distanceKm': null,
    };

    return _userProfileFromJson(combinedUser);
  }

  /// Convert JSON to ProfilePhoto entity
  ProfilePhoto _profilePhotoFromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }

  /// Convert JSON to UserLocation entity
  UserLocation _userLocationFromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      address: json['address'] as String?,
    );
  }

  /// Convert match JSON from API to UserProfile entity
  UserProfile _userProfileFromMatchJson(Map<String, dynamic> matchJson) {
    final user = matchJson['user'] as Map<String, dynamic>;

    // Create a combined user object for the existing parser
    final combinedUser = <String, dynamic>{
      'id': user['id'],
      'name': '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      'age': user['age'],
      'bio': user['bio'] ?? '',
      'photos':
          (user['photos'] as List<dynamic>?)
              ?.map(
                (photo) => {
                  'id': photo.hashCode.toString(),
                  'url': photo as String,
                  'order': 0,
                  'isVerified': false,
                },
              )
              .toList() ??
          [],
      'location': user['coordinates'] != null
          ? {
              'latitude': user['coordinates']['lat'] ?? 0.0,
              'longitude': user['coordinates']['lng'] ?? 0.0,
              'city': user['location'],
              'country': 'Unknown',
              'address': user['location'],
            }
          : {
              'latitude': 0.0,
              'longitude': 0.0,
              'city': 'Unknown',
              'country': 'Unknown',
              'address': 'Unknown',
            },
      'isVerified': user['verified'] ?? false,
      'interests':
          (user['interests'] as List<dynamic>?)
              ?.map((interest) => interest as String)
              .toList() ??
          [],
      'occupation': null,
      'education': null,
      'height': null,
      'zodiacSign': null,
      'lifestyle': <String, dynamic>{},
      'preferences': <String, dynamic>{},
      'lastActiveAt': user['updatedAt'],
      'distanceKm': null,
    };

    return _userProfileFromJson(combinedUser);
  }

  /// Handle Dio errors and convert them to meaningful exceptions
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Request timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network settings.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'An error occurred';
        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized: Please login again');
          case 403:
            return Exception('Forbidden: $message');
          case 404:
            return Exception('Not found: $message');
          case 429:
            return Exception('Too many requests. Please try again later.');
          case 500:
            return Exception('Server error. Please try again later.');
          default:
            return Exception('HTTP $statusCode: $message');
        }
      default:
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }

  // Extended methods for new MatchBloc functionality

  /// Get matches with status filtering for MatchBloc
  Future<List<MatchModel>> getMatches({
    String? status,
    int? limit,
    int offset = 0,
    bool excludeWithConversations = false,
  }) async {
    try {
      // Get current user ID once at the beginning
      final currentUserId = await _apiClient.getCurrentUserId() ?? '';
      
      print('🔍 MatchingService: Getting matches with excludeWithConversations=$excludeWithConversations');
      
      final response = await _apiClient.getMatches(
        limit: limit ?? 20,
        offset: offset,
        excludeWithConversations: excludeWithConversations,
      );

      final data = response.data as Map<String, dynamic>;
      final matches = data['data'] as List<dynamic>?;

      if (matches == null) {
        print('🔍 MatchingService: No matches data returned');
        return [];
      }

      print('🔍 MatchingService: Received ${matches.length} matches from API');

      List<MatchModel> matchModels = matches
          .map(
            (match) =>
                _matchModelFromApiResponse(
              match as Map<String, dynamic>,
              currentUserId,
            ),
          )
          .toList();

      // Apply client-side status filtering if needed
      if (status != null) {
        matchModels = matchModels.where((match) {
          // Map various status values to backend statuses
          switch (status.toLowerCase()) {
            case 'accepted':
            case 'mutual':
            case 'matched':
              return match.status == 'matched' || match.status == 'mutual';
            case 'pending':
              return match.status == 'pending';
            case 'expired':
              return match.status == 'expired';
            case 'rejected':
              return match.status == 'rejected';
            default:
              return true; // Return all if unknown status
          }
        }).toList();
      }

      return matchModels;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get match suggestions for discovery
  Future<List<UserModel>> getMatchSuggestions({
    int limit = 10,
    bool useAI = false,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'useAI': useAI,
        if (filters != null) ...filters,
      };

      final response = await _apiClient.get(
        ApiConstants.matchingSuggestions,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final suggestions =
          data['suggestions'] ?? data['profiles'] as List<dynamic>;

      return suggestions
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a match (like someone)
  Future<MatchModel> createMatch({
    required String targetUserId,
    bool isSuper = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.matchingLike, // Use /matching/like
        data: {
          'targetUserId': targetUserId,
          'likeType': isSuper ? 'SUPER_LIKE' : 'LIKE',
        },
      );

      final data = response.data as Map<String, dynamic>;
      return MatchModel.fromJson(data['match'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Accept a pending match
  Future<MatchModel> acceptMatch(String matchId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.matchingMatches}/$matchId/accept',
      );

      final data = response.data as Map<String, dynamic>;
      return MatchModel.fromJson(data['match'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Reject a pending match
  Future<void> rejectMatch(String matchId) async {
    try {
      await _apiClient.patch('${ApiConstants.matchingMatches}/$matchId/reject');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unmatch with a user
  Future<void> unmatchUser(String matchId) async {
    try {
      await _apiClient.delete('${ApiConstants.matchingMatches}/$matchId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get detailed match information
  Future<MatchModel> getMatchDetails(String matchId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.matchingMatches}/$matchId',
      );

      final data = response.data as Map<String, dynamic>;
      return MatchModel.fromJson(data['match'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update match status
  Future<MatchModel> updateMatchStatus({
    required String matchId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.matchingMatches}/$matchId/status',
        data: {'status': status},
      );

      final data = response.data as Map<String, dynamic>;
      return MatchModel.fromJson(data['match'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Rewind/undo the last swipe action (premium feature)
  Future<Map<String, dynamic>> undoLastSwipe() async {
    try {
      final response = await _apiClient.post(ApiConstants.matchingUndo);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Boost profile for increased visibility (premium feature)
  Future<Map<String, dynamic>> boostProfile() async {
    try {
      // Use dedicated boost endpoint
      final response = await _apiClient.post(ApiConstants.premiumBoost);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convert API match response to MatchModel 
  /// The API returns match entries with nested user objects, not MatchModel structure
  MatchModel _matchModelFromApiResponse(
    Map<String, dynamic> apiMatch,
    String currentUserId,
  ) {
    final user = apiMatch['user'] as Map<String, dynamic>?;
    final userId = user?['id'] as String? ?? '';
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final photos = user?['photos'] as List<dynamic>? ?? [];
    final primaryPhoto = photos.isNotEmpty ? photos.first as String : '';

    // Store user data in matchReasons for UI access (temporary solution)
    final enrichedMatchReasons = <String, dynamic>{
      'user': {
        'id': userId,
        'name': '$firstName $lastName'.trim(),
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': primaryPhoto,
        'photos': photos,
        'age': user?['age'],
        'bio': user?['bio'],
        'interests': user?['interests'],
      },
    };

    // Create a simplified MatchModel from the API response
    // Since the API doesn't return full MatchModel data, we'll simulate it
    return MatchModel(
      id: apiMatch['id'] as String? ?? '',
      user1Id: currentUserId, // Use actual current user ID
      user2Id: userId, // The matched user
      isMatched: true, // If it's in matches, it's matched
      compatibilityScore: 0.85, // Default score since API doesn't provide it
      matchReasons: enrichedMatchReasons, // Store user data here
      status: 'matched', // Default to matched status
      matchedAt: DateTime.now(), // Use current time as fallback
      createdAt: DateTime.now(), // Use current time as fallback
      updatedAt: DateTime.now(), // Use current time as fallback
    );
  }
}
