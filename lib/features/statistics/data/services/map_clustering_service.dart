import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/heat_map_models.dart';
import '../../domain/models/map_cluster.dart';

/// Service for clustering heat map data points based on zoom level
class MapClusteringService {
  // Cache for stable cluster positions across zoom levels
  static final Map<String, LatLng> _stableClusterPositions = {};
  static List<HeatMapDataPoint> _lastDataPoints = [];
  
  // Performance optimization: Cache clusters by zoom level
  static final Map<String, List<MapCluster>> _clusterCache = {};
  static double _lastZoomLevel = -1;
  static DateTime _lastClusterTime = DateTime.now();

  // Debounce threshold in milliseconds
  static const int _debounceMs = 300;
  
  /// Cluster data points based on zoom level for privacy
  /// Uses stable hierarchical clustering to maintain consistent positions
  static List<MapCluster> clusterDataPoints(
    List<HeatMapDataPoint> dataPoints,
    double zoomLevel,
  ) {
    if (dataPoints.isEmpty) return [];
    
    // Performance optimization: Check if we can use cached results
    final now = DateTime.now();
    final timeSinceLastCluster = now
        .difference(_lastClusterTime)
        .inMilliseconds;
    final zoomDiff = (zoomLevel - _lastZoomLevel).abs();

    // Use cache if zoom level is similar and recent
    if (timeSinceLastCluster < _debounceMs &&
        zoomDiff < 0.5 &&
        !_dataPointsChanged(dataPoints)) {
      final cacheKey = _getCacheKey(dataPoints.length, zoomLevel);
      if (_clusterCache.containsKey(cacheKey)) {
        print(
          'MapClusteringService: Using cached clusters for zoom $zoomLevel',
        );
        return _clusterCache[cacheKey]!;
      }
    }
    
    // Clear cache if data changed significantly
    if (_dataPointsChanged(dataPoints)) {
      _stableClusterPositions.clear();
      _clusterCache.clear();
      _lastDataPoints = List.from(dataPoints);
    }

    print(
      'MapClusteringService: Stable clustering ${dataPoints.length} points at zoom $zoomLevel',
    );

    // Use hierarchical clustering based on zoom level
    final clusters = _performHierarchicalClustering(dataPoints, zoomLevel);

    // Cache the results
    final cacheKey = _getCacheKey(dataPoints.length, zoomLevel);
    _clusterCache[cacheKey] = clusters;
    _lastZoomLevel = zoomLevel;
    _lastClusterTime = now;

    // Keep cache size reasonable
    if (_clusterCache.length > 10) {
      _clusterCache.clear();
    }

    return clusters;
  }

  /// Generate cache key for clustering results
  static String _getCacheKey(int dataPointCount, double zoomLevel) {
    final zoomInt = (zoomLevel * 2).round(); // 0.5 zoom precision
    return '${dataPointCount}_${zoomInt}';
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
    // Determine clustering level based on zoom - optimized for performance
    int clusterLevel;
    double baseRadius;
    
    if (zoomLevel <= 6) {
      // Global/continental level - single or very few clusters
      clusterLevel = 0;
      baseRadius = 200000; // 200km for very wide view
    } else if (zoomLevel <= 8) {
      // Country level - few large clusters
      clusterLevel = 1;
      baseRadius = 75000; // 75km
    } else if (zoomLevel <= 10) {
      // Regional level - moderate clusters
      clusterLevel = 2;
      baseRadius = 30000; // 30km
    } else if (zoomLevel <= 12) {
      // City level - smaller clusters
      clusterLevel = 3;
      baseRadius = 15000; // 15km
    } else if (zoomLevel <= 14) {
      // District level - fine clusters
      clusterLevel = 4;
      baseRadius = 7000; // 7km
    } else if (zoomLevel <= 16) {
      // Neighborhood level - very fine clusters
      clusterLevel = 5;
      baseRadius = 3000; // 3km
    } else {
      // Street level - minimum privacy clusters
      clusterLevel = 6;
      baseRadius = 1200; // 1.2km for privacy
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
    // Create stable grid coordinates with better resolution
    // Use smaller divisor for more stable grid alignment
    final cellSize = cellSizeKm * 0.01; // Convert to degrees approximately
    final gridLat = (coordinates.latitude / cellSize).floor();
    final gridLng = (coordinates.longitude / cellSize).floor();
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