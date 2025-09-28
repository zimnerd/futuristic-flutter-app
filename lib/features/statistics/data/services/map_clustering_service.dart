import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/heat_map_models.dart';
import '../../domain/models/map_cluster.dart';

/// Service for clustering heat map data points based on zoom level
class MapClusteringService {
  // Cache for stable cluster positions across zoom levels
  static final Map<String, LatLng> _stableClusterPositions = {};
  static List<HeatMapDataPoint> _lastDataPoints = [];
  
  /// Cluster data points based on zoom level for privacy
  /// Uses stable hierarchical clustering to maintain consistent positions
  static List<MapCluster> clusterDataPoints(
    List<HeatMapDataPoint> dataPoints,
    double zoomLevel,
  ) {
    if (dataPoints.isEmpty) return [];
    
    // Clear cache if data changed significantly
    if (_dataPointsChanged(dataPoints)) {
      _stableClusterPositions.clear();
      _lastDataPoints = List.from(dataPoints);
    }

    print(
      'MapClusteringService: Stable clustering ${dataPoints.length} points at zoom $zoomLevel',
    );
    
    // Use hierarchical clustering based on zoom level
    return _performHierarchicalClustering(dataPoints, zoomLevel);
  }
  
  /// Check if data points have changed significantly
  static bool _dataPointsChanged(List<HeatMapDataPoint> newPoints) {
    if (_lastDataPoints.length != newPoints.length) return true;

    // Quick check - compare first few points
    for (int i = 0; i < math.min(3, newPoints.length); i++) {
      final oldPoint = _lastDataPoints[i];
      final newPoint = newPoints[i];
      if (oldPoint.coordinates.latitude != newPoint.coordinates.latitude ||
          oldPoint.coordinates.longitude != newPoint.coordinates.longitude) {
        return true;
      }
    }
    return false;
  }

  /// Perform hierarchical clustering with stable positions
  static List<MapCluster> _performHierarchicalClustering(
    List<HeatMapDataPoint> dataPoints,
    double zoomLevel,
  ) {
    // Determine clustering level based on zoom
    int clusterLevel;
    double baseRadius;
    
    if (zoomLevel <= 6) {
      // Country/continent level - single cluster
      clusterLevel = 0;
      baseRadius = 50000; // 50km
    } else if (zoomLevel <= 9) {
      // Regional level - few large clusters
      clusterLevel = 1;
      baseRadius = 20000; // 20km
    } else if (zoomLevel <= 12) {
      // City level - moderate clusters
      clusterLevel = 2;
      baseRadius = 5000; // 5km
    } else if (zoomLevel <= 15) {
      // District level - smaller clusters
      clusterLevel = 3;
      baseRadius = 2000; // 2km
    } else {
      // Street level - minimum privacy clusters
      clusterLevel = 4;
      baseRadius = 800; // 800m for privacy
    }
    
    print(
      'MapClusteringService: Zoom $zoomLevel -> Level $clusterLevel, Radius ${baseRadius}m',
    );
    
    // Create stable grid-based clusters
    return _createStableGridClusters(dataPoints, clusterLevel, baseRadius);
  }
  
  /// Create stable clusters using a grid-based approach
  static List<MapCluster> _createStableGridClusters(
    List<HeatMapDataPoint> dataPoints,
    int level,
    double radiusMeters,
  ) {
    if (dataPoints.isEmpty) return [];

    // Calculate grid cell size based on radius
    final double cellSizeKm = radiusMeters / 1000.0;
    final Map<String, List<HeatMapDataPoint>> gridCells = {};

    // Group points into stable grid cells
    for (final point in dataPoints) {
      final latLng = LatLng(
        point.coordinates.latitude,
        point.coordinates.longitude,
      );
      final cellKey = _getStableGridKey(latLng, cellSizeKm, level);
      gridCells.putIfAbsent(cellKey, () => []).add(point);
    }
    
    final clusters = <MapCluster>[];
    
    for (final entry in gridCells.entries) {
      final cellKey = entry.key;
      final cellPoints = entry.value;
      
      if (cellPoints.isEmpty) continue;
      
      // Get or create stable position for this grid cell
      final stablePosition = _getStablePosition(cellKey, cellPoints);
      
      // Group by status for privacy
      final statusGroups = <String, List<HeatMapDataPoint>>{};
      for (final point in cellPoints) {
        final status = point.label ?? 'unknown';
        statusGroups.putIfAbsent(status, () => []).add(point);
      }
      
      // Create cluster for dominant status group
      final dominantStatus = _getDominantStatus(statusGroups);
      final dominantPoints = statusGroups[dominantStatus] ?? [];

      if (dominantPoints.isNotEmpty) {
        clusters.add(
          MapCluster(
            id: 'stable_${cellKey}_${dominantStatus}',
            position: stablePosition,
            dataPoints: dominantPoints,
            count: dominantPoints.length,
            radius: radiusMeters,
          ),
        );
      }
    }
    
    print(
      'MapClusteringService: Created ${clusters.length} stable grid clusters',
    );
    return clusters;
  }
  
  /// Generate stable grid key for consistent positioning
  static String _getStableGridKey(
    LatLng coordinates,
    double cellSizeKm,
    int level,
  ) {
    // Create stable grid coordinates
    final gridLat = (coordinates.latitude / cellSizeKm).floor();
    final gridLng = (coordinates.longitude / cellSizeKm).floor();
    return 'L${level}_${gridLat}_${gridLng}';
  }

  /// Get or create stable position for grid cell
  static LatLng _getStablePosition(
    String cellKey,
    List<HeatMapDataPoint> points,
  ) {
    // Return cached position if available
    if (_stableClusterPositions.containsKey(cellKey)) {
      return _stableClusterPositions[cellKey]!;
    }

    // Calculate center position and cache it
    final avgLat =
        points.map((p) => p.coordinates.latitude).reduce((a, b) => a + b) /
        points.length;
    final avgLng =
        points.map((p) => p.coordinates.longitude).reduce((a, b) => a + b) /
        points.length;

    final stablePosition = LatLng(avgLat, avgLng);
    _stableClusterPositions[cellKey] = stablePosition;
    
    return stablePosition;
  }
  
  /// Get dominant status from status groups
  static String _getDominantStatus(
    Map<String, List<HeatMapDataPoint>> statusGroups,
  ) {
    String dominantStatus = 'unknown';
    int maxCount = 0;
    
    for (final entry in statusGroups.entries) {
      if (entry.value.length > maxCount) {
        maxCount = entry.value.length;
        dominantStatus = entry.key;
      }
    }
    
    return dominantStatus;
  }


  
  /// Clear cluster cache (useful when data changes completely)
  static void clearCache() {
    _stableClusterPositions.clear();
    _lastDataPoints.clear();
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