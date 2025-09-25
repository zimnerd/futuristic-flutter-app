import 'dart:developer' as dev;
import 'dart:math' as math;
import '../../core/constants/api_constants.dart';
import '../../domain/services/api_service.dart';
import '../../core/di/service_locator.dart';
import '../models/heat_map_models.dart';
import '../../core/models/location_models.dart';

/// Service for handling heat map and location-based statistics
class HeatMapService {
  final ApiService _apiService = sl<ApiService>();

  /// Get heat map data for user locations
  Future<List<HeatMapDataPoint>> getHeatMapData({
    LocationBounds? bounds,
    HeatMapFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (bounds != null) {
        queryParams.addAll({
          'northLatitude': bounds.northLatitude,
          'southLatitude': bounds.southLatitude,
          'eastLongitude': bounds.eastLongitude,
          'westLongitude': bounds.westLongitude,
        });
      }
      
      if (filters != null) {
        queryParams.addAll(filters.toJson());
      }

      final response = await _apiService.get(
        ApiConstants.statisticsHeatMap,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['dataPoints'] is List) {
        final points = (response.data['dataPoints'] as List)
            .map((json) => HeatMapDataPoint.fromJson(json))
            .toList();
        
        dev.log('Fetched ${points.length} heat map points', name: 'HeatMapService');
        return points;
      }

      return [];
    } catch (e) {
      dev.log('Error fetching heat map data: $e', name: 'HeatMapService');
      rethrow;
    }
  }

  /// Get location coverage data for the given area
  Future<LocationCoverageData> getLocationCoverageData({
    required LocationCoordinates center,
    required double radiusKm,
    LocationCoverageFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'centerLatitude': center.latitude,
        'centerLongitude': center.longitude,
        'radiusKm': radiusKm,
      };

      if (filters != null) {
        queryParams.addAll(filters.toJson());
      }

      final response = await _apiService.get(
        ApiConstants.statisticsLocationCoverage,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        return LocationCoverageData.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch location coverage data');
      }
    } catch (e) {
      dev.log('Error fetching location coverage data: $e', name: 'HeatMapService');
      rethrow;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    LocationCoordinates point1,
    LocationCoordinates point2,
  ) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    final double lat1Rad = _degreesToRadians(point1.latitude);
    final double lat2Rad = _degreesToRadians(point2.latitude);
    final double deltaLatRad = _degreesToRadians(point2.latitude - point1.latitude);
    final double deltaLngRad = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  /// Calculate bearing between two coordinates
  static double calculateBearing(
    LocationCoordinates from,
    LocationCoordinates to,
  ) {
    final double lat1Rad = _degreesToRadians(from.latitude);
    final double lat2Rad = _degreesToRadians(to.latitude);
    final double deltaLngRad = _degreesToRadians(to.longitude - from.longitude);

    final double y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    final double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = _radiansToDegrees(bearingRad);

    return (bearingDeg + 360) % 360; // Normalize to 0-360 degrees
  }

  /// Calculate destination point given start point, distance and bearing
  static LocationCoordinates calculateDestination({
    required LocationCoordinates start,
    required double distanceKm,
    required double bearingDegrees,
  }) {
    const double earthRadius = 6371.0;
    final double distanceRadians = distanceKm / earthRadius;
    final double bearingRadians = _degreesToRadians(bearingDegrees);

    final double startLatRad = _degreesToRadians(start.latitude);
    final double startLngRad = _degreesToRadians(start.longitude);

    final double destLatRad = math.asin(
      math.sin(startLatRad) * math.cos(distanceRadians) +
          math.cos(startLatRad) * math.sin(distanceRadians) * math.cos(bearingRadians),
    );

    final double destLngRad = startLngRad +
        math.atan2(
          math.sin(bearingRadians) * math.sin(distanceRadians) * math.cos(startLatRad),
          math.cos(distanceRadians) - math.sin(startLatRad) * math.sin(destLatRad),
        );

    return LocationCoordinates(
      latitude: _radiansToDegrees(destLatRad),
      longitude: _radiansToDegrees(destLngRad),
    );
  }

  /// Check if a point is within a circular area
  static bool isWithinRadius({
    required LocationCoordinates center,
    required LocationCoordinates point,
    required double radiusKm,
  }) {
    final double distance = calculateDistance(center, point);
    return distance <= radiusKm;
  }

  /// Generate bounding box for a center point and radius
  static LocationBounds generateBoundingBox({
    required LocationCoordinates center,
    required double radiusKm,
  }) {
    // Calculate the approximate degree offset for the given radius
    // Note: This is approximate and works better for smaller distances
    const double kmToDegree = 0.009; // Rough conversion, varies by latitude
    final double offset = radiusKm * kmToDegree;

    return LocationBounds(
      northLatitude: center.latitude + offset,
      southLatitude: center.latitude - offset,
      eastLongitude: center.longitude + offset,
      westLongitude: center.longitude - offset,
    );
  }

  /// Calculate the optimal grid size for heat map based on zoom level
  static double calculateOptimalGridSize(double zoomLevel) {
    // Grid size in degrees, smaller for higher zoom levels
    if (zoomLevel >= 15) return 0.001; // ~100m
    if (zoomLevel >= 13) return 0.005; // ~500m
    if (zoomLevel >= 11) return 0.01;  // ~1km
    if (zoomLevel >= 9) return 0.05;   // ~5km
    return 0.1; // ~10km
  }

  /// Filter heat map data by density threshold
  static List<HeatMapDataPoint> filterByDensity(
    List<HeatMapDataPoint> dataPoints,
    int minDensity,
  ) {
    return dataPoints.where((point) => point.density >= minDensity).toList();
  }

  /// Sort heat map data by density (highest first)
  static List<HeatMapDataPoint> sortByDensity(
    List<HeatMapDataPoint> dataPoints, {
    bool ascending = false,
  }) {
    final List<HeatMapDataPoint> sorted = List.from(dataPoints);
    sorted.sort((a, b) {
      return ascending 
          ? a.density.compareTo(b.density)
          : b.density.compareTo(a.density);
    });
    return sorted;
  }

  /// Calculate coverage statistics for an area
  static Map<String, dynamic> calculateCoverageStatistics(
    LocationCoverageData coverageData,
  ) {
    if (coverageData.coverageAreas.isEmpty) {
      return {
        'totalAreas': 0,
        'averageDensity': 0.0,
        'maxDensity': 0,
        'minDensity': 0,
        'totalCoverage': 0.0,
      };
    }

    final densities = coverageData.coverageAreas.map((area) => area.density).toList();
    final coverages = coverageData.coverageAreas.map((area) => area.coverage).toList();

    return {
      'totalAreas': coverageData.coverageAreas.length,
      'averageDensity': densities.reduce((a, b) => a + b) / densities.length,
      'maxDensity': densities.reduce(math.max),
      'minDensity': densities.reduce(math.min),
      'totalCoverage': coverages.reduce((a, b) => a + b),
    };
  }
}