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
    bool reset = false,
  }) async {
    try {
      // Implement actual API call to backend
      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
        'reset': reset,
      };
      
      // Add filter parameters if provided
      if (filters != null) {
        if (filters.minAge != null) queryParams['minAge'] = filters.minAge;
        if (filters.maxAge != null) queryParams['maxAge'] = filters.maxAge;
        if (filters.maxDistance != null) queryParams['maxDistance'] = filters.maxDistance;
        if (filters.interests.isNotEmpty) queryParams['interests'] = filters.interests.join(',');
        if (filters.verifiedOnly) queryParams['verifiedOnly'] = filters.verifiedOnly;
        if (filters.premiumOnly) queryParams['premiumOnly'] = filters.premiumOnly;
        if (filters.recentlyActive) queryParams['recentlyActive'] = filters.recentlyActive;
      }
      
      final response = await _apiClient.get(
        ApiConstants.discover, // This should be /matching/suggestions
        queryParameters: queryParams,
      );
      
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final List<dynamic> usersJson = data['profiles'] ?? data['users'] ?? [];
      return usersJson
          .map((json) => UserProfile.fromJson(json))
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
        endpoint = ApiConstants.swipe;
        data = {'targetUserId': targetUserId, 'action': 'like'};
      } else {
        endpoint = ApiConstants.swipe;
        data = {'targetUserId': targetUserId, 'action': 'pass'};
      }
      
      final response = await _apiClient.post(
        endpoint,
        data: data,
      );
      
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
      // Implement actual API call to backend
      final response = await _apiClient.post(
        '/discovery/undo',
        data: {},
      );
      
      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;
      final bool canUndo = responseData['success'] ?? false;
      return canUndo;
    } catch (error) {
      // Throw error instead of falling back to mock logic
      throw Exception('Failed to undo last swipe: $error');
    }
  }

    /// Activate boost feature to increase profile visibility
  Future<BoostResult> activateBoost() async {
    try {
      // Implement actual API call to backend
      final response = await _apiClient.post(
        '/discovery/boost',
        data: {},
      );
      
      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;
      final bool success = responseData['success'] ?? false;
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
      final response = await _apiClient.get(
        '/discovery/boosts/available',
      );
      
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
        '/api/discovery/super-likes/remaining',
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
}
