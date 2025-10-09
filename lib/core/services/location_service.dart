import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/api_constants.dart';
import '../models/location_models.dart';
import '../../data/services/heat_map_service.dart';
import '../../domain/services/api_service.dart';
import '../di/service_locator.dart';
import 'permission_service.dart';

/// Location permission status
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

/// Location accuracy level
enum LocationAccuracyLevel { low, medium, high, best }

/// Location update request model
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

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Enhanced location service for GPS tracking and location updates
class LocationService {
  // Location tracking state
  StreamSubscription<Position>? _locationSubscription;
  LocationCoordinates? _lastKnownLocation;
  DateTime? _lastUpdateTime;
  Timer? _updateTimer;

  // Configuration
  static const double _updateThresholdKm = 1.0; // Update when moved >1km
  static const Duration _maxUpdateInterval = Duration(
    hours: 1,
  ); // Force update after 1 hour
  static const Duration _minUpdateInterval = Duration(
    minutes: 5,
  ); // Minimum time between updates

  /// Get current location coordinates (legacy method - maintained for compatibility)
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('LocationService: Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('LocationService: Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Permission denied by user');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission permanently denied');
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('LocationService: Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        return null;
      }

      debugPrint('LocationService: Attempting to get current position...');

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      
      debugPrint(
        'LocationService: Successfully got position: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting location: $e');
      return null;
    }
  }

  /// Get location address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  /// Get coordinates from address string
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  /// Get current location permission status
  Future<LocationPermissionStatus> getPermissionStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.denied;
      }

      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.granted;
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.permanentlyDenied;
        case LocationPermission.unableToDetermine:
          return LocationPermissionStatus.unknown;
      }
    } catch (e) {
      dev.log('Error checking location permission: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Request location permissions with user-friendly flow
  Future<LocationPermissionStatus> requestPermissions({
    bool showRationale = true,
  }) async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Request user to enable location services
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          return LocationPermissionStatus.denied;
        }
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return LocationPermissionStatus.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied, redirect to settings
        if (showRationale) {
          await openAppSettings();
        }
        return LocationPermissionStatus.permanentlyDenied;
      }

      // Permission granted
      return LocationPermissionStatus.granted;
    } catch (e) {
      dev.log('Error requesting location permission: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Request location permissions with user-friendly dialogs (recommended)
  /// This method shows explanatory dialogs and handles permission denial gracefully
  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    try {
      debugPrint('📍 LocationService: Starting permission request with dialog');

      // Check if location service is enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint(
        '📍 LocationService: Location services enabled: $serviceEnabled',
      );

      if (!serviceEnabled) {
        debugPrint(
          '📍 LocationService: Location services disabled, showing enable dialog',
        );
        // Show dialog to enable location services
        if (!context.mounted) {
          debugPrint(
            '📍 LocationService: Context not mounted, returning false',
          );
          return false;
        }

        final enableService = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text(
              '📍 Location Services Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            content: const Text(
              'Location services are disabled. Please enable them to use location features.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop(true);
                  await Geolocator.openLocationSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E3BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Enable Location'),
              ),
            ],
          ),
        );

        debugPrint(
          '📍 LocationService: User chose to enable services: $enableService',
        );

        if (enableService != true) {
          debugPrint(
            '📍 LocationService: User cancelled location services enable',
          );
          return false;
        }

        // Check again after user potentially enabled services
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint(
          '📍 LocationService: Location services after settings: $serviceEnabled',
        );

        if (!serviceEnabled) {
          debugPrint('📍 LocationService: Location services still disabled');
          return false;
        }
      }

      debugPrint(
        '📍 LocationService: Location services enabled, requesting permission',
      );

      // Use PermissionService for user-friendly permission request
      final permissionService = PermissionService();
      final granted = await permissionService
          .requestLocationWhenInUsePermission(context);

      debugPrint('📍 LocationService: Permission granted: $granted');

      if (!granted && context.mounted) {
        debugPrint(
          '📍 LocationService: Permission denied, showing features limited dialog',
        );
        // Show dialog explaining which features are limited
        await permissionService.showLocationFeaturesLimitedDialog(context);
      }

      return granted;
    } catch (e) {
      debugPrint(
        '📍 LocationService: Error requesting location permission with dialog: $e',
      );
      return false;
    }
  }

  /// Get current location with enhanced features
  Future<LocationCoordinates?> getCurrentLocationCoordinates({
    LocationAccuracyLevel accuracy = LocationAccuracyLevel.medium,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final permissionStatus = await getPermissionStatus();
      if (permissionStatus != LocationPermissionStatus.granted) {
        dev.log('Location permission not granted: $permissionStatus');
        return null;
      }

      final locationSettings = LocationSettings(
        accuracy: _getGeolocatorAccuracy(accuracy),
        distanceFilter: 10, // Minimum distance (in meters) to update
        timeLimit: timeout,
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      final coordinates = LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _lastKnownLocation = coordinates;
      return coordinates;
    } catch (e) {
      dev.log('Error getting current location: $e');
      return _lastKnownLocation; // Return cached location if available
    }
  }

  /// Start automatic location tracking with smart updates
  Future<void> startLocationTracking({
    LocationAccuracyLevel accuracy = LocationAccuracyLevel.medium,
  }) async {
    try {
      final permissionStatus = await getPermissionStatus();
      if (permissionStatus != LocationPermissionStatus.granted) {
        dev.log('Cannot start location tracking: permission not granted');
        return;
      }

      // Stop existing tracking
      await stopLocationTracking();

      final locationSettings = LocationSettings(
        accuracy: _getGeolocatorAccuracy(accuracy),
        distanceFilter: 50, // Update every 50 meters
        timeLimit: const Duration(seconds: 10),
      );

      dev.log('Starting location tracking with accuracy: $accuracy');

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _handleLocationUpdate,
            onError: (error) {
              dev.log('Location tracking error: $error');
            },
          );

      // Start periodic update timer for force updates
      _updateTimer = Timer.periodic(_maxUpdateInterval, (_) {
        _forceLocationUpdate();
      });
    } catch (e) {
      dev.log('Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    _updateTimer?.cancel();
    _updateTimer = null;

    dev.log('Location tracking stopped');
  }

  /// Handle location updates with smart filtering
  void _handleLocationUpdate(Position position) async {
    try {
      final newLocation = LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Check if update is needed based on distance and time
      final shouldUpdate = _shouldUpdateLocation(
        newLocation,
        position.accuracy,
      );

      if (shouldUpdate) {
        await _sendLocationUpdate(
          LocationUpdateRequest(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            timestamp: DateTime.now(),
          ),
        );

        _lastKnownLocation = newLocation;
        _lastUpdateTime = DateTime.now();

        dev.log(
          'Location updated: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      dev.log('Error handling location update: $e');
    }
  }

  /// Check if location update should be sent
  bool _shouldUpdateLocation(LocationCoordinates newLocation, double accuracy) {
    // Always update if no previous location
    if (_lastKnownLocation == null) return true;

    // Always update if too much time has passed
    if (_lastUpdateTime != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastUpdateTime!);
      if (timeSinceUpdate >= _maxUpdateInterval) return true;
    }

    // Don't update too frequently
    if (_lastUpdateTime != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastUpdateTime!);
      if (timeSinceUpdate < _minUpdateInterval) return false;
    }

    // Update if moved more than threshold distance
    final distance = HeatMapService.calculateDistance(
      _lastKnownLocation!,
      newLocation,
    );

    return distance >= _updateThresholdKm;
  }

  /// Force location update (called by timer)
  void _forceLocationUpdate() async {
    try {
      final position = await getCurrentLocationCoordinates();
      if (position != null) {
        await _sendLocationUpdate(
          LocationUpdateRequest(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: 0.0, // Unknown accuracy for forced update
            timestamp: DateTime.now(),
          ),
        );

        _lastUpdateTime = DateTime.now();
        dev.log('Forced location update sent');
      }
    } catch (e) {
      dev.log('Error in forced location update: $e');
    }
  }

  /// Send location update to backend
  Future<void> _sendLocationUpdate(LocationUpdateRequest request) async {
    try {
      final apiService = sl<ApiService>();
      await apiService.put(ApiConstants.usersLocation, data: request.toJson());
    } catch (e) {
      dev.log('Error sending location update: $e');
      rethrow;
    }
  }

  /// Update location manually
  Future<bool> updateLocation(LocationCoordinates coordinates) async {
    try {
      final request = LocationUpdateRequest(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        accuracy: 0.0,
        timestamp: DateTime.now(),
      );

      await _sendLocationUpdate(request);
      _lastKnownLocation = coordinates;
      _lastUpdateTime = DateTime.now();

      return true;
    } catch (e) {
      dev.log('Error updating location manually: $e');
      return false;
    }
  }

  /// Get last known location
  LocationCoordinates? get lastKnownLocation => _lastKnownLocation;

  /// Check if location tracking is active
  bool get isTrackingActive => _locationSubscription != null;

  /// Convert LocationAccuracyLevel to Geolocator accuracy
  LocationAccuracy _getGeolocatorAccuracy(LocationAccuracyLevel accuracy) {
    switch (accuracy) {
      case LocationAccuracyLevel.low:
        return LocationAccuracy.low;
      case LocationAccuracyLevel.medium:
        return LocationAccuracy.medium;
      case LocationAccuracyLevel.high:
        return LocationAccuracy.high;
      case LocationAccuracyLevel.best:
        return LocationAccuracy.best;
    }
  }

  /// Clean up resources
  void dispose() {
    stopLocationTracking();
  }
}