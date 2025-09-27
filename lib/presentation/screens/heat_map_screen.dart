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
        // Map controls overlay
        _buildMapControls(context),
        // Map overlay info
        _buildMapOverlay(context, state),
        // Stats panel
        _buildStatsPanel(context, state),
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

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        print('🗺️ Google Maps created successfully with controller');
        print('🗺️ Map type: $_mapType');
        print('🗺️ Buildings enabled: true');
        print('🗺️ Indoor view enabled: true');
        print('🗺️ Lite mode enabled: false');
        print('🗺️ Traffic enabled: false');
        print('🗺️ Initial zoom level: $_currentZoom');

        // Small delay to ensure map is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _mapController != null) {
            final zoomLevel = hasGeographicMismatch
                ? 6.0
                : _getZoomLevel(state.currentRadius);
            print(
              '🗺️ Animating camera to position: $initialPosition with zoom: $zoomLevel',
            );
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: initialPosition, zoom: zoomLevel),
              ),
            );
            print('🗺️ Camera animation complete');
          } else {
            print(
              '🗺️ Cannot animate camera - mounted: $mounted, controller: ${_mapController != null}',
            );
          }
        });
      },
      onCameraMove: (CameraPosition position) {
        setState(() {
          _currentZoom = position.zoom;
        });
        print('🗺️ Zoom changed to: $_currentZoom');
      },
      onCameraIdle: () {
        print('🗺️ Camera idle at zoom: $_currentZoom');
      },
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: hasGeographicMismatch
            ? 6.0
            : 12.0, // Lower zoom for data clusters
      ),
      markers: markers,
      circles: circles,
      mapType: _mapType,
      zoomControlsEnabled: false,
      compassEnabled: true,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      mapToolbarEnabled: false,
      liteModeEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: true,
    );
  }

  Set<Marker> _buildMarkers(HeatMapLoaded state) {
    final markers = <Marker>{};

    // Note: User location now shown via myLocationEnabled: true (Google blue dot)
    print('HeatMapScreen: User location will be shown via Google blue dot');
    if (state.userLocation != null) {
      print(
        'HeatMapScreen: User location coordinates: ${state.userLocation!.latitude}, ${state.userLocation!.longitude}',
      );
    } else {
      print('HeatMapScreen: User location is null');
    }

    // Cluster the data points based on zoom level
    print('HeatMapScreen: 🔍 Starting clustering for ${state.heatmapData.dataPoints.length} data points at zoom $_currentZoom');
    final clusters = MapClusteringService.clusterDataPoints(
      state.heatmapData.dataPoints,
      _currentZoom,
    );
    print('HeatMapScreen: 🎯 Clustering completed: ${clusters.length} clusters from ${state.heatmapData.dataPoints.length} points');
    
    // Debug cluster details
    for (int i = 0; i < clusters.length && i < 5; i++) {
      final cluster = clusters[i];
      print('HeatMapScreen: 🔍 Cluster $i: ${cluster.count} points, ${cluster.totalUserCount} users at ${cluster.position}');
    }

    // Add cluster markers - ALWAYS use cluster markers for privacy
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      print(
        'HeatMapScreen: 🔐 Adding CLUSTER marker $i at ${cluster.position.latitude}, ${cluster.position.longitude} with ${cluster.count} points (${cluster.totalUserCount} users)',
      );
      
      // Always create cluster markers for privacy - never show individual locations
      markers.add(
        Marker(
          markerId: MarkerId(cluster.id),
          position: cluster.position,
          icon: _getClusterMarkerIcon(cluster.totalUserCount, cluster.dominantStatus),
          onTap: () => _showClusterDetails(cluster),
        ),
      );
    }

    print('HeatMapScreen: Total markers built: ${markers.length}');
    return markers;
  }

  Set<Circle> _buildCircles(HeatMapLoaded state) {
    if (state.userLocation == null) return {};

    return {
      Circle(
        circleId: const CircleId('coverage_circle'),
        center: LatLng(state.userLocation!.latitude, state.userLocation!.longitude),
        radius: state.currentRadius * 1000.0, // Convert km to meters
        fillColor: const Color(0xFF6E3BFF).withOpacity(0.1),
        strokeColor: const Color(0xFF6E3BFF),
        strokeWidth: 2,
      ),
    };
  }

  BitmapDescriptor _getMarkerIcon(String status) {
    switch (status) {
      case 'matched':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'liked_me':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'unmatched':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'passed':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  BitmapDescriptor _getClusterMarkerIcon(int userCount, String dominantStatus) {
    // For now, use the dominant status color with default marker
    // In a full implementation, you'd create custom cluster icons with numbers
    switch (dominantStatus.toLowerCase()) {
      case 'matched':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'liked_me':
      case 'likedme':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'unmatched':
      case 'available':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'passed':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _showClusterDetails(MapCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cluster Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Users: ${cluster.totalUserCount}'),
            Text('Data Points: ${cluster.count}'),
            Text('Dominant Status: ${cluster.dominantStatus}'),
            Text('Location: ${cluster.position.latitude.toStringAsFixed(4)}, ${cluster.position.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 16),
            const Text('Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...cluster.dataPoints.map((point) => 
              Text('• ${point.label ?? 'Unknown'}: ${point.density} users')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapOverlay(BuildContext context, HeatMapLoaded state) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
              const Color(0xFF6E3BFF).withOpacity(0.9),
              const Color(0xFF00C2FF).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                    color: Colors.white.withOpacity(0.3),
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

  void _showMarkerDetails(HeatMapDataPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          point.label ?? 'User Density Area',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Density: ${point.density} users\nRadius: ${point.radius.toStringAsFixed(0)}m',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF6E3BFF)),
            ),
          ),
        ],
      ),
    );
  }



  double _getZoomLevel(int radiusKm) {
    if (radiusKm <= 5) return 14.0;
    if (radiusKm <= 10) return 13.0;
    if (radiusKm <= 25) return 11.0;
    if (radiusKm <= 50) return 10.0;
    if (radiusKm <= 100) return 9.0;
    if (radiusKm <= 200) return 8.0;
    return 6.0;
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
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<MapType>(
              icon: const Icon(Icons.layers),
              onSelected: (MapType type) {
                print('🗺️ Switching map type from $_mapType to $type');
                setState(() {
                  _mapType = type;
                });
                print('🗺️ Map type changed to: $_mapType');
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: MapType.normal,
                  child: Text('Normal'),
                ),
                const PopupMenuItem(
                  value: MapType.satellite,
                  child: Text('Satellite'),
                ),
                const PopupMenuItem(
                  value: MapType.hybrid,
                  child: Text('Hybrid'),
                ),
                const PopupMenuItem(
                  value: MapType.terrain,
                  child: Text('Terrain'),
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
                  color: Colors.black.withOpacity(0.2),
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
          // My Location Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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