import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/heat_map_service.dart';
import '../../core/services/location_service.dart';
import '../../data/models/heat_map_models.dart';
import '../../core/models/location_models.dart';
import '../../data/models/location_models.dart' as data_models;
import '../../features/statistics/data/services/map_clustering_service.dart';
import '../../features/statistics/domain/models/map_cluster.dart';

// Function to show the heat map as a full-screen modal
void showHeatMapModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (modalContext) => Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: const HeatMapScreen(),
    ),
  );
}

// BLoC Events
abstract class HeatMapEvent {}

class LoadHeatMapData extends HeatMapEvent {
  final int radiusKm;
  LoadHeatMapData(this.radiusKm);
}

class UpdateRadius extends HeatMapEvent {
  final int radiusKm;
  UpdateRadius(this.radiusKm);
}

class RefreshLocation extends HeatMapEvent {}

// BLoC States
abstract class HeatMapState {}

class HeatMapInitial extends HeatMapState {}

class HeatMapLoading extends HeatMapState {}

class HeatMapLoaded extends HeatMapState {
  final HeatMapData heatmapData;
  final LocationCoverageData coverageData;
  final LocationCoordinates? userLocation;
  final int currentRadius;

  HeatMapLoaded({
    required this.heatmapData,
    required this.coverageData,
    this.userLocation,
    required this.currentRadius,
  });
}

class HeatMapError extends HeatMapState {
  final String message;
  HeatMapError(this.message);
}

// BLoC
class HeatMapBloc extends Bloc<HeatMapEvent, HeatMapState> {
  final HeatMapService _heatMapService;
  final LocationService _locationService;

  HeatMapBloc(this._heatMapService, this._locationService) : super(HeatMapInitial()) {
    on<LoadHeatMapData>(_onLoadHeatMapData);
    on<UpdateRadius>(_onUpdateRadius);
    on<RefreshLocation>(_onRefreshLocation);
  }

  Future<void> _onLoadHeatMapData(LoadHeatMapData event, Emitter<HeatMapState> emit) async {
    emit(HeatMapLoading());
    
    try {
      print('HeatMapBloc: Starting location request...');
      final position = await _locationService.getCurrentLocation();
      print('HeatMapBloc: Location result: $position');
      
      final userCoords = position != null 
        ? LocationCoordinates(latitude: position.latitude, longitude: position.longitude) 
        : null;
      
      if (userCoords == null) {
        print('HeatMapBloc: No location available, emitting error');
        emit(
          HeatMapError(
            'Unable to get current location. Please enable location services and grant permission.',
          ),
        );
        return;
      }
      
      // First, update user location in backend
      print('HeatMapBloc: Updating user location in backend...');
      try {
        await _heatMapService.updateUserLocation(userCoords);
        print('HeatMapBloc: User location updated successfully');
      } catch (e) {
        print('HeatMapBloc: Failed to update user location: $e');
        // Continue anyway - try to fetch data without updating location
      }
      print('HeatMapBloc: Now fetching heat map data...');
      
      final [heatmapDataPoints, coverageData] = await Future.wait([
        _heatMapService.getHeatMapData(),
        _heatMapService.getLocationCoverageData(
          center: userCoords,
          radiusKm: event.radiusKm.toDouble(),
        ),
      ]);
      
      final points = heatmapDataPoints as List<HeatMapDataPoint>;
      final coverage = coverageData as LocationCoverageData;
      
      // Create HeatMapData from points
      final heatmapData = HeatMapData(
        dataPoints: points,
        bounds: LocationBounds(
          northLatitude: points.isNotEmpty 
            ? points.map((p) => p.coordinates.latitude).reduce((a, b) => a > b ? a : b) + 0.01
            : userCoords.latitude + 0.01,
          southLatitude: points.isNotEmpty 
            ? points.map((p) => p.coordinates.latitude).reduce((a, b) => a < b ? a : b) - 0.01
            : userCoords.latitude - 0.01,
          eastLongitude: points.isNotEmpty 
            ? points.map((p) => p.coordinates.longitude).reduce((a, b) => a > b ? a : b) + 0.01
            : userCoords.longitude + 0.01,
          westLongitude: points.isNotEmpty 
            ? points.map((p) => p.coordinates.longitude).reduce((a, b) => a < b ? a : b) - 0.01
            : userCoords.longitude - 0.01,
        ),
        totalUsers: points.length,
        averageDensity: points.isNotEmpty 
          ? points.map((p) => p.density).reduce((a, b) => a + b) / points.length
          : 0.0,
        generatedAt: DateTime.now(),
      );
      
      emit(HeatMapLoaded(
        heatmapData: heatmapData,
        coverageData: coverage,
        userLocation: userCoords,
        currentRadius: event.radiusKm,
      ));
    } catch (e) {
      emit(HeatMapError('Failed to load heat map data: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRadius(UpdateRadius event, Emitter<HeatMapState> emit) async {
    add(LoadHeatMapData(event.radiusKm));
  }

  Future<void> _onRefreshLocation(RefreshLocation event, Emitter<HeatMapState> emit) async {
    final currentState = state;
    if (currentState is HeatMapLoaded) {
      add(LoadHeatMapData(currentState.currentRadius));
    } else {
      add(LoadHeatMapData(50)); // Default radius
    }
  }
}

// Heat Map Screen Widget
class HeatMapScreen extends StatefulWidget {
  const HeatMapScreen({Key? key}) : super(key: key);

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen> {
  GoogleMapController? _mapController;
  int _currentRadius = 50;
  MapType _mapType = MapType.normal;
  double _currentZoom = 6.0;
  bool _showHeatmap = false; // Disabled by default for better UX
  
  // Debouncing for camera movements to optimize performance
  Timer? _debounceTimer;
  bool _isMapReady = false;
  bool _isUpdatingClusters = false;
  
  // Cache management
  DateTime? _lastDataFetch;
  static const Duration _cacheValidity = Duration(minutes: 5);
  List<MapCluster>? _cachedClusters;
  
  // Performance tracking
  // Clustering performance tracking (removed unused counter)

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Check if cached data is still valid
  bool _isCacheValid() {
    if (_lastDataFetch == null || _cachedClusters == null) return false;
    return DateTime.now().difference(_lastDataFetch!) < _cacheValidity;
  }

  /// Toggle heatmap visibility
  void _toggleHeatmap() {
    setState(() {
      _showHeatmap = !_showHeatmap;
    });
    
    // If enabling heatmap and we need fresh data, trigger reload
    if (_showHeatmap && !_isCacheValid()) {
      context.read<HeatMapBloc>().add(LoadHeatMapData(_currentRadius));
    }
  }

  /// Get maximum clusters based on zoom level for optimal performance
  int _getMaxClustersForZoom(double zoom) {
    if (zoom >= 16) return 100; // Very zoomed in - more detail
    if (zoom >= 14) return 75;  // Zoomed in - good detail
    if (zoom >= 12) return 50;  // Medium zoom - balanced
    if (zoom >= 10) return 30;  // Zoomed out - fewer clusters
    return 20; // Very zoomed out - minimal clusters
  }

  /// Update clusters based on current zoom level with debouncing
  void _updateClustersForZoom() {
    if (_isUpdatingClusters || !_isMapReady) return;

    _isUpdatingClusters = true;

    // Trigger a rebuild with current zoom level
    if (mounted) {
      setState(() {
        // Force rebuild to update clusters
      });
    }

    // Reset flag after a short delay
    Timer(const Duration(milliseconds: 100), () {
      _isUpdatingClusters = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access services from the parent context before creating BlocProvider
    final heatMapService = context.read<HeatMapService>();
    final locationService = context.read<LocationService>();
    
    return BlocProvider(
      create: (context) => HeatMapBloc(
        heatMapService, locationService,
      )..add(LoadHeatMapData(_currentRadius)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
        child: SafeArea(
          child: Column(
            children: [
              _buildModalHeader(context),
              Expanded(
                child: BlocBuilder<HeatMapBloc, HeatMapState>(
                  builder: (context, state) {
                    if (state is HeatMapLoading) {
                      return _buildLoadingState();
                    } else if (state is HeatMapLoaded) {
                      return _buildMapWithData(context, state);
                    } else if (state is HeatMapError) {
                      return _buildErrorState(context, state);
                    }
                    return _buildInitialState(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Map Coverage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showHeatmap ? const Color(0xFF00C2FF) : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.scatter_plot, color: Colors.white, size: 20),
            ),
            onPressed: _toggleHeatmap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6E3BFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
            onPressed: () => _showRadiusSelector(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E3BFF)),
            ),
            SizedBox(height: 24),
            Text(
              'Loading map data...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWithData(BuildContext context, HeatMapLoaded state) {
    print(
      'HeatMapScreen: Building map with data - userLocation: ${state.userLocation}, dataPoints: ${state.heatmapData.dataPoints.length}, radius: ${state.currentRadius}',
    );
    return Stack(
      children: [
        // Full screen Google Map
        Positioned.fill(child: _buildGoogleMap(state)),
        // Cluster number overlays
        ..._buildClusterNumberOverlays(state),
        // Map controls overlay
        _buildMapControls(context),
        // Map overlay info
        _buildMapOverlay(context, state),
        // Stats panel
        _buildStatsPanel(context, state),
        // Loading overlay during cluster updates
        if (_isUpdatingClusters)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Updating clusters...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGoogleMap(HeatMapLoaded state) {
    print('HeatMapScreen: Building GoogleMap widget');
    print('HeatMapScreen: User location: ${state.userLocation}');
    print(
      'HeatMapScreen: Heatmap data points: ${state.heatmapData.dataPoints.length}',
    );

    // Determine best position for map camera
    LatLng initialPosition;
    bool hasGeographicMismatch = false;

    print('HeatMapScreen: 🔍 Checking data points for geographic mismatch...');
    print(
      'HeatMapScreen: Data points count: ${state.heatmapData.dataPoints.length}',
    );

    if (state.heatmapData.dataPoints.isNotEmpty) {
      final firstPoint = state.heatmapData.dataPoints.first;
      final lastPoint = state.heatmapData.dataPoints.last;
      print(
        'HeatMapScreen: First data point: ${firstPoint.coordinates.latitude}, ${firstPoint.coordinates.longitude}',
      );
      print(
        'HeatMapScreen: Last data point: ${lastPoint.coordinates.latitude}, ${lastPoint.coordinates.longitude}',
      );

      // Check if user location and data are on different continents
      final userLat = state.userLocation?.latitude ?? 0;
      final dataLat = firstPoint.coordinates.latitude;
      print('HeatMapScreen: 🔍 User latitude: $userLat');
      print('HeatMapScreen: 🔍 Data latitude: $dataLat');
      print('HeatMapScreen: 🔍 User > 0: ${userLat > 0}');
      print('HeatMapScreen: 🔍 Data < 0: ${dataLat < 0}');
      print('HeatMapScreen: 🔍 User < 0: ${userLat < 0}');
      print('HeatMapScreen: 🔍 Data > 0: ${dataLat > 0}');

      hasGeographicMismatch =
          (userLat > 0 && dataLat < 0) || (userLat < 0 && dataLat > 0);
      print(
        'HeatMapScreen: 🔍 Geographic mismatch detected: $hasGeographicMismatch',
      );

      if (hasGeographicMismatch) {
        print(
          'HeatMapScreen: ⚠️ WARNING: User location and data points are on different continents!',
        );
        print('HeatMapScreen: User: $userLat, Data: $dataLat');
        print(
          'HeatMapScreen: Centering map on data cluster instead of user location',
        );

        // Calculate center of data points
        final avgLat =
            state.heatmapData.dataPoints
                .map((p) => p.coordinates.latitude)
                .reduce((a, b) => a + b) /
            state.heatmapData.dataPoints.length;
        final avgLng =
            state.heatmapData.dataPoints
                .map((p) => p.coordinates.longitude)
                .reduce((a, b) => a + b) /
            state.heatmapData.dataPoints.length;

        initialPosition = LatLng(avgLat, avgLng);
        print('HeatMapScreen: Data center position: $initialPosition');
      } else {
        // Use user location if data is in same region
        initialPosition = state.userLocation != null
            ? LatLng(
                state.userLocation!.latitude,
                state.userLocation!.longitude,
              )
            : LatLng(
                firstPoint.coordinates.latitude,
                firstPoint.coordinates.longitude,
              );
      }
    } else {
      // No data points, use user location or default
      initialPosition = state.userLocation != null
          ? LatLng(state.userLocation!.latitude, state.userLocation!.longitude)
          : const LatLng(-26.2041028, 28.0473051); // Default to Johannesburg
    }

    print('HeatMapScreen: Initial position: $initialPosition');

    final markers = _buildMarkers(state);
    final circles = _buildCircles(state);

    print(
      'HeatMapScreen: Built ${markers.length} markers and ${circles.length} circles',
    );

    print('🗺️ About to build GoogleMap widget...');
    print('🗺️ Initial position: $initialPosition');
    print('🗺️ Markers count: ${markers.length}');
    print('🗺️ Circles count: ${circles.length}');

    return GoogleMap(
      key: const ValueKey('heat_map_google_map'),
      onMapCreated: (GoogleMapController controller) async {
        _mapController = controller;
        print('🗺️ HeatMapScreen: Google Maps created successfully');
        print('🔧 Map Controller Type: ${controller.runtimeType}');
        print('🔧 Map ID: ${controller.mapId}');
        
        // Check if map tiles are loading by testing a basic operation
        try {
          final bounds = await controller.getVisibleRegion();
          print('🔧 Visible region obtained: ${bounds.toString()}');
          print('🔧 This indicates map tiles should be loading');
        } catch (e) {
          print('🔧 ERROR: Cannot get visible region - $e');
          print('🔧 This may indicate API key or network issues');
        }

        // Wait for map to be fully initialized before camera operations
        await Future.delayed(const Duration(milliseconds: 200));

        if (mounted && _mapController != null) {
          final zoomLevel = hasGeographicMismatch ? 8.0 : 12.0;
          print('🗺️ Moving camera to: $initialPosition, zoom: $zoomLevel');

          try {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: initialPosition, zoom: zoomLevel),
              ),
            );
            print('🗺️ Camera positioned successfully');

            // Test tile loading after positioning
            await Future.delayed(const Duration(milliseconds: 500));
            final newBounds = await controller.getVisibleRegion();
            print('🔧 Post-animation visible region: ${newBounds.toString()}');
          } catch (e) {
            print('🗺️ Camera positioning error: $e');
          }
        }
      },
      onCameraMove: (CameraPosition position) {
        if (mounted) {
          setState(() {
            _currentZoom = position.zoom;
          });
          print('🗺️ Zoom changed to: $_currentZoom');
          
          // Debounce cluster updates during camera movement
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted && !_isUpdatingClusters) {
              _updateClustersForZoom();
            }
          });
        }
      },
      onCameraIdle: () {
        _isMapReady = true;
        print('🗺️ Camera idle at zoom: $_currentZoom');
        
        // Cancel any pending debounced updates
        _debounceTimer?.cancel();

        // Update clusters immediately when camera stops
        if (mounted && !_isUpdatingClusters) {
          _updateClustersForZoom();
        }
      },
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 10.0, // Safe initial zoom level
      ),
      markers: markers,
      circles: circles,
      mapType: _mapType,
      // Essential tile rendering settings
      minMaxZoomPreference: const MinMaxZoomPreference(2.0, 20.0),
      cameraTargetBounds: CameraTargetBounds.unbounded,
      // UI Controls
      zoomControlsEnabled: false,
      compassEnabled: true,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      // Gesture settings
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      // Performance settings
      liteModeEnabled: false,
      // Map features
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: true,
    );
  }

  /// Build cluster circles for privacy (no individual markers)
  Set<Circle> _buildClusterCircles(HeatMapLoaded state) {
    final clusterCircles = <Circle>{};

    // Note: User location shown via myLocationEnabled: true (Google blue dot)
    print('HeatMapScreen: User location will be shown via Google blue dot');
    if (state.userLocation != null) {
      print(
        'HeatMapScreen: User location coordinates: ${state.userLocation!.latitude}, ${state.userLocation!.longitude}',
      );
    }

    // Cluster the data points based on zoom level
    print(
      'HeatMapScreen: 🔍 Starting privacy clustering for ${state.heatmapData.dataPoints.length} data points at zoom $_currentZoom',
    );
    final clusters = MapClusteringService.clusterDataPoints(
      state.heatmapData.dataPoints,
      _currentZoom,
    );
    print(
      'HeatMapScreen: 🎯 Privacy clustering completed: ${clusters.length} clusters from ${state.heatmapData.dataPoints.length} points',
    );
    
    // Debug cluster details
    for (int i = 0; i < clusters.length && i < 5; i++) {
      final cluster = clusters[i];
      print(
        'HeatMapScreen: 🔍 Privacy Cluster $i: ${cluster.count} points, ${cluster.totalUserCount} users at ${cluster.position}',
      );
    }

    // Add cluster circles - PRIVACY: Show as circles with user count, never individual locations
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      print(
        'HeatMapScreen: 🔐 Adding PRIVACY CLUSTER circle $i at ${cluster.position.latitude}, ${cluster.position.longitude} with ${cluster.count} points (${cluster.totalUserCount} users)',
      );
      
      // Create privacy cluster circles with size based on user count
      final circleRadius = _getClusterRadius(cluster.totalUserCount);
      final circleColor = _getClusterColor(cluster.dominantStatus);

      print('🔵 Creating circle: id=${cluster.id}, center=${cluster.position}, radius=${circleRadius}m, color=$circleColor');
      
      clusterCircles.add(
        Circle(
          circleId: CircleId(cluster.id),
          center: cluster.position,
          radius: circleRadius,
          fillColor: circleColor.withValues(alpha: 0.4), // Slightly more opaque
          strokeColor: circleColor,
          strokeWidth: 3, // Thicker stroke for visibility
          onTap: () => _showClusterDetails(cluster),
        ),
      );
    }

    print(
      'HeatMapScreen: Total privacy cluster circles built: ${clusterCircles.length}',
    );
    return clusterCircles;
  }

  /// No individual markers for privacy - using empty set
  Set<Marker> _buildMarkers(HeatMapLoaded state) {
    // PRIVACY: Return empty markers set - all user locations shown as clusters only
    print(
      'HeatMapScreen: 🔐 No individual markers for privacy - using cluster circles only',
    );
    return <Marker>{};
  }

  Set<Circle> _buildCircles(HeatMapLoaded state) {
    final circles = <Circle>{};

    // Add user coverage circle (always shown)
    if (state.userLocation != null) {
      circles.add(
        Circle(
          circleId: const CircleId('coverage_circle'),
          center: LatLng(
            state.userLocation!.latitude,
            state.userLocation!.longitude,
          ),
          radius: state.currentRadius * 1000.0, // Convert km to meters
          fillColor: const Color(0xFF6E3BFF).withValues(alpha: 0.1),
          strokeColor: const Color(0xFF6E3BFF),
          strokeWidth: 2,
        ),
      );
    }

    // Only add cluster/heatmap circles when heatmap is enabled
    if (_showHeatmap) {
      // Add privacy cluster circles
      circles.addAll(_buildClusterCircles(state));
      
      // Add heatmap overlay circles
      circles.addAll(_buildHeatmapCircles(state));
    }

    return circles;
  }

  /// Build heatmap overlay circles for density visualization
  Set<Circle> _buildHeatmapCircles(HeatMapLoaded state) {
    final heatmapCircles = <Circle>{};

    for (int i = 0; i < state.heatmapData.dataPoints.length; i++) {
      final point = state.heatmapData.dataPoints[i];

      // Create heatmap circle based on density
      final heatmapRadius = _getHeatmapRadius(point.density);
      final heatmapColor = _getHeatmapColor(point.density);

      heatmapCircles.add(
        Circle(
          circleId: CircleId('heatmap_$i'),
          center: LatLng(
            point.coordinates.latitude,
            point.coordinates.longitude,
          ),
          radius: heatmapRadius,
          fillColor: heatmapColor.withValues(alpha: 0.4),
          strokeColor: heatmapColor.withValues(alpha: 0.8),
          strokeWidth: 1,
        ),
      );
    }

    print(
      'HeatMapScreen: Built ${heatmapCircles.length} heatmap overlay circles',
    );
    return heatmapCircles;
  }

  /// Get heatmap circle radius based on density
  double _getHeatmapRadius(int density) {
    // Radius scales with density for visual impact
    if (density <= 2) return 50.0;
    if (density <= 5) return 100.0;
    if (density <= 10) return 150.0;
    if (density <= 20) return 200.0;
    return 300.0; // High density areas
  }

  /// Get heatmap color based on density (heat gradient)
  Color _getHeatmapColor(int density) {
    // Heat gradient: blue (low) -> green -> yellow -> red (high)
    if (density <= 2) return const Color(0xFF0000FF); // Blue
    if (density <= 5) return const Color(0xFF00FF00); // Green
    if (density <= 10) return const Color(0xFFFFFF00); // Yellow
    if (density <= 20) return const Color(0xFFFF8000); // Orange
    return const Color(0xFFFF0000); // Red
  }

  /// Build cluster number overlays positioned over cluster circles
  List<Widget> _buildClusterNumberOverlays(HeatMapLoaded state) {
    if (_mapController == null) return [];

    final overlays = <Widget>[];

    // Get clusters for positioning
    final clusters = MapClusteringService.clusterDataPoints(
      state.heatmapData.dataPoints,
      _currentZoom,
    );

    for (final cluster in clusters) {
      overlays.add(_buildClusterNumberOverlay(cluster));
    }

    return overlays;
  }

  /// Build individual cluster number overlay
  Widget _buildClusterNumberOverlay(MapCluster cluster) {
    return FutureBuilder<ScreenCoordinate?>(
      future: _mapController?.getScreenCoordinate(cluster.position),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final screenCoords = snapshot.data!;
        final clusterColor = _getClusterColor(cluster.dominantStatus);

        return Positioned(
          left: screenCoords.x.toDouble() - 20, // Center the overlay
          top: screenCoords.y.toDouble() - 20,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: clusterColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${cluster.totalUserCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get cluster circle radius based on user count AND zoom level (for privacy visualization)
  double _getClusterRadius(int userCount) {
    // Base radius scales with user count AND zoom level for visibility
    double baseRadius;
    if (userCount <= 5) {
      baseRadius = 100.0;
    } else if (userCount <= 10) {
      baseRadius = 150.0;
    } else if (userCount <= 25) {
      baseRadius = 200.0;
    } else if (userCount <= 50) {
      baseRadius = 300.0;
    } else {
      baseRadius = 400.0; // Max radius for very large clusters
    }
    
    // Scale radius based on zoom level for visibility
    double zoomMultiplier;
    if (_currentZoom <= 6) {
      zoomMultiplier = 50.0; // Very large at continent level
    } else if (_currentZoom <= 8) {
      zoomMultiplier = 25.0; // Large at country level
    } else if (_currentZoom <= 10) {
      zoomMultiplier = 12.0; // Medium at region level
    } else if (_currentZoom <= 12) {
      zoomMultiplier = 6.0; // Smaller at city level
    } else if (_currentZoom <= 15) {
      zoomMultiplier = 3.0; // Small at district level
    } else {
      zoomMultiplier = 1.5; // Minimum at street level
    }
    
    final finalRadius = baseRadius * zoomMultiplier;
    print('🎯 Cluster radius calculation: userCount=$userCount, zoom=$_currentZoom, base=$baseRadius, multiplier=$zoomMultiplier, final=${finalRadius}m');
    return finalRadius;
  }

  /// Get cluster circle color based on dominant status
  Color _getClusterColor(String dominantStatus) {
    switch (dominantStatus.toLowerCase()) {
      case 'matched':
        return const Color(0xFF4CAF50); // Green
      case 'liked_me':
      case 'likedme':
        return const Color(0xFFFF9800); // Orange  
      case 'unmatched':
      case 'available':
        return const Color(0xFF2196F3); // Blue
      case 'passed':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  void _showClusterDetails(MapCluster cluster) {
    // Calculate detailed statistics
    final statusBreakdown = <String, Map<String, dynamic>>{};
    int totalUsers = 0;
    double totalDensity = 0;

    for (final point in cluster.dataPoints) {
      final status = point.label ?? 'Unknown';
      final users = point.density;
      totalUsers += users;
      totalDensity += point.density;

      statusBreakdown.putIfAbsent(
        status,
        () => {'users': 0, 'points': 0, 'avgDensity': 0.0},
      );

      statusBreakdown[status]!['users'] += users;
      statusBreakdown[status]!['points'] += 1;
    }

    // Calculate average densities
    for (final status in statusBreakdown.keys) {
      final data = statusBreakdown[status]!;
      data['avgDensity'] = data['users'] / data['points'];
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getClusterColor(cluster.dominantStatus),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cluster Analysis',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Overview Statistics
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow('Total Users', '$totalUsers'),
                      _buildStatRow('Data Points', '${cluster.count}'),
                      _buildStatRow('Dominant Status', cluster.dominantStatus),
                      _buildStatRow(
                        'Cluster Radius',
                        '${(cluster.radius / 1000).toStringAsFixed(1)} km',
                      ),
                      _buildStatRow(
                        'Average Density',
                        '${(totalDensity / cluster.count).toStringAsFixed(1)} users/point',
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        '📍 Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Latitude',
                        cluster.position.latitude.toStringAsFixed(6),
                      ),
                      _buildStatRow(
                        'Longitude',
                        cluster.position.longitude.toStringAsFixed(6),
                      ),
                      _buildStatRow(
                        'Zoom Level',
                        '${_currentZoom.toStringAsFixed(1)}x',
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        '👥 Status Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status breakdown with visual indicators
                      ...statusBreakdown.entries.map((entry) {
                        final status = entry.key;
                        final data = entry.value;
                        final percentage = ((data['users'] / totalUsers) * 100)
                            .toStringAsFixed(1);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getClusterColor(
                              status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getClusterColor(
                                status,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getClusterColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getStatusDisplayName(status),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$percentage%',
                                    style: TextStyle(
                                      color: _getClusterColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${data['users']} users'),
                                  Text('${data['points']} points'),
                                  Text(
                                    '${data['avgDensity'].toStringAsFixed(1)} avg density',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),
                      const Text(
                        '🔒 Privacy Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Individual locations are never shown'),
                            Text('• Users are grouped by status for privacy'),
                            Text('• Minimum cluster radius enforced'),
                            Text('• Positions are stable across zoom levels'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'matched':
        return '💖 Matched';
      case 'liked_me':
      case 'likedme':
        return '💕 Liked Me';
      case 'unmatched':
      case 'available':
        return '👋 Available';
      case 'passed':
        return '❌ Passed';
      default:
        return '❓ Unknown';
    }
  }

  Widget _buildMapOverlay(BuildContext context, HeatMapLoaded state) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coverage: ${state.currentRadius} km radius',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zoom Level: ${_currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Matched', Colors.green, '✨'),
        _buildLegendItem('Liked Me', Colors.orange, '❤️'),
        _buildLegendItem('Available', Colors.blue, '👋'),
        _buildLegendItem('Passed', Colors.red, '👎'),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String emoji) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          emoji,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel(BuildContext context, HeatMapLoaded state) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6E3BFF).withValues(alpha: 0.9),
              const Color(0xFF00C2FF).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'People in your area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white, size: 18),
                  onPressed: () => _showRadiusSelector(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatItem(
                    'Total Users',
                    state.coverageData.totalUsers,
                    '👥',
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    'Avg Density',
                    state.coverageData.averageDensity.toInt(),
                    '📊',
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    'Coverage',
                    '${(state.coverageData.totalCoverage * 100).toStringAsFixed(1)}%',
                    '🗺️',
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    'Areas Found',
                    state.coverageData.coverageAreas.length,
                    '📍',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, String emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, HeatMapError state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<HeatMapBloc>().add(LoadHeatMapData(_currentRadius));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E3BFF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<HeatMapBloc>().add(LoadHeatMapData(_currentRadius));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E3BFF),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Load Map',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }



  void _showRadiusSelector(BuildContext context) {
    final heatMapBloc = context.read<HeatMapBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => BlocProvider.value(
        value: heatMapBloc,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          builder: (sheetContext, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Radius',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...data_models.DistancePreference.predefinedOptions
                              .map(
                                (option) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    option.displayText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: _currentRadius == option.distanceKm
                                      ? const Icon(
                                          Icons.check,
                                          color: Color(0xFF6E3BFF),
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _currentRadius = option.distanceKm;
                                    });
                                    heatMapBloc.add(
                                      UpdateRadius(option.distanceKm),
                                    );
                                    Navigator.pop(modalContext);
                                  },
                                ),
                              ),
                          const SizedBox(height: 24), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }







  Widget _buildMapControls(BuildContext context) {
    return Positioned(
      top: 120,
      right: 16,
      child: Column(
        children: [
          // Map Type Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<MapType>(
              icon: const Icon(Icons.layers),
              onSelected: (MapType type) {
                setState(() {
                  _mapType = type;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: MapType.normal,
                  child: Row(
                    children: [
                      Icon(Icons.map),
                      SizedBox(width: 8),
                      Text('Normal'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: MapType.satellite,
                  child: Row(
                    children: [
                      Icon(Icons.satellite),
                      SizedBox(width: 8),
                      Text('Satellite'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: MapType.hybrid,
                  child: Row(
                    children: [
                      Icon(Icons.terrain),
                      SizedBox(width: 8),
                      Text('Hybrid'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Zoom Controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const Divider(height: 1),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Heatmap Toggle
          Container(
            decoration: BoxDecoration(
              color: _showHeatmap ? const Color(0xFF6E3BFF) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.gradient,
                color: _showHeatmap ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _showHeatmap = !_showHeatmap;
                });
              },
              tooltip: _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
            ),
          ),
          const SizedBox(height: 8),
          // My Location Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () async {
                final state = context.read<HeatMapBloc>().state;
                if (state is HeatMapLoaded && state.userLocation != null) {
                  await _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        state.userLocation!.latitude,
                        state.userLocation!.longitude,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}