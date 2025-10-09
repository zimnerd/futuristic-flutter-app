import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/heat_map_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/heat_map_models.dart';
import '../../data/models/optimized_heatmap_models.dart';
import '../../core/models/location_models.dart';
import '../../data/models/location_models.dart' as data_models;

// Function to show the heat map as a full-screen modal
void showHeatMapModal(BuildContext context) {
  // Get the services from the parent context
  final heatMapService = context.read<HeatMapService>();
  final locationService = context.read<LocationService>();
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (modalContext) => BlocProvider(
      create: (_) => HeatMapBloc(heatMapService, locationService),
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: const HeatMapScreen(),
      ),
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

class FetchBackendClusters extends HeatMapEvent {
  final double zoom;
  final LatLngBounds? viewport;
  final double radiusKm;

  FetchBackendClusters({
    required this.zoom,
    this.viewport,
    required this.radiusKm,
  });
}

// BLoC States
abstract class HeatMapState {}

class HeatMapInitial extends HeatMapState {}

class HeatMapLoading extends HeatMapState {}

class HeatMapLoaded extends HeatMapState {
  final HeatMapData heatmapData;
  final LocationCoverageData coverageData;
  final LocationCoordinates? userLocation;
  final int currentRadius;
  final List<OptimizedClusterData>? backendClusters;

  HeatMapLoaded({
    required this.heatmapData,
    required this.coverageData,
    this.userLocation,
    required this.currentRadius,
    this.backendClusters,
  });

  HeatMapLoaded copyWith({
    HeatMapData? heatmapData,
    LocationCoverageData? coverageData,
    LocationCoordinates? userLocation,
    int? currentRadius,
    List<OptimizedClusterData>? backendClusters,
  }) {
    return HeatMapLoaded(
      heatmapData: heatmapData ?? this.heatmapData,
      coverageData: coverageData ?? this.coverageData,
      userLocation: userLocation ?? this.userLocation,
      currentRadius: currentRadius ?? this.currentRadius,
      backendClusters: backendClusters ?? this.backendClusters,
    );
  }
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
    on<FetchBackendClusters>(_onFetchBackendClusters);
  }

  Future<void> _onLoadHeatMapData(
    LoadHeatMapData event,
    Emitter<HeatMapState> emit,
  ) async {
    emit(HeatMapLoading());
    
    try {
      final position = await _locationService.getCurrentLocation();
      
      final userCoords = position != null 
        ? LocationCoordinates(latitude: position.latitude, longitude: position.longitude) 
        : null;
      
      if (userCoords == null) {
        emit(
          HeatMapError(
            'Unable to get current location. Please enable location services and grant permission.',
          ),
        );
        return;
      }
      
      // First, update user location in backend
      try {
        await _heatMapService.updateUserLocation(userCoords);
      } catch (e) {
        // Continue anyway - try to fetch data without updating location
      }
      
      // FIX: Fetch BOTH heatmap data AND backend clusters during initial load
      final [
        heatmapDataPoints,
        coverageData,
        optimizedClusters,
      ] = await Future.wait([
        _heatMapService.getHeatMapData(),
        _heatMapService.getLocationCoverageData(
          center: userCoords,
          radiusKm: event.radiusKm.toDouble(),
        ),
        // Fetch backend clusters with default zoom level
        _heatMapService.getOptimizedHeatMapData(
          zoom: 11.0, // Default zoom for initial load
          radiusKm: event.radiusKm.toDouble(),
          maxClusters: 50,
        ),
      ]);
      
      final points = heatmapDataPoints as List<HeatMapDataPoint>;
      final coverage = coverageData as LocationCoverageData;
      final clusters = optimizedClusters as OptimizedHeatmapResponse;
      
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
          backendClusters:
              clusters.clusters, // FIX: Include clusters in initial state
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

  /// Fetch clusters from backend - eliminates heavy frontend computation
  Future<void> _onFetchBackendClusters(
    FetchBackendClusters event,
    Emitter<HeatMapState> emit,
  ) async {
    // Handle both HeatMapInitial and HeatMapLoaded states
    // If state is Initial, trigger LoadHeatMapData to initialize the state first
    if (state is! HeatMapLoaded) {
      // Trigger initial data load which will include backend clusters
      add(LoadHeatMapData(event.radiusKm.toInt()));
      return;
    }

    final currentState = state as HeatMapLoaded;

    try {
      final response = await _heatMapService.getOptimizedHeatMapData(
        zoom: event.zoom,
        northLat: event.viewport?.northeast.latitude,
        southLat: event.viewport?.southwest.latitude,
        eastLng: event.viewport?.northeast.longitude,
        westLng: event.viewport?.southwest.longitude,
        radiusKm: event.radiusKm,
        maxClusters: 50,
      );

      emit(currentState.copyWith(backendClusters: response.clusters));
    } catch (e) {
      AppLogger.error('Failed to fetch backend clusters: $e');
      // Don't emit error - keep existing state and let UI fall back gracefully
    }
  }
}


// Heat Map Screen Widget
class HeatMapScreen extends StatefulWidget {
  const HeatMapScreen({super.key});

  @override
  State<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends State<HeatMapScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  int _currentRadius = 50;
  MapType _mapType = MapType.normal;
  double _currentZoom = 6.0;
  bool _showHeatmap = true; // Enabled by default for better UX
  bool _showClusters =
      true; // ENABLED BY DEFAULT - show user clusters immediately
  bool _isStatisticsPopupVisible = false;
  
  // Debouncing for camera movements to optimize performance
  Timer? _debounceTimer;
  Timer? _clusterCalculationTimer;
  
  final bool _isUpdatingClusters = false;
  bool _isCalculatingClusters = false;

  // Google Maps lifecycle management to fix black screen issue
  // See: https://github.com/flutter/flutter/issues/40284
  // Use a stable key to prevent unnecessary widget recreation
  final GlobalKey _googleMapKey = GlobalKey();

  // Memoized sets to prevent rebuilding on every frame
  Set<Circle>? _memoizedCircles;
  Set<Marker>? _memoizedMarkers;
  String? _lastCacheKey;
  
  // Performance tracking
  // Clustering performance tracking (removed unused counter)

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to handle app resume
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _clusterCalculationTimer?.cancel();
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Group zoom levels to minimize cluster recalculations
  /// 1-3 → 2, 4-6 → 5, 7-9 → 8, 10-12 → 11, 13-15 → 14, 16-18 → 17
  double _getGroupedZoomLevel(double zoom) {
    if (zoom < 1) return 1;
    if (zoom > 18) return 18;

    // Group into ranges of 3 zoom levels
    final group = ((zoom - 1) / 3).floor();
    final groupedZoom = (group * 3) + 2; // Middle value of each group

    return groupedZoom.toDouble();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Instead of recreating the entire widget, just refresh the map controller
      // This prevents the black screen issue caused by platform view recreation
      if (_mapController != null && mounted) {
        // Map is already initialized, no need to recreate it
      }
    }
  }

  /// Show statistics popup for users within radius
  void _showStatisticsPopup() async {
    if (_isStatisticsPopupVisible) return;

    setState(() {
      _isStatisticsPopupVisible = true;
    });

    final state = context.read<HeatMapBloc>().state;
    if (state is HeatMapLoaded) {
      _showUserStatisticsDialog(state.heatmapData, state.coverageData);
    } else {
      // Load data first if not available
      context.read<HeatMapBloc>().add(LoadHeatMapData(_currentRadius));
    }
  }

  /// Show dialog with user statistics within radius
  void _showUserStatisticsDialog(
    HeatMapData heatmapData,
    LocationCoverageData coverageData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '📊 User Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6E3BFF),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Radius', '$_currentRadius km'),
                _buildStatRow(
                  'Total Users',
                  '${heatmapData.dataPoints.length}',
                ),
                _buildStatRow(
                  'Coverage Areas',
                  '${coverageData.coverageAreas.length}',
                ),
                _buildStatRow(
                  'Active Regions',
                  '${heatmapData.dataPoints.where((p) => p.density > 5).length}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Density Distribution:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildStatsPopupDensityStats(heatmapData.dataPoints),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isStatisticsPopupVisible = false;
                });
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF6E3BFF)),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isStatisticsPopupVisible = false;
      });
    });
  }

  /// Build density statistics widgets
  List<Widget> _buildStatsPopupDensityStats(List<HeatMapDataPoint> points) {
    final lowDensity = points.where((p) => p.density <= 2).length;
    final mediumDensity = points
        .where((p) => p.density > 2 && p.density <= 5)
        .length;
    final highDensity = points.where((p) => p.density > 5).length;

    return [
      _buildStatRow('Low Density (≤2)', '$lowDensity areas'),
      _buildStatRow('Medium Density (3-5)', '$mediumDensity areas'),
      _buildStatRow('High Density (>5)', '$highDensity areas'),
    ];
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
    return Stack(
      children: [
        Positioned.fill(child: _buildGoogleMap(state)),
        if (_showClusters) ..._buildClusterNumberOverlays(state),
        _buildMapControls(context),
        _buildMapOverlay(context, state),
        _buildStatsPanel(context, state),
        if (_isCalculatingClusters)
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
                      'Calculating clusters...',
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
    // Determine best position for map camera
    LatLng initialPosition;
    bool hasGeographicMismatch = false;

    if (state.heatmapData.dataPoints.isNotEmpty) {
      final firstPoint = state.heatmapData.dataPoints.first;

      // Check if user location and data are on different continents
      final userLat = state.userLocation?.latitude ?? 0;
      final dataLat = firstPoint.coordinates.latitude;

      hasGeographicMismatch =
          (userLat > 0 && dataLat < 0) || (userLat < 0 && dataLat > 0);

      if (hasGeographicMismatch) {

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

    // Calculate optimal zoom level based on data distribution
    final initialZoomLevel = hasGeographicMismatch ? 8.0 : 12.0;
    
    final markers = _buildMarkers(state);
    final circles = _buildCircles(state);

    final googleMapWidget = GoogleMap(
      key: _googleMapKey, // Use dynamic key instead of const ValueKey
      onMapCreated: (GoogleMapController controller) async {
        _mapController = controller;
        
        // Check if map tiles are loading by testing a basic operation
        try {
          final bounds = await controller.getVisibleRegion();

          // FIX: Fetch backend clusters immediately on map load (onCameraIdle may not fire initially)
          if (_showClusters && mounted) {
            final groupedZoom = _getGroupedZoomLevel(_currentZoom);
            final radiusKm = _currentRadius.toDouble();

            context.read<HeatMapBloc>().add(
              FetchBackendClusters(
                zoom: groupedZoom,
                viewport: bounds,
                radiusKm: radiusKm,
              ),
            );
          }
        } catch (e) {
          AppLogger.error('Cannot get visible region: $e');
        }
      },
      onCameraMove: (CameraPosition position) {
        if (mounted) {
          // Cancel any pending cluster calculation when camera starts moving
          _clusterCalculationTimer?.cancel();

          // Update zoom without triggering loading state
          // Keep existing clusters visible for smooth UX (Google Maps pattern)
          _currentZoom = position.zoom;
        }
      },
      onCameraIdle: () async {
        // Cancel any pending debounced updates
        _debounceTimer?.cancel();

        // Debounce backend cluster fetch: wait 300ms after camera stops
        _clusterCalculationTimer?.cancel();
        
        _clusterCalculationTimer = Timer(
          const Duration(milliseconds: 300),
          () async {
            
            if (mounted && !_isUpdatingClusters && _showClusters) {
              final groupedZoom = _getGroupedZoomLevel(_currentZoom);
              AppLogger.debug(
                '� Camera stopped at grouped zoom $groupedZoom, fetching backend clusters...',
              );

              try {
                // Get current viewport bounds
                final controller = _mapController;
                if (controller != null) {
                  final bounds = await controller.getVisibleRegion();

                  // Use user's distance preference from UI state
                  final radiusKm = _currentRadius.toDouble();

                // Invalidate marker cache - new clusters will be fetched
                setState(() {
                  _memoizedMarkers = null;
                });

                  // Dispatch event to fetch backend clusters
                  if (!mounted) return;
                  context.read<HeatMapBloc>().add(
                    FetchBackendClusters(
                      zoom: groupedZoom,
                      viewport: bounds,
                      radiusKm: radiusKm,
                    ),
                  );

                  setState(() {
                    _isCalculatingClusters = false; // Hide loading indicator
                  });
                }
              } catch (e) {
                AppLogger.error('Error fetching backend clusters: $e');
                setState(() {
                  _isCalculatingClusters = false;
                });
              }
            } else {
              setState(() {
                _isCalculatingClusters = false;
              });
            }
          },
        );
      },
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom:
            initialZoomLevel, // Use calculated zoom level - no animation needed
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
      // FIX: Disable myLocation when user is far from data (prevents map rendering issues)
      myLocationEnabled: !hasGeographicMismatch,
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

    return googleMapWidget;
  }

  /// Build cluster circles for privacy (no individual markers)
  /// Cluster circles disabled in favor of backend-calculated clusters
  Set<Circle> _buildClusterCircles(HeatMapLoaded state) {
    if (!_showClusters) {
      return {};
    }
    return {};
  }

  /// Build cluster markers with user count labels, status colors, and dynamic sizing
  Future<Set<Marker>> _buildMarkersFromBackendClusters(
    List<OptimizedClusterData> clusters,
  ) async {
    // Apply zoom-based aggregation
    final aggregatedClusters = _aggregateClustersByStatus(
      clusters,
      _currentZoom,
    );
    final clusterMarkers = <Marker>{};

    for (var i = 0; i < aggregatedClusters.length; i++) {
      final cluster = aggregatedClusters[i];

      // Determine predominant status and corresponding color
      final predominantStatus = _getPredominantStatus(cluster.statusBreakdown);
      final statusColor = _getStatusColor(predominantStatus);

      // Determine size tier based on user count
      final sizeTier = _getClusterSizeTier(cluster.userCount);
      final markerSize = _getMarkerSize(sizeTier);
      
      // Generate custom marker icon with user count label
      final markerIcon = await _generateClusterMarkerIcon(
        userCount: cluster.userCount,
        color: statusColor,
        size: markerSize,
      );

      final marker = Marker(
        markerId: MarkerId(cluster.id),
        position: LatLng(cluster.latitude, cluster.longitude),
        icon: markerIcon,
        anchor: const Offset(0.5, 0.5), // Center the marker
        onTap: () => _showBackendClusterDetails(cluster),
      );

      clusterMarkers.add(marker);
    }
    return clusterMarkers;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Google Maps Cluster Marker Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Aggregate clusters by status at low zoom levels (1-10)
  /// Returns 1-4 mega-clusters (one per status with users)
  List<OptimizedClusterData> _aggregateClustersByStatus(
    List<OptimizedClusterData> clusters,
    double zoom,
  ) {
    // Only aggregate at very low zoom levels (1-10)
    if (zoom >= 9) {
      return clusters; // Return original clusters at high zoom
    }

    // Accumulate totals by status
    final Map<String, int> statusTotals = {
      'matched': 0,
      'liked_me': 0,
      'unmatched': 0,
      'passed': 0,
    };

    // Calculate geographic center (simple average)
    double sumLat = 0.0;
    double sumLng = 0.0;
    int totalUsers = 0;

    for (final cluster in clusters) {
      sumLat += cluster.latitude * cluster.userCount;
      sumLng += cluster.longitude * cluster.userCount;
      totalUsers += cluster.userCount;

      final breakdown = cluster.statusBreakdown ?? {};
      statusTotals['matched'] =
          statusTotals['matched']! + (breakdown['matched'] ?? 0);
      statusTotals['liked_me'] =
          statusTotals['liked_me']! + (breakdown['liked_me'] ?? 0);
      statusTotals['unmatched'] =
          statusTotals['unmatched']! + (breakdown['unmatched'] ?? 0);
      statusTotals['passed'] =
          statusTotals['passed']! + (breakdown['passed'] ?? 0);
    }

    final centerLat = totalUsers > 0 ? sumLat / totalUsers : 0.0;
    final centerLng = totalUsers > 0 ? sumLng / totalUsers : 0.0;

    // Create mega-clusters (one per status that has users)
    final List<OptimizedClusterData> megaClusters = [];

    statusTotals.forEach((status, count) {
      if (count > 0) {
        // Create single-status breakdown for this mega-cluster
        final Map<String, int> singleStatusBreakdown = {status: count};

        final megaCluster = OptimizedClusterData(
          id: 'mega_$status',
          latitude: centerLat,
          longitude: centerLng,
          userCount: count,
          radius: 150.0,
          densityScore: 0,
          avgAge: 0.0,
          genderDistribution: null,
          ageDistribution: null,
          statusBreakdown: singleStatusBreakdown,
        );

        megaClusters.add(megaCluster);
      }
    });

    return megaClusters;
  }

  /// Get predominant status from statusBreakdown
  String _getPredominantStatus(Map<String, int>? statusBreakdown) {
    if (statusBreakdown == null || statusBreakdown.isEmpty) {
      return 'unmatched'; // Default to available/unmatched
    }

    String predominant = 'unmatched';
    int maxCount = 0;

    // Priority order: matched > liked_me > unmatched > passed
    statusBreakdown.forEach((status, count) {
      if (count > maxCount) {
        maxCount = count;
        predominant = status;
      } else if (count == maxCount && status == 'matched') {
        // Prefer matched when tied
        predominant = status;
      }
    });

    return predominant;
  }

  /// Get color for predominant status (per legend)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'matched':
        return Colors.green; // Green - Matched
      case 'liked_me':
        return Colors.orange; // Orange - Liked Me
      case 'passed':
        return Colors.red; // Red - Passed
      case 'unmatched':
      default:
        return const Color(0xFF00C2FF); // Blue/Cyan - Available
    }
  }

  /// Get cluster size tier based on user count
  String _getClusterSizeTier(int userCount) {
    if (userCount > 50) return 'large';
    if (userCount > 10) return 'medium';
    return 'small';
  }

  /// Get marker size in pixels based on tier
  int _getMarkerSize(String sizeTier) {
    switch (sizeTier) {
      case 'large':
        return 80;
      case 'medium':
        return 60;
      case 'small':
      default:
        return 50;
    }
  }

  /// Generate custom cluster marker icon with user count label
  Future<BitmapDescriptor> _generateClusterMarkerIcon({
    required int userCount,
    required Color color,
    required int size,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw outer circle (white stroke)
    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, strokePaint);

    // Draw inner circle (colored)
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, fillPaint);

    // Draw user count text
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: userCount.toString(),
      style: TextStyle(
        color: Colors.white,
        fontSize: size > 60 ? 20 : (size > 50 ? 16 : 14),
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? byteData = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Show details for backend cluster with status breakdown
  void _showBackendClusterDetails(OptimizedClusterData cluster) {
    // Extract status breakdown
    final statusBreakdown = cluster.statusBreakdown ?? {};
    final matched = statusBreakdown['matched'] ?? 0;
    final likedMe = statusBreakdown['liked_me'] ?? 0;
    final available = statusBreakdown['unmatched'] ?? 0;
    final passed = statusBreakdown['passed'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.people, color: Color(0xFF6E3BFF), size: 24),
            SizedBox(width: 8),
            Text(
              'Cluster Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6E3BFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Color(0xFF6E3BFF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total Users: ${cluster.userCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status Breakdown:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusRow('✅ Matched', matched, Colors.green),
            _buildStatusRow('❤️ Liked Me', likedMe, Colors.orange),
            _buildStatusRow('👋 Available', available, const Color(0xFF00C2FF)),
            _buildStatusRow('👎 Passed', passed, Colors.red),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF00C2FF),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cluster.latitude.toStringAsFixed(4)}, ${cluster.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF6E3BFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build a status row for cluster details dialog
  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: count > 0 ? Colors.white : Colors.white38,
                fontWeight: count > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: count > 0 ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Build markers synchronously - uses memoized cluster markers
  Set<Marker> _buildMarkers(HeatMapLoaded state) {
    // Return empty set if clustering is disabled
    if (!_showClusters) {
      return <Marker>{};
    }

    // Return memoized markers if available
    if (_memoizedMarkers != null) {
      return _memoizedMarkers!;
    }

    // If no memoized markers but we have clusters, trigger async generation
    if (state.backendClusters != null && state.backendClusters!.isNotEmpty) {
      // Trigger async marker generation (don't await)
      _generateClusterMarkers(state.backendClusters!);
    }

    return <Marker>{};
  }

  /// Generate cluster markers asynchronously and update state
  Future<void> _generateClusterMarkers(
    List<OptimizedClusterData> clusters,
  ) async {
    final clusterMarkers = await _buildMarkersFromBackendClusters(clusters);

    setState(() {
      _memoizedMarkers = clusterMarkers;
    });
  }

  Set<Circle> _buildCircles(HeatMapLoaded state) {
    // Create cache key from state properties that affect circles
    final cacheKey =
        '${state.userLocation?.latitude}_'
        '${state.userLocation?.longitude}_'
        '${state.currentRadius}_'
        '${_showClusters}_'
        '${_showHeatmap}_'
        '${state.backendClusters?.length ?? 0}_'
        '${state.heatmapData.dataPoints.length}';

    // Return memoized circles if state hasn't changed
    if (_memoizedCircles != null && _lastCacheKey == cacheKey) {
      return _memoizedCircles!;
    }

    // Safety: If building new circles, ensure we don't return empty set during transition
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
      AppLogger.debug(
        '🎨 User coverage circle added (radius: ${state.currentRadius}km)',
      );
    }

    // Add privacy cluster circles when clustering is enabled
    if (_showClusters) {
      AppLogger.debug('🎨 Clustering enabled, building cluster circles...');
      final clusterCircles = _buildClusterCircles(state);
      circles.addAll(clusterCircles);
      AppLogger.debug('🎨 Added ${clusterCircles.length} cluster circles');
    } else {
      AppLogger.debug('🎨 Clustering disabled, skipping cluster circles');
    }
    
    // Add heatmap overlay circles when heatmap is enabled
    if (_showHeatmap) {
      final heatmapCircles = _buildHeatmapCircles(state);
      circles.addAll(heatmapCircles);
    }

    // Cache the result only if we have circles (prevent caching empty/transition states)
    if (circles.isNotEmpty) {
      _memoizedCircles = circles;
      _lastCacheKey = cacheKey;
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

    AppLogger.debug(
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

  /// Cluster overlays disabled - info shown on tap via _showBackendClusterDetails()
  List<Widget> _buildClusterNumberOverlays(HeatMapLoaded state) {
    return [];
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

  Widget _buildMapOverlay(BuildContext context, HeatMapLoaded state) {
    return Positioned(
      top: 6,
      left: 8,
      right: 8,
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
    // Calculate stats from actual backend clusters (visible markers)
    final totalUsers =
        state.backendClusters?.fold<int>(
          0,
          (sum, cluster) => sum + cluster.userCount,
        ) ??
        0;
    final clusterCount = state.backendClusters?.length ?? 0;

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
                  _buildStatItemWithIcon(
                    'Active Users',
                    totalUsers,
                    Icons.people,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItemWithIcon(
                    'Clusters',
                    clusterCount,
                    Icons.scatter_plot,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItemWithIcon(
                    'Total Users',
                    totalUsers,
                    Icons.local_fire_department,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItemWithIcon(
                    'Coverage',
                    '${_currentRadius}km',
                    Icons.location_on,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemWithIcon(String label, dynamic value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
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
    // Check if this is a location permission error
    final isLocationError =
        state.message.contains('location') ||
        state.message.contains('permission') ||
        state.message.contains('Unable to get current location');

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
            Icon(
              isLocationError ? Icons.location_off : Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              isLocationError
                  ? 'Location Access Required'
                  : 'Oops! Something went wrong',
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
                isLocationError
                    ? 'The heat map needs location access to show people nearby and coverage areas. Please enable location permissions to continue.'
                    : state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (isLocationError) ...[
              ElevatedButton(
                onPressed: () async {
                  final permissionService = PermissionService();
                  final granted = await permissionService
                      .requestLocationWhenInUsePermission(context);
                  if (granted) {
                    // Retry loading data after permission granted
                    context.read<HeatMapBloc>().add(
                      LoadHeatMapData(_currentRadius),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E3BFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enable Location',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final permissionService = PermissionService();
                  await permissionService.showLocationFeaturesLimitedDialog(
                    context,
                  );
                },
                child: const Text(
                  'What features need location?',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  context.read<HeatMapBloc>().add(
                    LoadHeatMapData(_currentRadius),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E3BFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
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
          // Clustering Toggle
          Container(
            decoration: BoxDecoration(
              color: _showClusters ? const Color(0xFF00C2FF) : Colors.white,
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
                Icons.scatter_plot,
                color: _showClusters ? Colors.white : Colors.black87,
              ),
              onPressed: () async {
                setState(() {
                  _showClusters = !_showClusters;
                  // Clear memoized markers when turning off clusters
                  if (!_showClusters) {
                    _memoizedMarkers = null;
                  }
                });

                // Only fetch clusters when turning ON
                if (_showClusters && mounted) {
                  try {
                    final bounds = await _mapController?.getVisibleRegion();
                    final groupedZoom = _getGroupedZoomLevel(_currentZoom);
                    final radiusKm = _currentRadius.toDouble();

                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    context.read<HeatMapBloc>().add(
                      FetchBackendClusters(
                        zoom: groupedZoom,
                        viewport: bounds,
                        radiusKm: radiusKm,
                      ),
                    );
                  } catch (e) {
                    AppLogger.error('Failed to fetch clusters: $e');
                  }
                }
              },
              tooltip: _showClusters ? 'Hide Clusters' : 'Show Clusters',
            ),
          ),
          const SizedBox(height: 8),
          // Statistics Button
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
              icon: const Icon(Icons.analytics, color: Color(0xFF00D4AA)),
              onPressed: _showStatisticsPopup,
              tooltip: 'Show Statistics',
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