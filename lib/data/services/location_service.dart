import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';
import '../../domain/services/api_service.dart';

class LocationService {
  static const String _lastLocationKey = 'last_location';
  static const String _lastUpdateKey = 'last_location_update';
  static const double _significantDistanceThresholdKm = 1.0;

  final ApiService _apiService;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;

  LocationService(this._apiService);

  /// Request location permissions from user
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location with caching
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastKnownPosition != null) {
      return _lastKnownPosition;
    }

    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _lastKnownPosition = position;
      await _cacheLocation(position);
      
      return position;
    } catch (e) {
      // Fallback to cached location if available
      return await _getCachedLocation();
    }
  }

  /// Start listening to location changes
  Future<void> startLocationTracking() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        await _handleLocationUpdate(position);
      },
      onError: (error) {
            AppLogger.debug('Location tracking error: $error');
      },
    );
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Handle location update with smart filtering
  Future<void> _handleLocationUpdate(Position newPosition) async {
    final lastPosition = await _getCachedLocation();
    
    if (lastPosition == null || 
        _shouldUpdateLocation(lastPosition, newPosition)) {
      
      _lastKnownPosition = newPosition;
      await _cacheLocation(newPosition);
      await _updateServerLocation(newPosition);
    }
  }

  /// Check if location should be updated based on distance threshold
  bool _shouldUpdateLocation(Position lastPosition, Position newPosition) {
    final distance = _calculateDistanceKm(
      lastPosition.latitude,
      lastPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance >= _significantDistanceThresholdKm;
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Update location on server
  Future<void> _updateServerLocation(Position position) async {
    try {
      await _apiService.post('/users/location', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location': await _getLocationName(position),
      });

      // Update last update timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.debug('Failed to update server location: $e');
    }
  }

  /// Get location name from coordinates (reverse geocoding)
  Future<String?> _getLocationName(Position position) async {
    try {
      // This would require a geocoding service
      // For now, return a simple format
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      return null;
    }
  }

  /// Cache location locally
  Future<void> _cacheLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, 
      '${position.latitude},${position.longitude},${position.timestamp.millisecondsSinceEpoch}');
  }

  /// Get cached location
  Future<Position?> _getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final locationString = prefs.getString(_lastLocationKey);
    
    if (locationString == null) return null;

    final parts = locationString.split(',');
    if (parts.length != 3) return null;

    try {
      return Position(
        latitude: double.parse(parts[0]),
        longitude: double.parse(parts[1]),
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get distance preference from user settings
  Future<int> getDistancePreference() async {
    try {
      final response = await _apiService.get('/users/me');
      return response.data['distancePreferenceKm'] ?? 50;
    } catch (e) {
      return 50; // Default to 50km
    }
  }

  /// Update distance preference
  Future<void> updateDistancePreference(int distanceKm) async {
    try {
      await _apiService.patch('/users/me', data: {
        'distancePreferenceKm': distanceKm,
      });
    } catch (e) {
      AppLogger.debug('Failed to update distance preference: $e');
    }
  }

  /// Check if location services are available and enabled
  Future<bool> isLocationAvailable() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    
    return serviceEnabled && 
           permission != LocationPermission.denied &&
           permission != LocationPermission.deniedForever;
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Clean up resources
  void dispose() {
    stopLocationTracking();
  }
}