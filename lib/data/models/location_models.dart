class LocationPermissionStatus {
  final bool isGranted;
  final bool canRequest;
  final bool isPermanentlyDenied;
  final bool isServiceEnabled;

  const LocationPermissionStatus({
    required this.isGranted,
    required this.canRequest,
    required this.isPermanentlyDenied,
    required this.isServiceEnabled,
  });
}

class UserLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final double? accuracy;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    this.accuracy,
  });

  factory UserLocation.fromPosition(dynamic position, {String? address}) {
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      timestamp: position.timestamp ?? DateTime.now(),
      accuracy: position.accuracy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      accuracy: json['accuracy']?.toDouble(),
    );
  }
}

class DistancePreference {
  final int distanceKm;
  final String displayText;

  const DistancePreference({
    required this.distanceKm,
    required this.displayText,
  });

  static const List<DistancePreference> predefinedOptions = [
    DistancePreference(distanceKm: 5, displayText: '5 km'),
    DistancePreference(distanceKm: 10, displayText: '10 km'),
    DistancePreference(distanceKm: 25, displayText: '25 km'),
    DistancePreference(distanceKm: 50, displayText: '50 km'),
    DistancePreference(distanceKm: 100, displayText: '100 km'),
    DistancePreference(distanceKm: 200, displayText: '200 km'),
    DistancePreference(distanceKm: 500, displayText: '500 km'),
    DistancePreference(distanceKm: 1000, displayText: 'Global'),
  ];
}