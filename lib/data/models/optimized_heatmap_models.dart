/// Models for optimized heatmap clustering
/// Designed to handle thousands of users efficiently
library;

class OptimizedClusterData {
  final String id;
  final double latitude;
  final double longitude;
  final int userCount;
  final double radius;
  final int densityScore;
  final double avgAge;
  final Map<String, dynamic>? genderDistribution;
  final Map<String, dynamic>? ageDistribution;
  final Map<String, int>?
  statusBreakdown; // matched, liked_me, unmatched, passed

  const OptimizedClusterData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.userCount,
    required this.radius,
    required this.densityScore,
    required this.avgAge,
    this.genderDistribution,
    this.ageDistribution,
    this.statusBreakdown,
  });

  factory OptimizedClusterData.fromJson(Map<String, dynamic> json) {
    return OptimizedClusterData(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      userCount: json['userCount'] as int,
      radius:
          (json['radius'] as num?)?.toDouble() ??
          100.0, // Default radius if not provided
      densityScore: json['densityScore'] as int? ?? 0,
      avgAge: (json['avgAge'] as num?)?.toDouble() ?? 0.0,
      genderDistribution: json['genderDistribution'] as Map<String, dynamic>?,
      ageDistribution: json['ageDistribution'] as Map<String, dynamic>?,
      statusBreakdown: json['statusBreakdown'] != null
          ? Map<String, int>.from(json['statusBreakdown'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'userCount': userCount,
      'radius': radius,
      'densityScore': densityScore,
      'avgAge': avgAge,
      'genderDistribution': genderDistribution,
      'ageDistribution': ageDistribution,
    };
  }
}

class PerformanceMetrics {
  final int queryTimeMs;
  final int clusteringTimeMs;
  final int totalUsers;
  final int clustersGenerated;

  const PerformanceMetrics({
    required this.queryTimeMs,
    required this.clusteringTimeMs,
    this.totalUsers = 0,
    this.clustersGenerated = 0,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      queryTimeMs: json['queryTimeMs'] as int? ?? 0,
      clusteringTimeMs: json['clusteringTimeMs'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
      clustersGenerated: json['clustersGenerated'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queryTimeMs': queryTimeMs,
      'clusteringTimeMs': clusteringTimeMs,
      'totalUsers': totalUsers,
      'clustersGenerated': clustersGenerated,
    };
  }

  /// Total processing time in milliseconds
  int get totalTimeMs => queryTimeMs + clusteringTimeMs;

  /// Performance rating (0-10, higher is better)
  int get performanceRating {
    if (totalTimeMs < 100) return 10;
    if (totalTimeMs < 200) return 8;
    if (totalTimeMs < 500) return 6;
    if (totalTimeMs < 1000) return 4;
    if (totalTimeMs < 2000) return 2;
    return 1;
  }
}

class OptimizedHeatmapResponse {
  final List<OptimizedClusterData> clusters;
  final PerformanceMetrics performance;
  final int totalUsers;

  const OptimizedHeatmapResponse({
    required this.clusters,
    required this.performance,
    required this.totalUsers,
  });

  factory OptimizedHeatmapResponse.fromJson(Map<String, dynamic> json) {
    final clusters =
        (json['clusters'] as List?)
            ?.map(
              (e) => OptimizedClusterData.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    final performance = json['performance'] != null
        ? PerformanceMetrics.fromJson(
            json['performance'] as Map<String, dynamic>,
          )
        : const PerformanceMetrics(queryTimeMs: 0, clusteringTimeMs: 0);

    return OptimizedHeatmapResponse(
      clusters: clusters,
      performance: performance,
      totalUsers: json['totalUsers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clusters': clusters.map((e) => e.toJson()).toList(),
      'performance': performance.toJson(),
      'totalUsers': totalUsers,
    };
  }

  /// Check if response indicates good performance
  bool get isPerformant => performance.performanceRating >= 6;

  /// Get the most populated cluster
  OptimizedClusterData? get mostPopulatedCluster {
    if (clusters.isEmpty) return null;
    return clusters.reduce((a, b) => a.userCount > b.userCount ? a : b);
  }

  /// Get clusters sorted by population (descending)
  List<OptimizedClusterData> get clustersByPopulation {
    final sorted = List<OptimizedClusterData>.from(clusters);
    sorted.sort((a, b) => b.userCount.compareTo(a.userCount));
    return sorted;
  }
}
