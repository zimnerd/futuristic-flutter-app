import 'dart:developer' as dev;
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// User statistics model
class UserStatistics {
  final int totalLikes;
  final int totalMatches;
  final int totalPasses;
  final int profileViews;
  final int messagesCount;
  final int likesReceived;
  final int superLikesReceived;
  final int superLikesSent;
  final double matchRate;
  final double responseRate;
  final Map<String, int> dailyActivity;
  final Map<String, int> ageDistribution;
  final Map<String, int> locationDistribution;

  const UserStatistics({
    required this.totalLikes,
    required this.totalMatches,
    required this.totalPasses,
    required this.profileViews,
    required this.messagesCount,
    required this.likesReceived,
    required this.superLikesReceived,
    required this.superLikesSent,
    required this.matchRate,
    required this.responseRate,
    required this.dailyActivity,
    required this.ageDistribution,
    required this.locationDistribution,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalLikes: json['likesSent'] as int? ?? json['totalLikes'] as int? ?? 0,
      totalMatches:
          json['matchesCount'] as int? ?? json['totalMatches'] as int? ?? 0,
      totalPasses: json['totalPasses'] as int? ?? 0,
      profileViews: json['profileViews'] as int? ?? 0,
      messagesCount: json['messagesCount'] as int? ?? 0,
      likesReceived: json['likesReceived'] as int? ?? 0,
      superLikesReceived: json['superLikesReceived'] as int? ?? 0,
      superLikesSent: json['superLikesSent'] as int? ?? 0,
      matchRate: (json['matchRate'] as num?)?.toDouble() ?? 0.0,
      responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0.0,
      dailyActivity: Map<String, int>.from(json['dailyActivity'] as Map? ?? {}),
      ageDistribution: Map<String, int>.from(json['ageDistribution'] as Map? ?? {}),
      locationDistribution: Map<String, int>.from(json['locationDistribution'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLikes': totalLikes,
      'totalMatches': totalMatches,
      'totalPasses': totalPasses,
      'profileViews': profileViews,
      'messagesCount': messagesCount,
      'likesReceived': likesReceived,
      'superLikesReceived': superLikesReceived,
      'superLikesSent': superLikesSent,
      'matchRate': matchRate,
      'responseRate': responseRate,
      'dailyActivity': dailyActivity,
      'ageDistribution': ageDistribution,
      'locationDistribution': locationDistribution,
    };
  }

  @override
  String toString() => 
      'UserStatistics(likes: $totalLikes, matches: $totalMatches, views: $profileViews)';
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

/// Service for handling user statistics
class StatisticsService {
  final ApiClient _apiClient;

  StatisticsService(this._apiClient);

  /// Get comprehensive user statistics
  Future<UserStatistics> getUserStatistics() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.statisticsUser,
      );

      if (response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        // Extract the nested 'data' object from the API response
        final statsData =
            responseData['data'] as Map<String, dynamic>? ?? responseData;
        return UserStatistics.fromJson(statsData);
      }

      // Return empty statistics if no data
      return const UserStatistics(
        totalLikes: 0,
        totalMatches: 0,
        totalPasses: 0,
        profileViews: 0,
        messagesCount: 0,
        likesReceived: 0,
        superLikesReceived: 0,
        superLikesSent: 0,
        matchRate: 0.0,
        responseRate: 0.0,
        dailyActivity: {},
        ageDistribution: {},
        locationDistribution: {},
      );
    } catch (e) {
      dev.log('Error fetching user statistics: $e', name: 'StatisticsService');
      rethrow;
    }
  }

  /// Calculate match success rate
  double calculateMatchRate(int matches, int totalLikes) {
    if (totalLikes == 0) return 0.0;
    return (matches / totalLikes) * 100;
  }

  /// Calculate profile completion score
  double calculateProfileCompletion({
    required bool hasPhoto,
    required bool hasBio,
    required bool hasInterests,
    required bool hasLocation,
    required bool hasAge,
  }) {
    int completedFields = 0;
    const totalFields = 5;

    if (hasPhoto) completedFields++;
    if (hasBio) completedFields++;
    if (hasInterests) completedFields++;
    if (hasLocation) completedFields++;
    if (hasAge) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  /// Get activity trend for the last 7 days
  List<MapEntry<String, int>> getWeeklyActivityTrend(Map<String, int> dailyActivity) {
    final now = DateTime.now();
    final weeklyData = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      weeklyData[dateKey] = dailyActivity[dateKey] ?? 0;
    }

    return weeklyData.entries.toList();
  }

  /// Calculate engagement level based on statistics
  String calculateEngagementLevel(UserStatistics stats) {
    double score = 0.0;

    // Profile views contribute 30%
    score += (stats.profileViews / 100) * 0.3;

    // Match rate contributes 40%
    score += (stats.matchRate / 100) * 0.4;

    // Response rate contributes 30%
    score += (stats.responseRate / 100) * 0.3;

    if (score >= 0.8) return 'Very High';
    if (score >= 0.6) return 'High';
    if (score >= 0.4) return 'Medium';
    if (score >= 0.2) return 'Low';
    return 'Very Low';
  }

  /// Get top performing days of the week
  List<String> getTopPerformingDays(Map<String, int> dailyActivity) {
    final dayTotals = <String, int>{
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    // Aggregate by day of week
    dailyActivity.forEach((date, activity) {
      try {
        final DateTime dateTime = DateTime.parse(date);
        final String dayName = _getDayName(dateTime.weekday);
        dayTotals[dayName] = (dayTotals[dayName] ?? 0) + activity;
      } catch (e) {
        dev.log('Error parsing date: $date', name: 'StatisticsService');
      }
    });

    // Sort by activity level
    final sortedDays = dayTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDays.take(3).map((entry) => entry.key).toList();
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  /// Format statistics for display
  Map<String, String> formatStatisticsForDisplay(UserStatistics stats) {
    return {
      // Main stats
      'totalMatches': stats.totalMatches.toString(),
      'totalLikes': stats.totalLikes.toString(),
      'likesReceived': stats.likesReceived.toString(),
      'likesSent': stats.totalLikes
          .toString(), // likesSent is the same as totalLikes
      'profileViews': stats.profileViews.toString(),
      'messagesCount': stats.messagesCount.toString(),

      // Super likes
      'superLikesReceived': stats.superLikesReceived.toString(),
      'superLikesSent': stats.superLikesSent.toString(),

      // Calculated stats
      'matchRate': '${stats.matchRate.toStringAsFixed(1)}%',
      'responseRate': '${stats.responseRate.toStringAsFixed(1)}%',
      'engagementLevel': calculateEngagementLevel(stats),
    };
  }
}