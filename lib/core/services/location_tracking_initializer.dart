import 'dart:async';
import '../utils/logger.dart';
import '../models/location_models.dart' show LocationCoordinates;
import 'location_service.dart';

/// Manages location tracking initialization and lifecycle for the app
/// 
/// Best practices for dating apps:
/// - Start tracking immediately after user logs in
/// - Update location when user moves >1km (privacy + battery optimization)
/// - Send location updates to backend for matching
/// - Handle permission requests gracefully
/// - Continue tracking in background (when app is backgrounded)
class LocationTrackingInitializer {
  static final LocationTrackingInitializer _instance = LocationTrackingInitializer._internal();
  factory LocationTrackingInitializer() => _instance;
  LocationTrackingInitializer._internal();

  final LocationService _locationService = LocationService();
  bool _isInitialized = false;
  bool _isTracking = false;

  /// Initialize location tracking for authenticated user
  /// Should be called immediately after successful login
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('📍 Location tracking already initialized');
      return true;
    }

    try {
      AppLogger.info('📍 Initializing location tracking...');

      // Request location permissions
      final permissionStatus = await _locationService.requestPermissions(
        showRationale: true,
      );

      if (permissionStatus != LocationPermissionStatus.granted) {
        AppLogger.warning(
          '📍 Location permission not granted: $permissionStatus',
        );
        _handlePermissionDenied(permissionStatus);
        return false;
      }

      // Get current location immediately
      final currentLocation = await _locationService.getCurrentLocationCoordinates(
        accuracy: LocationAccuracyLevel.high,
      );

      if (currentLocation != null) {
        AppLogger.info(
          '📍 Got initial location: ${currentLocation.latitude}, ${currentLocation.longitude}',
        );

        // Update backend with current location
        await _locationService.updateLocation(currentLocation);
        AppLogger.info('📍 Initial location sent to backend');
      }

      // Start continuous location tracking
      await _locationService.startLocationTracking(
        accuracy: LocationAccuracyLevel.medium, // Balance accuracy vs battery
      );

      _isInitialized = true;
      _isTracking = true;

      AppLogger.info('✅ Location tracking initialized successfully');
      AppLogger.info('📍 Tracking with 1km update threshold (dating app best practice)');
      
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to initialize location tracking: $e');
      _isInitialized = false;
      _isTracking = false;
      return false;
    }
  }

  /// Handle permission denied scenarios
  void _handlePermissionDenied(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.denied:
        AppLogger.warning(
          '📍 Location permission denied - user can grant it later in settings',
        );
        break;
      case LocationPermissionStatus.permanentlyDenied:
        AppLogger.warning(
          '📍 Location permission permanently denied - user must enable in device settings',
        );
        break;
      case LocationPermissionStatus.restricted:
        AppLogger.warning(
          '📍 Location permission restricted (parental controls)',
        );
        break;
      case LocationPermissionStatus.unknown:
        AppLogger.warning('📍 Location permission status unknown');
        break;
      case LocationPermissionStatus.granted:
        break;
    }
  }

  /// Stop location tracking (called on logout)
  Future<void> stop() async {
    if (!_isTracking) {
      return;
    }

    try {
      await _locationService.stopLocationTracking();
      _isTracking = false;
      _isInitialized = false;
      AppLogger.info('📍 Location tracking stopped');
    } catch (e) {
      AppLogger.error('❌ Error stopping location tracking: $e');
    }
  }

  /// Manually update location (for pull-to-refresh or manual refresh)
  Future<bool> forceLocationUpdate() async {
    if (!_isInitialized) {
      AppLogger.warning('📍 Cannot force update - tracking not initialized');
      return false;
    }

    try {
      final location = await _locationService.getCurrentLocationCoordinates(
        accuracy: LocationAccuracyLevel.high,
      );

      if (location != null) {
        await _locationService.updateLocation(location);
        AppLogger.info('📍 Manual location update successful');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('❌ Failed to force location update: $e');
      return false;
    }
  }

  /// Get current tracking status
  bool get isTracking => _isTracking;

  /// Get last known location
  LocationCoordinates? get lastKnownLocation => _locationService.lastKnownLocation;

  /// Check if location services are available
  Future<bool> isLocationAvailable() async {
    final status = await _locationService.getPermissionStatus();
    return status == LocationPermissionStatus.granted;
  }
}
