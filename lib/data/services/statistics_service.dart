import '../../domain/services/api_service.dart';
import '../models/statistics_model.dart';
import 'api_service_impl.dart';

class UserStatistics {
  final int profileViews;
  final int likesReceived;
  final int likesSent;
  final int matchesCount;
  final int messagesCount;
  final int superLikesReceived;
  final int superLikesSent;

  const UserStatistics({
    required this.profileViews,
    required this.likesReceived,
    required this.likesSent,
    required this.matchesCount,
    required this.messagesCount,
    required this.superLikesReceived,
    required this.superLikesSent,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      profileViews: json['profileViews'] ?? 0,
      likesReceived: json['likesReceived'] ?? 0,
      likesSent: json['likesSent'] ?? 0,
      matchesCount: json['matchesCount'] ?? 0,
      messagesCount: json['messagesCount'] ?? 0,
      superLikesReceived: json['superLikesReceived'] ?? 0,
      superLikesSent: json['superLikesSent'] ?? 0,
    );
  }
}

class HeatmapData {
  final double latitude;
  final double longitude;
  final int count;
  final String status; // 'matched', 'liked_me', 'unmatched', 'passed'

  const HeatmapData({
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.status,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
      status: json['status'] ?? 'unmatched',
    );
  }
}

class LocationCoverageData {
  final LocationCenter center;
  final double radius;
  final UserCounts userCounts;

  const LocationCoverageData({
    required this.center,
    required this.radius,
    required this.userCounts,
  });

  factory LocationCoverageData.fromJson(Map<String, dynamic> json) {
    return LocationCoverageData(
      center: LocationCenter.fromJson(json['center'] ?? {}),
      radius: json['radius']?.toDouble() ?? 0.0,
      userCounts: UserCounts.fromJson(json['userCounts'] ?? {}),
    );
  }
}

class LocationCenter {
  final double latitude;
  final double longitude;

  const LocationCenter({
    required this.latitude,
    required this.longitude,
  });

  factory LocationCenter.fromJson(Map<String, dynamic> json) {
    return LocationCenter(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }
}

class UserCounts {
  final int matched;
  final int likedMe;
  final int unmatched;
  final int passed;

  const UserCounts({
    required this.matched,
    required this.likedMe,
    required this.unmatched,
    required this.passed,
  });

  factory UserCounts.fromJson(Map<String, dynamic> json) {
    return UserCounts(
      matched: json['matched'] ?? 0,
      likedMe: json['likedMe'] ?? 0,
      unmatched: json['unmatched'] ?? 0,
      passed: json['passed'] ?? 0,
    );
  }

  int get total => matched + likedMe + unmatched + passed;
}

class StatisticsService {
  final ApiService _apiService;

  StatisticsService([ApiService? apiService]) : _apiService = apiService ?? ApiServiceImpl();

  /// Get current user's statistics
  Future<UserStatistics> getUserStatistics() async {
    try {
      final response = await _apiService.get('/statistics/me');
      return UserStatistics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load user statistics: $e');
    }
  }

  /// Get statistics with period filter (for compatibility with StatisticsScreen)
  Future<StatisticsModel> getStatistics(String period) async {
    try {
      final response = await _apiService.get('/statistics/me', queryParameters: {'period': period});
      return StatisticsModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  /// Get heatmap data for location visualization
  Future<List<HeatmapData>> getHeatmapData({int? radiusKm}) async {
    try {
      final queryParams = radiusKm != null ? {'radius': radiusKm.toString()} : null;
      final response = await _apiService.get(
        '/statistics/heatmap',
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data ?? [];
      return data.map((item) => HeatmapData.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load heatmap data: $e');
    }
  }

  /// Get location coverage data for map display
  Future<LocationCoverageData> getLocationCoverage({int? radiusKm}) async {
    try {
      final queryParams = radiusKm != null ? {'radius': radiusKm.toString()} : null;
      final response = await _apiService.get(
        '/statistics/location-coverage',
        queryParameters: queryParams,
      );
      
      return LocationCoverageData.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load location coverage: $e');
    }
  }

  /// Calculate match rate percentage
  double calculateMatchRate(UserStatistics stats) {
    if (stats.likesSent == 0) return 0.0;
    return (stats.matchesCount / stats.likesSent) * 100;
  }

  /// Calculate like back rate percentage
  double calculateLikeBackRate(UserStatistics stats) {
    if (stats.likesReceived == 0) return 0.0;
    return (stats.matchesCount / stats.likesReceived) * 100;
  }

  /// Get engagement score based on various metrics
  double calculateEngagementScore(UserStatistics stats) {
    // Simple engagement score calculation
    final profileScore = stats.profileViews * 0.1;
    final likesScore = stats.likesReceived * 2;
    final matchesScore = stats.matchesCount * 5;
    final messagesScore = stats.messagesCount * 3;
    final superLikesScore = stats.superLikesReceived * 10;
    
    return profileScore + likesScore + matchesScore + messagesScore + superLikesScore;
  }

  /// Get user activity level based on statistics
  String getActivityLevel(UserStatistics stats) {
    final engagementScore = calculateEngagementScore(stats);
    
    if (engagementScore >= 1000) return 'Very Active';
    if (engagementScore >= 500) return 'Active';
    if (engagementScore >= 200) return 'Moderate';
    if (engagementScore >= 50) return 'Low';
    return 'New User';
  }

  /// Format statistics for display
  Map<String, dynamic> formatStatisticsForDisplay(UserStatistics stats) {
    return {
      'profileViews': {
        'value': stats.profileViews,
        'label': 'Profile Views',
        'icon': '👀',
      },
      'likesReceived': {
        'value': stats.likesReceived,
        'label': 'People Who Liked Me',
        'icon': '❤️',
      },
      'likesSent': {
        'value': stats.likesSent,
        'label': 'People I Liked',
        'icon': '👍',
      },
      'matchesCount': {
        'value': stats.matchesCount,
        'label': 'Mutual Matches',
        'icon': '✨',
      },
      'messagesCount': {
        'value': stats.messagesCount,
        'label': 'Messages Sent',
        'icon': '💬',
      },
      'superLikesReceived': {
        'value': stats.superLikesReceived,
        'label': 'Super Likes Received',
        'icon': '⭐',
      },
      'matchRate': {
        'value': '${calculateMatchRate(stats).toStringAsFixed(1)}%',
        'label': 'Match Rate',
        'icon': '📊',
      },
      'activityLevel': {
        'value': getActivityLevel(stats),
        'label': 'Activity Level',
        'icon': '🔥',
      },
    };
  }
}