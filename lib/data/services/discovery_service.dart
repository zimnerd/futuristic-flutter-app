// cSpell:ignore Mila Camila Scarlett Zoey
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

/// Service for handling user discovery and swipe operations
///
/// Manages API calls for:
/// - Fetching discoverable users with filters
/// - Recording swipe actions (like, pass, super like)
/// - Managing boost features
/// - Handling undo functionality
class DiscoveryService {
  final ApiClient _apiClient;

  DiscoveryService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get discoverable users based on filters and preferences
  Future<List<UserProfile>> getDiscoverableUsers({
    DiscoveryFilters? filters,
    int offset = 0,
    int limit = 10,
    // bool reset = false, // Removed - backend doesn't support this parameter
  }) async {
    try {
      // Implement actual API call to backend
      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
        // 'reset': reset, // Removed - backend doesn't support this parameter
      };

      // Add filter parameters if provided
      if (filters != null) {
        if (filters.minAge != null) queryParams['minAge'] = filters.minAge;
        if (filters.maxAge != null) queryParams['maxAge'] = filters.maxAge;
        if (filters.maxDistance != null)
          queryParams['maxDistance'] = filters.maxDistance;
        if (filters.interests.isNotEmpty)
          queryParams['interests'] = filters.interests.join(',');
        if (filters.verifiedOnly)
          queryParams['verifiedOnly'] = filters.verifiedOnly;
        if (filters.premiumOnly)
          queryParams['premiumOnly'] = filters.premiumOnly;
        if (filters.recentlyActive)
          queryParams['recentlyActive'] = filters.recentlyActive;
      }

      final response = await _apiClient.get(
        ApiConstants.matchingSuggestions, // Updated to use new API constant
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> suggestionsJson = data['data'] ?? [];
      return suggestionsJson
          .map(
            (suggestion) =>
                _userProfileFromSuggestion(suggestion as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      // Throw error instead of falling back to mock data
      throw Exception('Failed to fetch discoverable users: $error');
    }
  }

  /// Record a swipe action and check for matches
  Future<SwipeResult> recordSwipeAction({
    required String targetUserId,
    required SwipeAction action,
  }) async {
    try {
      // Use correct API endpoints based on action
      final String endpoint;
      final Map<String, dynamic> data;

      if (action == SwipeAction.right || action == SwipeAction.up) {
        endpoint = ApiConstants.matchingLike; // Use /matching/like
        data = {
          'targetUserId': targetUserId,
          'likeType': action == SwipeAction.up ? 'SUPER_LIKE' : 'LIKE',
        };
      } else {
        endpoint = ApiConstants.matchingPass; // Use /matching/pass
        data = {'targetUserId': targetUserId};
      }

      final response = await _apiClient.post(endpoint, data: data);

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;
      final bool isMatch = responseData['match'] ?? false;
      final String? conversationId = responseData['conversationId'];

      return SwipeResult(
        isMatch: isMatch,
        targetUserId: targetUserId,
        action: action,
        conversationId: conversationId,
      );
    } catch (error) {
      // Throw error instead of falling back to mock logic
      throw Exception('Failed to record swipe action: $error');
    }
  }

  /// Undo the last swipe action (premium feature)
  Future<bool> undoLastSwipe() async {
    try {
      // Use the correct backend endpoint
      final response = await _apiClient.post(
        ApiConstants.matchingUndo,
        data: {},
      );

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;
      final bool canUndo = responseData['canUndo'] ?? false;
      return canUndo;
    } catch (error) {
      // Throw error instead of falling back to mock logic
      throw Exception('Failed to undo last swipe: $error');
    }
  }

  /// Activate boost feature to increase profile visibility
  Future<BoostResult> activateBoost() async {
    try {
      // Use dedicated boost endpoint
      final response = await _apiClient.post(
        ApiConstants.premiumBoost,
        data: {},
      );

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;
      final bool success = responseData['success'] ?? true;
      final int durationMinutes = responseData['durationMinutes'] ?? 30;
      final String startTimeStr =
          responseData['startTime'] ?? DateTime.now().toIso8601String();

      return BoostResult(
        success: success,
        duration: Duration(minutes: durationMinutes),
        startTime: DateTime.parse(startTimeStr),
      );
    } catch (error) {
      // Throw error instead of falling back to mock logic
      throw Exception('Failed to activate boost: $error');
    }
  }

  /// Check if user has available boosts
  Future<bool> hasAvailableBoosts() async {
    try {
      // Implement actual API call to backend
      final response = await _apiClient.get('/discovery/boosts/available');

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;
      final bool hasBoosts = responseData['hasBoosts'] ?? false;
      return hasBoosts;
    } catch (error) {
      // Throw error instead of falling back to mock logic
      throw Exception('Failed to check available boosts: $error');
    }
  }

  /// Get user's remaining super likes for today
  Future<int> getRemainingSuperLikes() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.matching}/super-likes/remaining',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!['remaining'] as int;
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (error) {
      // Throw error instead of falling back to mock data
      throw Exception('Failed to get remaining super likes: $error');
    }
  }

  /// Get users who liked the current user (premium feature)
  Future<List<UserProfile>> getWhoLikedYou({
    DiscoveryFilters? filters,
    int page = 1,
    int limit = 20,
    bool? superLikesOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      // Add filter parameters if provided
      if (superLikesOnly != null) {
        queryParams['superLikesOnly'] = superLikesOnly;
      }

      final response = await _apiClient.get(
        ApiConstants.matchingWhoLikedMe,
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> usersJson = data['data'] ?? [];

      return usersJson
          .map(
            (user) => _userProfileFromSuggestion(user as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch who liked you: $error');
    }
  }

  /// Convert suggestion JSON from API to UserProfile entity
  UserProfile _userProfileFromSuggestion(Map<String, dynamic> suggestion) {
    final user = suggestion['user'] as Map<String, dynamic>;
    final profile = user['profile'] as Map<String, dynamic>?;

    // Handle null or missing values safely
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();

    // Safely parse age with null check
    final ageValue = user['age'];
    final int age;
    if (ageValue == null) {
      age = 18; // Default age if null
    } else if (ageValue is int) {
      age = ageValue;
    } else if (ageValue is double) {
      age = ageValue.toInt();
    } else {
      age = int.tryParse(ageValue.toString()) ?? 18;
    }

    // Safely parse height with null check
    final heightValue = profile?['height'];
    final int? height;
    if (heightValue == null) {
      height = null;
    } else if (heightValue is int) {
      height = heightValue;
    } else if (heightValue is double) {
      height = heightValue.toInt();
    } else {
      height = int.tryParse(heightValue.toString());
    }

    // Create a UserProfile from the API suggestion structure
    return UserProfile(
      id: user['id'] as String,
      name: name.isNotEmpty ? name : 'Unknown User',
      age: age,
      bio: user['bio'] as String? ?? '',
      photos:
          (user['photos'] as List<dynamic>?)?.asMap().entries.map((entry) {
            final index = entry.key;
            final photo = entry.value;

            // Handle both string URLs (legacy) and Photo objects (new format)
            if (photo is String) {
              return ProfilePhoto(
                id: photo.hashCode.toString(),
                url: photo,
                order: index,
                isVerified: false,
              );
            } else if (photo is Map<String, dynamic>) {
              return ProfilePhoto(
                id: photo['id']?.toString() ?? photo['url'].hashCode.toString(),
                url:
                    photo['url'] as String? ??
                    photo['processedUrl'] as String? ??
                    '',
                order: photo['displayOrder'] as int? ?? index,
                blurhash: photo['blurhash'] as String?, // 🎯 Parse blurhash
                isMain: photo['isMain'] as bool? ?? (index == 0),
                isVerified: photo['verified'] as bool? ?? false,
                uploadedAt: photo['createdAt'] != null
                    ? DateTime.tryParse(photo['createdAt'] as String)
                    : null,
              );
            }

            // Fallback for unexpected formats
            return ProfilePhoto(
              id: photo.toString().hashCode.toString(),
              url: photo.toString(),
              order: index,
              isVerified: false,
            );
          }).toList() ??
          [],
      location: user['coordinates'] != null
          ? UserLocation(
              latitude: (user['coordinates']['latitude'] as num).toDouble(),
              longitude: (user['coordinates']['longitude'] as num).toDouble(),
              city: user['location']?.split(',').first?.trim(),
              country: user['location']?.split(',').last?.trim(),
              address: user['location'] as String?,
            )
          : UserLocation(
              latitude: 0.0,
              longitude: 0.0,
              city: user['location']?.split(',').first?.trim(),
              country: user['location']?.split(',').last?.trim(),
              address: user['location'] as String?,
            ),
      isVerified: user['verified'] as bool? ?? false,
      interests:
          (user['interests'] as List<dynamic>?)
              ?.map((interest) => interest as String)
              .toList() ??
          [],
      occupation: profile?['occupation'] as String?,
      education: profile?['education'] as String?,
      height: height,
      zodiacSign: null,
      lifestyle: <String, dynamic>{},
      preferences: <String, dynamic>{},
      lastActiveAt: user['lastActiveAt'] != null
          ? DateTime.parse(user['lastActiveAt'] as String)
          : user['lastActive'] != null
          ? DateTime.parse(user['lastActive'] as String)
          : null,
      distanceKm:
          suggestion['distanceKm'] as double? ??
          suggestion['distance'] as double? ??
          user['distanceKm'] as double? ??
          user['distance'] as double?,
    );
  }
}
