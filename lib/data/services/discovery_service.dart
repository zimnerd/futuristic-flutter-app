import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../domain/services/api_service.dart';
import 'api_service_impl.dart';

/// Service for handling user discovery and swipe operations
/// 
/// Manages API calls for:
/// - Fetching discoverable users with filters
/// - Recording swipe actions (like, pass, super like)
/// - Managing boost features
/// - Handling undo functionality
class DiscoveryService {
  final ApiService _apiService;
  
  DiscoveryService({ApiService? apiService}) 
    : _apiService = apiService ?? ApiServiceImpl();

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
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/discovery/users',
        queryParameters: queryParams,
      );
      
      final List<dynamic> usersJson = response.data?['users'] ?? [];
      return usersJson
          .map((json) => UserProfile.fromJson(json))
          .toList();
          
    } catch (error) {
      // Fallback to mock data for development if API fails
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      // Mock user data for development
      final mockUsers = _generateMockUsers(limit);
      
      return mockUsers.skip(offset).take(limit).toList();
    }
  }

  /// Record a swipe action and check for matches
  Future<SwipeResult> recordSwipeAction({
    required String targetUserId,
    required SwipeAction action,
  }) async {
    try {
      // Implement actual API call to backend
      final response = await _apiService.post<Map<String, dynamic>>(
        '/discovery/swipe',
        data: {
          'targetUserId': targetUserId,
          'action': action.name,
        },
      );
      
      final bool isMatch = response.data?['isMatch'] ?? false;
      
      return SwipeResult(
        isMatch: isMatch,
        targetUserId: targetUserId,
        action: action,
      );
    } catch (error) {
      // Fallback to mock logic for development
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Mock match detection (20% chance for likes, 40% for super likes)
      final isMatch = action == SwipeAction.right 
          ? DateTime.now().millisecond % 5 == 0 // 20% chance
          : action == SwipeAction.up
              ? DateTime.now().millisecond % 5 < 2 // 40% chance
              : false;
      
      return SwipeResult(
        isMatch: isMatch,
        targetUserId: targetUserId,
        action: action,
      );
    }
  }

  /// Undo the last swipe action (premium feature)
  Future<bool> undoLastSwipe() async {
    try {
      // Implement actual API call to backend
      final response = await _apiService.post<Map<String, dynamic>>(
        '/discovery/undo',
        data: {},
      );
      
      final bool canUndo = response.data?['success'] ?? false;
      return canUndo;
    } catch (error) {
      // Fallback to mock logic for development
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Mock undo availability (80% chance for premium users)
      final canUndo = DateTime.now().millisecond % 5 != 0; // 80% chance
      return canUndo;
    }
  }

    /// Activate boost feature to increase profile visibility
  Future<BoostResult> activateBoost() async {
    try {
      // Implement actual API call to backend
      final response = await _apiService.post<Map<String, dynamic>>(
        '/discovery/boost',
        data: {},
      );
      
      final bool success = response.data?['success'] ?? false;
      final int durationMinutes = response.data?['durationMinutes'] ?? 30;
      final String startTimeStr = response.data?['startTime'] ?? DateTime.now().toIso8601String();
      
      return BoostResult(
        success: success,
        duration: Duration(minutes: durationMinutes),
        startTime: DateTime.parse(startTimeStr),
      );
    } catch (error) {
      // Fallback to mock logic for development
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock boost activation (90% success rate)
      final success = DateTime.now().millisecond % 10 != 0; // 90% chance
      
      return BoostResult(
        success: success,
        duration: const Duration(minutes: 30),
        startTime: DateTime.now(),
      );
    }
  }

  /// Check if user has available boosts
  Future<bool> hasAvailableBoosts() async {
    try {
      // Implement actual API call to backend
      final response = await _apiService.get<Map<String, dynamic>>(
        '/discovery/boosts/available',
      );
      
      final bool hasBoosts = response.data?['hasBoosts'] ?? false;
      return hasBoosts;
    } catch (error) {
      // Fallback to mock logic for development
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Mock boost availability (70% chance)
      return DateTime.now().millisecond % 10 < 7; // 70% chance
    }
  }

  /// Get user's remaining super likes for today
  Future<int> getRemainingSuperLikes() async {
    try {
      // TODO: Implement actual API call to backend
      await Future.delayed(const Duration(milliseconds: 200));
      
      return 3; // Mock - 3 super likes remaining
    } catch (error) {
      throw Exception('Failed to get super like count: $error');
    }
  }

  /// Generate mock user data for development
  List<UserProfile> _generateMockUsers(int count) {
    final names = [
      'Emma', 'Olivia', 'Ava', 'Isabella', 'Sophia', 'Charlotte', 'Mia', 'Amelia',
      'Harper', 'Evelyn', 'Abigail', 'Emily', 'Elizabeth', 'Mila', 'Ella', 'Avery',
      'Sofia', 'Camila', 'Aria', 'Scarlett', 'Victoria', 'Madison', 'Luna', 'Grace',
      'Chloe', 'Penelope', 'Layla', 'Riley', 'Zoey', 'Nora'
    ];
    
    final interests = [
      'Photography', 'Travel', 'Fitness', 'Music', 'Art', 'Cooking', 'Reading',
      'Dancing', 'Hiking', 'Gaming', 'Movies', 'Coffee', 'Dogs', 'Cats', 'Yoga'
    ];

    return List.generate(count, (index) {
      final name = names[index % names.length];
      final age = 22 + (index % 15); // Ages 22-36
      final distance = 1.0 + (index % 20); // 1-20 km away
      
      return UserProfile(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch + index}',
        name: name,
        age: age,
        bio: 'Living my best life! Love ${interests[index % interests.length].toLowerCase()} and exploring new places. Looking for genuine connections.',
        photos: [
          ProfilePhoto(
            id: 'photo_${index}_1',
            url: 'https://picsum.photos/400/600?random=${index + 1}',
            order: 0,
          ),
          ProfilePhoto(
            id: 'photo_${index}_2',
            url: 'https://picsum.photos/400/600?random=${index + 100}',
            order: 1,
          ),
          ProfilePhoto(
            id: 'photo_${index}_3',
            url: 'https://picsum.photos/400/600?random=${index + 200}',
            order: 2,
          ),
        ],
        location: UserLocation(
          latitude: 37.7749 + (index * 0.01), // Mock SF coordinates
          longitude: -122.4194 + (index * 0.01),
          city: 'Mock City',
          country: 'Mock Country',
        ),
        distanceKm: distance,
        interests: interests.take(3 + (index % 4)).toList(),
        isVerified: index % 3 == 0,
        lastActiveAt: DateTime.now().subtract(Duration(hours: index % 24)),
      );
    });
  }
}
