import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/heat_map_models.dart';
import '../../domain/models/map_cluster.dart';

/// Service for clustering heat map data points based on zoom level
/// Optimized for viewport-based clustering with intelligent caching
class MapClusteringService {
  // Cache for stable cluster positions across zoom levels
  static final Map<String, LatLng> _stableClusterPositions = {};
  static List<HeatMapDataPoint> _lastDataPoints = [];
  
  // Performance optimization: Cache clusters by zoom level and viewport
  static final Map<String, List<MapCluster>> _clusterCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static double _lastZoomLevel = -1;
  static LatLngBounds? _lastViewport;
  static DateTime _lastClusterTime = DateTime.now();

  // Debounce and cache settings
  static const int _debounceMs = 300;
  static const int _cacheValidityMs = 30000; // 30 seconds
  static const int _maxCacheSize = 50; // Maximum cache entries
  
  // Zoom level thresholds for optimization
  static const double _minZoomLevel = 2.0;
  static const double _maxZoomLevel = 20.0;
  static const double _extremeZoomThreshold =
      4.0; // Below this, show single cluster

  /// Cluster data points based on zoom level and viewport for privacy
  /// Uses stable hierarchical clustering with viewport optimization
  static List<MapCluster> clusterDataPointsInViewport(
    List<HeatMapDataPoint> dataPoints,
    double zoomLevel, {
    LatLngBounds? viewport,
    bool forceRefresh = false,
  }) {
    if (dataPoints.isEmpty) return [];
    
    final now = DateTime.now();
    
    // Debounce rapid clustering requests
    if (!forceRefresh &&
        now.difference(_lastClusterTime).inMilliseconds < _debounceMs &&
        (zoomLevel - _lastZoomLevel).abs() < 0.5) {
      // Return last cached result if available
      final lastCacheKey = _getCacheKeyWithViewport(
        _lastDataPoints.length,
        _lastZoomLevel,
        _lastViewport,
      );
      final cached = _clusterCache[lastCacheKey];
      if (cached != null) return cached;
    }

    // Clamp zoom level to valid range
    zoomLevel = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);

    // Handle extreme zoom out - show single cluster to prevent black screen
    if (zoomLevel <= _extremeZoomThreshold) {
      return _createSingleClusterForExtremeZoom(dataPoints);
    }

    // Filter data points to viewport if provided (performance optimization)
    final viewportFilteredPoints = viewport != null
        ? _filterPointsToViewport(dataPoints, viewport)
        : dataPoints;

    if (viewportFilteredPoints.isEmpty) return [];

    // Check cache with viewport consideration
    final cacheKey = _getCacheKeyWithViewport(
      viewportFilteredPoints.length,
      zoomLevel,
      viewport,
    );
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      final cached = _clusterCache[cacheKey];
      if (cached != null) {
        developer.log(
          'MapClusteringService: Using cached clusters for zoom $zoomLevel',
          name: 'MapClusteringService',
        );
        return cached;
      }
    }
    
    // Clean old cache entries to prevent memory issues
    _cleanOldCache();

    // Clear stable positions if data changed significantly
    if (_dataPointsChanged(viewportFilteredPoints)) {
      _stableClusterPositions.clear();
    }

    developer.log(
      'MapClusteringService: Viewport clustering ${viewportFilteredPoints.length} points at zoom $zoomLevel',
      name: 'MapClusteringService',
    );

    // Use hierarchical clustering based on zoom level with viewport-filtered data
    final clusters = _performHierarchicalClustering(
      viewportFilteredPoints,
      zoomLevel,
    );

    // Cache the results with viewport consideration
    _clusterCache[cacheKey] = clusters;
    _cacheTimestamps[cacheKey] = now;
    _lastZoomLevel = zoomLevel;
    _lastViewport = viewport;
    _lastClusterTime = now;
    _lastDataPoints = List.from(viewportFilteredPoints);

    // Keep cache size reasonable
    if (_clusterCache.length > 10) {
      _clusterCache.clear();
    }

    return clusters;
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
    
    developer.log(
      'MapClusteringService: Zoom $zoomLevel -> Level $clusterLevel, Radius ${baseRadius}m',
      name: 'MapClusteringService',
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
            id: 'stable_${cellKey}_$dominantStatus',
            position: stablePosition,
            dataPoints: dominantPoints,
            count: dominantPoints.length,
            radius: radiusMeters,
          ),
        );
      }
    }
    
    developer.log(
      'MapClusteringService: Created ${clusters.length} stable grid clusters',
      name: 'MapClusteringService',
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
    return 'L${level}_${gridLat}_$gridLng';
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


  
  /// Create single cluster for extreme zoom out to prevent black screen
  static List<MapCluster> _createSingleClusterForExtremeZoom(
    List<HeatMapDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) return [];

    // Calculate center of all points
    double totalLat = 0;
    double totalLng = 0;

    for (final point in dataPoints) {
      totalLat += point.coordinates.latitude;
      totalLng += point.coordinates.longitude;
    }

    final centerLat = totalLat / dataPoints.length;
    final centerLng = totalLng / dataPoints.length;

    return [
      MapCluster(
        id: 'extreme_zoom_cluster',
        position: LatLng(centerLat, centerLng),
        dataPoints: dataPoints,
        count: dataPoints.length,
        radius: 50000, // Large radius for extreme zoom
      ),
    ];
  }

  /// Filter data points to only include those within viewport bounds
  static List<HeatMapDataPoint> _filterPointsToViewport(
    List<HeatMapDataPoint> dataPoints,
    LatLngBounds viewport,
  ) {
    return dataPoints.where((point) {
      final lat = point.coordinates.latitude;
      final lng = point.coordinates.longitude;

      return lat >= viewport.southwest.latitude &&
          lat <= viewport.northeast.latitude &&
          lng >= viewport.southwest.longitude &&
          lng <= viewport.northeast.longitude;
    }).toList();
  }

  /// Generate cache key with viewport consideration
  static String _getCacheKeyWithViewport(
    int pointCount,
    double zoomLevel,
    LatLngBounds? viewport,
  ) {
    final zoomInt = (zoomLevel * 10).round();
    if (viewport != null) {
      final swLat = (viewport.southwest.latitude * 1000).round();
      final swLng = (viewport.southwest.longitude * 1000).round();
      final neLat = (viewport.northeast.latitude * 1000).round();
      final neLng = (viewport.northeast.longitude * 1000).round();
      return '${pointCount}_${zoomInt}_${swLat}_${swLng}_${neLat}_$neLng';
    }
    return '${pointCount}_$zoomInt';
  }

  /// Check if cache entry is valid
  static bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    final now = DateTime.now();
    final age = now.difference(timestamp).inMilliseconds;
    return age < _cacheValidityMs;
  }

  /// Clean old cache entries to prevent memory bloat
  static void _cleanOldCache() {
    if (_clusterCache.length <= _maxCacheSize) return;

    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      final age = now.difference(entry.value).inMilliseconds;
      if (age > _cacheValidityMs) {
        keysToRemove.add(entry.key);
      }
    }

    // Remove oldest entries if still over limit
    if (_clusterCache.length - keysToRemove.length > _maxCacheSize) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final additionalToRemove =
          (_clusterCache.length - keysToRemove.length) - _maxCacheSize;
      for (int i = 0; i < additionalToRemove; i++) {
        keysToRemove.add(sortedEntries[i].key);
      }
    }

    for (final key in keysToRemove) {
      _clusterCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear cluster cache (useful when data changes completely)
  static void clearCache() {
    _stableClusterPositions.clear();
    _lastDataPoints.clear();
    _clusterCache.clear();
    _cacheTimestamps.clear();
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