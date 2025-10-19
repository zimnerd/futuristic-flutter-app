import 'package:equatable/equatable.dart';
import '../../core/models/location_models.dart';

/// Heat map data point representing user density at a location
class HeatMapDataPoint extends Equatable {
  final LocationCoordinates coordinates;
  final int density;
  final double radius;
  final String? label;

  const HeatMapDataPoint({
    required this.coordinates,
    required this.density,
    required this.radius,
    this.label,
  });

  @override
  List<Object?> get props => [coordinates, density, radius, label];

  Map<String, dynamic> toJson() => {
    'coordinates': coordinates.toJson(),
    'density': density,
    'radius': radius,
    if (label != null) 'label': label,
  };

  factory HeatMapDataPoint.fromJson(Map<String, dynamic> json) {
    // Handle both formats: API response format and stored format
    if (json.containsKey('coordinates')) {
      // Stored format
      return HeatMapDataPoint(
        coordinates: LocationCoordinates.fromJson(
          json['coordinates'] as Map<String, dynamic>,
        ),
        density: json['density'] as int,
        radius: (json['radius'] as num).toDouble(),
        label: json['label'] as String?,
      );
    } else {
      // API response format: {latitude, longitude, count, status}
      return HeatMapDataPoint(
        coordinates: LocationCoordinates(
          latitude: (json['latitude'] as num).toDouble(),
          longitude: (json['longitude'] as num).toDouble(),
        ),
        density: json['count'] as int,
        radius: 1.0, // Default radius
        label: json['status'] as String?,
      );
    }
  }

  @override
  String toString() =>
      'HeatMapDataPoint(coordinates: $coordinates, density: $density, radius: $radius)';
}

/// Heat map data model containing all data points and metadata
class HeatMapData extends Equatable {
  final List<HeatMapDataPoint> dataPoints;
  final LocationBounds bounds;
  final int totalUsers;
  final double averageDensity;
  final DateTime generatedAt;

  const HeatMapData({
    required this.dataPoints,
    required this.bounds,
    required this.totalUsers,
    required this.averageDensity,
    required this.generatedAt,
  });

  @override
  List<Object> get props => [
    dataPoints,
    bounds,
    totalUsers,
    averageDensity,
    generatedAt,
  ];

  Map<String, dynamic> toJson() => {
    'dataPoints': dataPoints.map((point) => point.toJson()).toList(),
    'bounds': bounds.toJson(),
    'totalUsers': totalUsers,
    'averageDensity': averageDensity,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory HeatMapData.fromJson(Map<String, dynamic> json) {
    return HeatMapData(
      dataPoints: (json['dataPoints'] as List<dynamic>)
          .map(
            (item) => HeatMapDataPoint.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      bounds: LocationBounds.fromJson(json['bounds'] as Map<String, dynamic>),
      totalUsers: json['totalUsers'] as int,
      averageDensity: (json['averageDensity'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  @override
  String toString() =>
      'HeatMapData(dataPoints: ${dataPoints.length}, totalUsers: $totalUsers)';
}

/// Heat map filters for data customization
class HeatMapFilters extends Equatable {
  final int maxDistance;
  final int minAge;
  final int maxAge;
  final MatchStatus? matchStatus;
  final List<String>? interests;
  final bool includeOnlineOnly;

  const HeatMapFilters({
    required this.maxDistance,
    required this.minAge,
    required this.maxAge,
    this.matchStatus,
    this.interests,
    this.includeOnlineOnly = false,
  });

  @override
  List<Object?> get props => [
    maxDistance,
    minAge,
    maxAge,
    matchStatus,
    interests,
    includeOnlineOnly,
  ];

  Map<String, dynamic> toJson() => {
    'maxDistance': maxDistance,
    'minAge': minAge,
    'maxAge': maxAge,
    if (matchStatus != null) 'matchStatus': matchStatus!.name,
    if (interests != null) 'interests': interests,
    'includeOnlineOnly': includeOnlineOnly,
  };

  factory HeatMapFilters.fromJson(Map<String, dynamic> json) {
    return HeatMapFilters(
      maxDistance: json['maxDistance'] as int,
      minAge: json['minAge'] as int,
      maxAge: json['maxAge'] as int,
      matchStatus: json['matchStatus'] != null
          ? MatchStatus.values.firstWhere((e) => e.name == json['matchStatus'])
          : null,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      includeOnlineOnly: json['includeOnlineOnly'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'HeatMapFilters(maxDistance: $maxDistance, minAge: $minAge, maxAge: $maxAge)';
}

/// Coverage area model representing an area with user density
class CoverageArea extends Equatable {
  final List<LocationCoordinates> boundaryPoints;
  final int density;
  final double coverage;
  final String areaType;

  const CoverageArea({
    required this.boundaryPoints,
    required this.density,
    required this.coverage,
    required this.areaType,
  });

  @override
  List<Object> get props => [boundaryPoints, density, coverage, areaType];

  Map<String, dynamic> toJson() => {
    'boundaryPoints': boundaryPoints.map((point) => point.toJson()).toList(),
    'density': density,
    'coverage': coverage,
    'areaType': areaType,
  };

  factory CoverageArea.fromJson(Map<String, dynamic> json) {
    return CoverageArea(
      boundaryPoints: (json['boundaryPoints'] as List<dynamic>)
          .map(
            (item) =>
                LocationCoordinates.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      density: json['density'] as int,
      coverage: (json['coverage'] as num).toDouble(),
      areaType: json['areaType'] as String,
    );
  }

  @override
  String toString() =>
      'CoverageArea(density: $density, coverage: $coverage, areaType: $areaType)';
}

/// Location coverage data model
class LocationCoverageData extends Equatable {
  final List<CoverageArea> coverageAreas;
  final int totalUsers;
  final double averageDensity;
  final double totalCoverage;
  final LocationCoordinates center;
  final double radiusKm;

  const LocationCoverageData({
    required this.coverageAreas,
    required this.totalUsers,
    required this.averageDensity,
    required this.totalCoverage,
    required this.center,
    required this.radiusKm,
  });

  @override
  List<Object> get props => [
    coverageAreas,
    totalUsers,
    averageDensity,
    totalCoverage,
    center,
    radiusKm,
  ];

  Map<String, dynamic> toJson() => {
    'coverageAreas': coverageAreas.map((area) => area.toJson()).toList(),
    'totalUsers': totalUsers,
    'averageDensity': averageDensity,
    'totalCoverage': totalCoverage,
    'center': center.toJson(),
    'radiusKm': radiusKm,
  };

  factory LocationCoverageData.fromJson(Map<String, dynamic> json) {
    // Handle both formats: API response format and stored format
    if (json.containsKey('coverageAreas')) {
      // Stored format
      return LocationCoverageData(
        coverageAreas: (json['coverageAreas'] as List<dynamic>)
            .map((item) => CoverageArea.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalUsers: json['totalUsers'] as int,
        averageDensity: (json['averageDensity'] as num).toDouble(),
        totalCoverage: (json['totalCoverage'] as num).toDouble(),
        center: LocationCoordinates.fromJson(
          json['center'] as Map<String, dynamic>,
        ),
        radiusKm: (json['radiusKm'] as num).toDouble(),
      );
    } else {
      // API response format: {center, radius, userCounts}
      final userCounts = json['userCounts'] as Map<String, dynamic>;
      final totalUsers =
          (userCounts['matched'] as int? ?? 0) +
          (userCounts['likedMe'] as int? ?? 0) +
          (userCounts['unmatched'] as int? ?? 0) +
          (userCounts['passed'] as int? ?? 0);

      return LocationCoverageData(
        coverageAreas:
            [], // Empty for API response - would need additional processing
        totalUsers: totalUsers,
        averageDensity: totalUsers > 0
            ? totalUsers / ((json['radius'] as num).toDouble())
            : 0.0,
        totalCoverage: (json['radius'] as num).toDouble(),
        center: LocationCoordinates.fromJson(
          json['center'] as Map<String, dynamic>,
        ),
        radiusKm: (json['radius'] as num).toDouble(),
      );
    }
  }

  @override
  String toString() =>
      'LocationCoverageData(totalUsers: $totalUsers, totalCoverage: $totalCoverage)';
}

/// Location coverage filters
class LocationCoverageFilters extends Equatable {
  final int minAge;
  final int maxAge;
  final MatchStatus? matchStatus;
  final List<String>? interests;
  final bool includeOnlineOnly;

  const LocationCoverageFilters({
    required this.minAge,
    required this.maxAge,
    this.matchStatus,
    this.interests,
    this.includeOnlineOnly = false,
  });

  @override
  List<Object?> get props => [
    minAge,
    maxAge,
    matchStatus,
    interests,
    includeOnlineOnly,
  ];

  Map<String, dynamic> toJson() => {
    'minAge': minAge,
    'maxAge': maxAge,
    if (matchStatus != null) 'matchStatus': matchStatus!.name,
    if (interests != null) 'interests': interests,
    'includeOnlineOnly': includeOnlineOnly,
  };

  factory LocationCoverageFilters.fromJson(Map<String, dynamic> json) {
    return LocationCoverageFilters(
      minAge: json['minAge'] as int,
      maxAge: json['maxAge'] as int,
      matchStatus: json['matchStatus'] != null
          ? MatchStatus.values.firstWhere((e) => e.name == json['matchStatus'])
          : null,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      includeOnlineOnly: json['includeOnlineOnly'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'LocationCoverageFilters(minAge: $minAge, maxAge: $maxAge)';
}

/// Match status enumeration
enum MatchStatus { none, likedYou, matched, rejected }

/// Extension for match status display names
extension MatchStatusExtension on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.none:
        return 'No Match';
      case MatchStatus.likedYou:
        return 'Liked You';
      case MatchStatus.matched:
        return 'Matched';
      case MatchStatus.rejected:
        return 'Rejected';
    }
  }

  String get description {
    switch (this) {
      case MatchStatus.none:
        return 'Users you haven\'t matched with';
      case MatchStatus.likedYou:
        return 'Users who liked you';
      case MatchStatus.matched:
        return 'Mutual matches';
      case MatchStatus.rejected:
        return 'Users you\'ve passed on';
    }
  }
}
