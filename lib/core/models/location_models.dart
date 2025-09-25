import 'package:equatable/equatable.dart';

/// Location coordinates model
class LocationCoordinates extends Equatable {
  final double latitude;
  final double longitude;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [latitude, longitude];

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LocationCoordinates.fromJson(Map<String, dynamic> json) {
    return LocationCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'LocationCoordinates(lat: $latitude, lng: $longitude)';
}

/// Location update request model for API
class LocationUpdateRequest {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const LocationUpdateRequest({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() => 'LocationUpdateRequest(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}

/// Location accuracy levels
enum LocationAccuracyLevel {
  low,
  medium,
  high,
  best,
}

/// Location permission status
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

/// Location bounds for area filtering
class LocationBounds extends Equatable {
  final double northLatitude;
  final double southLatitude;
  final double eastLongitude;
  final double westLongitude;

  const LocationBounds({
    required this.northLatitude,
    required this.southLatitude,
    required this.eastLongitude,
    required this.westLongitude,
  });

  @override
  List<Object> get props => [northLatitude, southLatitude, eastLongitude, westLongitude];

  Map<String, dynamic> toJson() => {
    'northLatitude': northLatitude,
    'southLatitude': southLatitude,
    'eastLongitude': eastLongitude,
    'westLongitude': westLongitude,
  };

  factory LocationBounds.fromJson(Map<String, dynamic> json) {
    return LocationBounds(
      northLatitude: (json['northLatitude'] as num).toDouble(),
      southLatitude: (json['southLatitude'] as num).toDouble(),
      eastLongitude: (json['eastLongitude'] as num).toDouble(),
      westLongitude: (json['westLongitude'] as num).toDouble(),
    );
  }

  /// Check if coordinates are within bounds
  bool contains(LocationCoordinates coordinates) {
    return coordinates.latitude >= southLatitude &&
           coordinates.latitude <= northLatitude &&
           coordinates.longitude >= westLongitude &&
           coordinates.longitude <= eastLongitude;
  }

  @override
  String toString() => 'LocationBounds(N:$northLatitude, S:$southLatitude, E:$eastLongitude, W:$westLongitude)';
}

/// User location with metadata
class UserLocation extends Equatable {
  final String userId;
  final LocationCoordinates coordinates;
  final DateTime lastUpdated;
  final double? accuracy;
  final bool isOnline;

  const UserLocation({
    required this.userId,
    required this.coordinates,
    required this.lastUpdated,
    this.accuracy,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [userId, coordinates, lastUpdated, accuracy, isOnline];

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'coordinates': coordinates.toJson(),
    'lastUpdated': lastUpdated.toIso8601String(),
    if (accuracy != null) 'accuracy': accuracy,
    'isOnline': isOnline,
  };

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['userId'] as String,
      coordinates: LocationCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'UserLocation(userId: $userId, coordinates: $coordinates, lastUpdated: $lastUpdated)';
}