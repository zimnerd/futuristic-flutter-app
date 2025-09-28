import 'dart:math' as math;
import '../../../../data/models/heat_map_models.dart';
import '../../domain/models/map_cluster.dart';

/// Service for clustering heat map data points based on zoom level
class MapClusteringService {
  /// Cluster data points based on zoom level for privacy
  /// Ensures minimum cluster sizes to protect user privacy
  static List<MapCluster> clusterDataPoints(
    List<HeatMapDataPoint> dataPoints,
    double zoomLevel,
  ) {
    if (dataPoints.isEmpty) return [];

    // PRIVACY ENHANCEMENT: Calculate cluster radius with minimum for privacy
    // At high zoom levels, enforce minimum radius to prevent individual markers
    double baseRadius;
    if (zoomLevel <= 8) {
      baseRadius = 5000; // 5km for country/region level
    } else if (zoomLevel <= 12) {
      baseRadius = 2000; // 2km for city level
    } else if (zoomLevel <= 15) {
      baseRadius = 1000; // 1km for district level
    } else {
      baseRadius = 800; // Minimum 800m for privacy at street level
    }
    
    // Always enforce minimum privacy radius
    final double minPrivacyRadius = 500.0; // Minimum 500m radius for privacy
    final double clusterRadius = math.max(baseRadius, minPrivacyRadius);
    
    print(
      'MapClusteringService: Clustering ${dataPoints.length} points at zoom $zoomLevel',
    );
    print('MapClusteringService: Using privacy radius: ${clusterRadius}m');

    // Use existing clustering method with privacy-enhanced radius
    return _performClustering(dataPoints, clusterRadius);
  }

  /// Perform distance-based clustering with privacy and status grouping
  static List<MapCluster> _performClustering(
    List<HeatMapDataPoint> dataPoints, 
    double clusterRadiusMeters,
  ) {
    final clusters = <MapCluster>[];
    final processed = <bool>[];
    
    // Initialize processed array
    for (int i = 0; i < dataPoints.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < dataPoints.length; i++) {
      if (processed[i]) continue;

      final centerPoint = dataPoints[i];
      final clusterPoints = <HeatMapDataPoint>[centerPoint];
      processed[i] = true;

      // PRIVACY: Group by status to avoid mixing different user types
      final centerStatus = centerPoint.label ?? 'unknown';

      // Find nearby points to cluster (same status only for privacy)
      for (int j = i + 1; j < dataPoints.length; j++) {
        if (processed[j]) continue;

        final pointStatus = dataPoints[j].label ?? 'unknown';

        // Only cluster points with the same status (privacy requirement)
        if (pointStatus != centerStatus) continue;

        final distance = _calculateDistance(
          centerPoint.coordinates.latitude,
          centerPoint.coordinates.longitude,
          dataPoints[j].coordinates.latitude,
          dataPoints[j].coordinates.longitude,
        );

        if (distance <= clusterRadiusMeters) {
          clusterPoints.add(dataPoints[j]);
          processed[j] = true;
        }
      }

      // Create cluster - always create even for single points for consistent privacy
      final centerPosition = MapCluster.calculateCenter(clusterPoints);
      clusters.add(MapCluster(
        id: 'cluster_${clusters.length}_${centerPosition.latitude.toStringAsFixed(4)}_${centerPosition.longitude.toStringAsFixed(4)}',
        position: centerPosition,
        dataPoints: clusterPoints,
        count: clusterPoints.length,
        radius: clusterRadiusMeters,
      ));
    }

    print(
      'MapClusteringService: Created ${clusters.length} status-grouped clusters',
    );
    return clusters;
  }

  /// Calculate distance between two points in meters using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get cluster marker size based on count
  static double getClusterSize(int count) {
    if (count <= 5) return 40;
    if (count <= 10) return 50;
    if (count <= 25) return 60;
    if (count <= 50) return 70;
    return 80;
  }

  /// Get cluster color based on dominant status
  static String getClusterColor(String dominantStatus) {
    switch (dominantStatus.toLowerCase()) {
      case 'matched':
        return '#4CAF50'; // Green
      case 'liked_me':
      case 'likedme':
        return '#FF9800'; // Orange
      case 'unmatched':
      case 'available':
        return '#2196F3'; // Blue
      case 'passed':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
}