import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/heat_map_models.dart';

/// Represents a cluster of heat map data points for map visualization
class MapCluster {
  final String id;
  final LatLng position;
  final List<HeatMapDataPoint> dataPoints;
  final int count;
  final double radius; // in meters

  const MapCluster({
    required this.id,
    required this.position,
    required this.dataPoints,
    required this.count,
    required this.radius,
  });

  /// Calculate the center position of all data points in the cluster
  static LatLng calculateCenter(List<HeatMapDataPoint> points) {
    if (points.isEmpty) {
      return const LatLng(0, 0);
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.coordinates.latitude;
      totalLng += point.coordinates.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  /// Get the dominant status in this cluster
  String get dominantStatus {
    final statusCounts = <String, int>{};

    for (final point in dataPoints) {
      final status = point.label ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + point.density;
    }

    return statusCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get total count of all users in this cluster
  int get totalUserCount {
    return dataPoints.fold(0, (sum, point) => sum + point.density);
  }

  @override
  String toString() {
    return 'MapCluster(id: $id, position: $position, count: $count, totalUsers: $totalUserCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapCluster && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Clustering configuration based on zoom level
class ClusterConfig {
  final double zoomLevel;
  final double clusterRadiusKm;
  final bool shouldCluster;

  const ClusterConfig({
    required this.zoomLevel,
    required this.clusterRadiusKm,
    required this.shouldCluster,
  });

  static ClusterConfig forZoomLevel(double zoom) {
    if (zoom >= 14) {
      // Very high zoom - small clusters for privacy
      return const ClusterConfig(
        zoomLevel: 14,
        clusterRadiusKm: 1,
        shouldCluster: true,
      );
    } else if (zoom >= 10) {
      // Medium zoom - medium clusters
      return const ClusterConfig(
        zoomLevel: 10,
        clusterRadiusKm: 5,
        shouldCluster: true,
      );
    } else if (zoom >= 6) {
      // Low zoom - large clusters
      return const ClusterConfig(
        zoomLevel: 6,
        clusterRadiusKm: 20,
        shouldCluster: true,
      );
    } else {
      // Very low zoom - very large clusters
      return const ClusterConfig(
        zoomLevel: 4,
        clusterRadiusKm: 50,
        shouldCluster: true,
      );
    }
  }
}
