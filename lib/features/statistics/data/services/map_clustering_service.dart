import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/heat_map_models.dart';
import '../../domain/models/map_cluster.dart';

/// Service for clustering heat map data points based on zoom level
class MapClusteringService {
  /// Cluster heat map data points based on zoom level and distance
  static List<MapCluster> clusterDataPoints(
    List<HeatMapDataPoint> dataPoints,
    double zoomLevel,
  ) {
    print('🔍 MapClusteringService: Input - ${dataPoints.length} points at zoom $zoomLevel');
    
    final config = ClusterConfig.forZoomLevel(zoomLevel);
    print('🔍 MapClusteringService: Config - shouldCluster: ${config.shouldCluster}, radius: ${config.clusterRadiusKm}km');
    
    if (!config.shouldCluster) {
      // Return individual points as single-item clusters
      print('🔍 MapClusteringService: Not clustering - creating individual clusters');
      return dataPoints.map((point) => MapCluster(
        id: 'single_${point.coordinates.latitude}_${point.coordinates.longitude}',
        position: LatLng(point.coordinates.latitude, point.coordinates.longitude),
        dataPoints: [point],
        count: 1,
        radius: 50, // 50 meters for individual points
      )).toList();
    }

    // Perform clustering - use larger radius for better clustering at low zoom
    final clusterRadiusMeters = config.clusterRadiusKm * 1000; // Convert km to meters
    print('🔍 MapClusteringService: Clustering with radius ${clusterRadiusMeters}m');
    
    final clusters = _performClustering(dataPoints, clusterRadiusMeters);
    print('🔍 MapClusteringService: Generated ${clusters.length} clusters from ${dataPoints.length} points');
    
    return clusters;
  }

  /// Perform distance-based clustering
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

      // Find nearby points to cluster
      for (int j = i + 1; j < dataPoints.length; j++) {
        if (processed[j]) continue;

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

      // Create cluster
      final centerPosition = MapCluster.calculateCenter(clusterPoints);
      clusters.add(MapCluster(
        id: 'cluster_${clusters.length}_${centerPosition.latitude.toStringAsFixed(4)}_${centerPosition.longitude.toStringAsFixed(4)}',
        position: centerPosition,
        dataPoints: clusterPoints,
        count: clusterPoints.length,
        radius: clusterRadiusMeters,
      ));
    }

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