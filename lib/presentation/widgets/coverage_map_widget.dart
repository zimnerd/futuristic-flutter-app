import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as cluster;

import '../../core/models/location_models.dart';
import '../../data/models/heat_map_models.dart';
import '../../data/services/heat_map_service.dart';
import '../../core/services/location_service.dart';

/// Coverage map widget showing user distribution and coverage areas
class CoverageMapWidget extends StatefulWidget {
  final int maxDistance;
  final int minAge;
  final int maxAge;
  final CoverageMapFilter filter;
  final Function(LocationCoordinates)? onLocationSelected;

  const CoverageMapWidget({
    super.key,
    required this.maxDistance,
    required this.minAge,
    required this.maxAge,
    this.filter = CoverageMapFilter.all,
    this.onLocationSelected,
  });

  @override
  State<CoverageMapWidget> createState() => _CoverageMapWidgetState();
}

class _CoverageMapWidgetState extends State<CoverageMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polygon> _polygons = {};
  
  LocationCoordinates? _currentLocation;
  List<HeatMapDataPoint> _heatMapData = [];
  LocationCoverageData? _coverageData;
  bool _isLoading = true;
  String? _error;

  late final HeatMapService _heatMapService;
  late final LocationService _locationService;

  // Map styling and type
  MapType _currentMapType = MapType.normal;
  
  // Clustering
  late cluster.ClusterManager<HeatMapClusterItem> _clusterManager;

  @override
  void initState() {
    super.initState();
    _heatMapService = context.read<HeatMapService>();
    _locationService = context.read<LocationService>();
    _initializeClusterManager();
    _initializeMap();
  }

  void _initializeClusterManager() {
    _clusterManager = cluster.ClusterManager<HeatMapClusterItem>(
      [],
      _updateMarkers,
    );
  }

  Future<void> _initializeMap() async {
    try {
      await _getCurrentLocation();
      await _loadMapData();
    } catch (e) {
      dev.log('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load map data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocationCoordinates();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
    } catch (e) {
      dev.log('Error getting current location: $e');
    }
  }

  Future<void> _loadMapData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load heatmap data
      final heatMapData = await _heatMapService.getHeatMapData(
        bounds: _calculateMapBounds(),
        filters: HeatMapFilters(
          maxDistance: widget.maxDistance,
          minAge: widget.minAge,
          maxAge: widget.maxAge,
          matchStatus: _getMatchStatusFromFilter(),
        ),
      );

      // Load coverage data
      final coverageData = await _heatMapService.getLocationCoverageData(
        center: _currentLocation!,
        radiusKm: widget.maxDistance.toDouble(),
        filters: LocationCoverageFilters(
          minAge: widget.minAge,
          maxAge: widget.maxAge,
          matchStatus: _getMatchStatusFromFilter(),
        ),
      );

      if (mounted) {
        setState(() {
          _heatMapData = heatMapData;
          _coverageData = coverageData;
          _isLoading = false;
        });
        
        _updateMapVisualization();
      }
    } catch (e) {
      dev.log('Error loading map data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load coverage data';
          _isLoading = false;
        });
      }
    }
  }

  void _updateMapVisualization() {
    _updateHeatMapVisualization();
    _updateCoverageVisualization();
    _updateUserLocationMarker();
    _updateClusterData();
  }

  void _updateClusterData() {
    final clusterItems = _heatMapData
        .map((point) => HeatMapClusterItem(point))
        .toList();

    _clusterManager.setItems(clusterItems);

    // Update cluster markers for current zoom level
    if (_mapController != null) {
      _clusterManager.updateMap();
    }
  }

  void _updateHeatMapVisualization() {
    final circles = <Circle>{};
    
    for (int i = 0; i < _heatMapData.length; i++) {
      final point = _heatMapData[i];
      
      circles.add(
        Circle(
          circleId: CircleId('heatmap_$i'),
          center: LatLng(point.coordinates.latitude, point.coordinates.longitude),
          radius: _calculateHeatMapRadius(point.density),
          fillColor: _getHeatMapColor(point.density).withValues(alpha: 0.3),
          strokeColor: _getHeatMapColor(point.density),
          strokeWidth: 1,
        ),
      );
    }

    setState(() {
      _circles.clear();
      _circles.addAll(circles);
    });
  }

  void _updateCoverageVisualization() {
    if (_coverageData == null || _currentLocation == null) return;

    final polygons = <Polygon>{};
    
    for (int i = 0; i < _coverageData!.coverageAreas.length; i++) {
      final area = _coverageData!.coverageAreas[i];
      
      final polygonPoints = area.boundaryPoints.map((coord) =>
          LatLng(coord.latitude, coord.longitude)).toList();

      polygons.add(
        Polygon(
          polygonId: PolygonId('coverage_$i'),
          points: polygonPoints,
          fillColor: _getCoverageColor(area.density).withValues(alpha: 0.2),
          strokeColor: _getCoverageColor(area.density),
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _polygons.clear();
      _polygons.addAll(polygons);
    });
  }

  void _updateUserLocationMarker() {
    if (_currentLocation == null) return;

    final markers = <Marker>{};
    
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
      ),
    );

    // Add range circle around user
    _circles.add(
      Circle(
        circleId: const CircleId('user_range'),
        center: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        radius: widget.maxDistance * 1000.0, // Convert km to meters
        fillColor: Colors.blue.withValues(alpha: 0.1),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }





  LocationBounds _calculateMapBounds() {
    if (_currentLocation == null) {
      // Default bounds (global)
      return const LocationBounds(
        northLatitude: 85.0,
        southLatitude: -85.0,
        eastLongitude: 180.0,
        westLongitude: -180.0,
      );
    }

    // Calculate bounds based on user location and distance preference
    const double kmToDegree = 0.009; // Approximate conversion
    final double offset = widget.maxDistance * kmToDegree;

    return LocationBounds(
      northLatitude: _currentLocation!.latitude + offset,
      southLatitude: _currentLocation!.latitude - offset,
      eastLongitude: _currentLocation!.longitude + offset,
      westLongitude: _currentLocation!.longitude - offset,
    );
  }

  double _calculateHeatMapRadius(int density) {
    // Scale radius based on density (100m - 2km)
    const double minRadius = 100.0;
    const double maxRadius = 2000.0;
    const int maxDensity = 100;
    
    final double normalizedDensity = (density / maxDensity).clamp(0.0, 1.0);
    return minRadius + (normalizedDensity * (maxRadius - minRadius));
  }

  Color _getHeatMapColor(int density) {
    // Color gradient based on density
    if (density > 50) return Colors.red;
    if (density > 20) return Colors.orange;
    if (density > 10) return Colors.yellow;
    if (density > 5) return Colors.lightGreen;
    return Colors.green;
  }

  Color _getCoverageColor(int density) {
    // Purple gradient for coverage areas
    if (density > 50) return const Color(0xFF6E3BFF);
    if (density > 20) return const Color(0xFF8A5FFF);
    if (density > 10) return const Color(0xFFA683FF);
    return const Color(0xFFC2A7FF);
  }

  MatchStatus? _getMatchStatusFromFilter() {
    switch (widget.filter) {
      case CoverageMapFilter.matched:
        return MatchStatus.matched;
      case CoverageMapFilter.likedMe:
        return MatchStatus.likedYou;
      case CoverageMapFilter.unmatched:
        return MatchStatus.none;
      case CoverageMapFilter.all:
        return null;
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    dev.log(
      '🗺️ CoverageMap: Map controller created - starting initialization',
    );
    _mapController = controller;
    _controller.complete(controller);

    try {
      // Add debug logging for map initialization
      dev.log('🗺️ CoverageMap: Map ID: ${controller.mapId}');

      // Give more time for tiles to load and detect any errors
      dev.log('🗺️ CoverageMap: Waiting for map tiles to initialize...');
      await Future.delayed(const Duration(milliseconds: 2000));

      _clusterManager.setMapId(controller.mapId);
      dev.log(
        '🗺️ CoverageMap: Cluster manager initialized with map ID: ${controller.mapId}',
      );

      // Move camera to user location if available
      if (_currentLocation != null) {
        final zoom = _calculateOptimalZoom();
        dev.log(
          '🗺️ CoverageMap: Setting camera position - lat: ${_currentLocation!.latitude}, lng: ${_currentLocation!.longitude}, zoom: $zoom',
        );

        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _currentLocation!.latitude,
                _currentLocation!.longitude,
              ),
              zoom: zoom,
            ),
          ),
        );
        dev.log('🗺️ CoverageMap: Camera animation completed');
      } else {
        dev.log(
          '🗺️ CoverageMap: No current location available for camera positioning',
        );
      }
    } catch (e, stackTrace) {
      dev.log('🚨 CoverageMap: Error during map initialization: $e');
      dev.log('🚨 CoverageMap: Stack trace: $stackTrace');
    }
  }

  double _calculateOptimalZoom() {
    // Calculate zoom level based on distance preference - higher zoom to show roads/buildings
    const Map<int, double> distanceToZoom = {
      5: 15.0, // City streets clearly visible
      10: 14.0, // Neighborhood level
      25: 13.0, // Multiple neighborhoods
      50: 12.0, // City-wide view with major roads
      100: 11.0, // Regional view
    };

    final zoom =
        distanceToZoom.entries
        .where((entry) => widget.maxDistance <= entry.key)
        .map((entry) => entry.value)
            .firstOrNull ??
        10.0; // Use 10.0 as safer default

    dev.log(
      'Coverage Map: Calculated zoom level: $zoom for distance: ${widget.maxDistance}km',
    );
    return zoom;
  }

  void _switchMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.terrain;
          break;
        case MapType.terrain:
          _currentMapType = MapType.hybrid;
          break;
        case MapType.hybrid:
          _currentMapType = MapType.normal;
          break;
        case MapType.none:
          _currentMapType = MapType.normal;
          break;
      }
    });
  }

  Future<void> _refreshData() async {
    await _loadMapData();
  }

  void _onCameraMove(CameraPosition position) {
    // Update clustering based on zoom level
    if (_mapController != null) {
      _clusterManager.onCameraMove(position);
    }
  }

  void _onCameraIdle() {
    // Update clusters when camera stops moving
    if (_mapController != null) {
      _clusterManager.updateMap();
    }
  }

  void _onMapTap(LatLng position) {
    // Handle map taps if needed
    dev.log('Map tapped at: ${position.latitude}, ${position.longitude}');

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(
        LocationCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            key: const ValueKey('coverage_google_map'),
            onMapCreated: (GoogleMapController controller) {
              dev.log(
                '🗺️ CoverageMap: GoogleMap onMapCreated callback triggered',
              );
              _onMapCreated(controller);
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null
                  ? LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    )
                  : const LatLng(-33.9249, 18.4241), // Cape Town as fallback
              zoom: 14.0,
            ),
            mapType: _currentMapType,
            markers: _markers,
            circles: _circles,
            polygons: _polygons,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(3.0, 20.0),
            cameraTargetBounds: CameraTargetBounds.unbounded,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            trafficEnabled: false,
            liteModeEnabled: false, // Ensure full map rendering
          ), // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6E3BFF)),
                    SizedBox(height: 16),
                    Text(
                      'Loading coverage data...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (_error != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E3BFF),
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // Map controls
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                // Refresh button
                FloatingActionButton(
                  mini: true,
                  onPressed: _refreshData,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Color(0xFF6E3BFF)),
                ),
                const SizedBox(height: 8),
                
                // Center on user button
                FloatingActionButton(
                  mini: true,
                  onPressed: _centerOnUser,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Color(0xFF6E3BFF)),
                ),
                const SizedBox(height: 8),

                // Map type switcher
                FloatingActionButton(
                  mini: true,
                  onPressed: _switchMapType,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.layers, color: Color(0xFF6E3BFF)),
                ),
              ],
            ),
          ),

          // Coverage statistics
          if (_coverageData != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildCoverageStats(),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverageStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Coverage Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6E3BFF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total Users', _coverageData!.totalUsers.toString()),
              _buildStatItem('Coverage Areas', _coverageData!.coverageAreas.length.toString()),
              _buildStatItem('Avg Density', _coverageData!.averageDensity.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6E3BFF),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _centerOnUser() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
            zoom: _calculateOptimalZoom(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// Filter options for coverage map
enum CoverageMapFilter {
  all,
  matched,
  likedMe,
  unmatched,
}

/// Extension for filter display names
extension CoverageMapFilterExtension on CoverageMapFilter {
  String get displayName {
    switch (this) {
      case CoverageMapFilter.all:
        return 'All Users';
      case CoverageMapFilter.matched:
        return 'Matches';
      case CoverageMapFilter.likedMe:
        return 'Liked Me';
      case CoverageMapFilter.unmatched:
        return 'Unmatched';
    }
  }

  IconData get icon {
    switch (this) {
      case CoverageMapFilter.all:
        return Icons.people;
      case CoverageMapFilter.matched:
        return Icons.favorite;
      case CoverageMapFilter.likedMe:
        return Icons.thumb_up;
      case CoverageMapFilter.unmatched:
        return Icons.remove_circle_outline;
    }
  }
}

/// Cluster item for heat map data points
class HeatMapClusterItem implements cluster.ClusterItem {
  final HeatMapDataPoint dataPoint;
  final LatLng _location;
  
  HeatMapClusterItem(this.dataPoint) 
      : _location = LatLng(dataPoint.coordinates.latitude, dataPoint.coordinates.longitude);

  @override
  LatLng get location => _location;

  @override
  String get geohash => '${location.latitude}_${location.longitude}';
}