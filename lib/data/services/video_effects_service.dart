import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service_impl.dart';
import '../../core/constants/api_constants.dart';

/// Service for managing video effects, filters, and virtual backgrounds
class VideoEffectsService {
  static VideoEffectsService? _instance;
  static VideoEffectsService get instance => _instance ??= VideoEffectsService._();
  
  VideoEffectsService._();

  final ApiServiceImpl _apiService = ApiServiceImpl();
  
  // Stream controllers for effects events
  final StreamController<Map<String, dynamic>> _effectsController = 
      StreamController.broadcast();
  final StreamController<List<VirtualBackground>> _backgroundsController = 
      StreamController.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get onEffectChanged => _effectsController.stream;
  Stream<List<VirtualBackground>> get onBackgroundsUpdated => _backgroundsController.stream;

  /// Get available virtual backgrounds from server
  Future<List<VirtualBackground>> getVirtualBackgrounds() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.webrtc}/virtual-backgrounds',
      );

      if (response.data['success'] == true) {
        final List<dynamic> backgroundsData = response.data['data'] ?? [];
        final backgrounds = backgroundsData
            .map((bg) => VirtualBackground.fromJson(bg))
            .toList();
        
        _backgroundsController.add(backgrounds);
        return backgrounds;
      }
      
      throw Exception('Failed to load virtual backgrounds');
    } catch (e) {
      debugPrint('Error getting virtual backgrounds: $e');
      rethrow;
    }
  }

  /// Apply virtual background to active call
  Future<bool> applyVirtualBackground({
    required String callId,
    required String backgroundId,
    String? backgroundUrl,
    double blurIntensity = 0.8,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.webrtc}/calls/$callId/virtual-background',
        data: {
          'type': backgroundUrl != null ? 'image' : 'blur',
          'backgroundUrl': backgroundUrl,
          'blurIntensity': blurIntensity,
          'backgroundId': backgroundId,
        },
      );

      if (response.data['success'] == true) {
        _effectsController.add({
          'type': 'virtual_background_applied',
          'callId': callId,
          'backgroundId': backgroundId,
          'backgroundUrl': backgroundUrl,
        });
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error applying virtual background: $e');
      return false;
    }
  }

  /// Remove virtual background from active call
  Future<bool> removeVirtualBackground(String callId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.webrtc}/calls/$callId/virtual-background',
      );

      if (response.data['success'] == true) {
        _effectsController.add({
          'type': 'virtual_background_removed',
          'callId': callId,
        });
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error removing virtual background: $e');
      return false;
    }
  }

  /// Apply camera filter to active call
  Future<bool> applyCameraFilter({
    required String callId,
    required String filterType,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.webrtc}/calls/$callId/filters',
        data: {
          'filterType': filterType,
          'settings': settings ?? {},
        },
      );

      if (response.data['success'] == true) {
        _effectsController.add({
          'type': 'filter_applied',
          'callId': callId,
          'filterType': filterType,
          'settings': settings,
        });
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error applying camera filter: $e');
      return false;
    }
  }

  /// Remove camera filter from active call
  Future<bool> removeCameraFilter({
    required String callId,
    required String filterType,
  }) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.webrtc}/calls/$callId/filters/$filterType',
      );

      if (response.data['success'] == true) {
        _effectsController.add({
          'type': 'filter_removed',
          'callId': callId,
          'filterType': filterType,
        });
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error removing camera filter: $e');
      return false;
    }
  }

  /// Get available camera filters
  List<CameraFilter> getAvailableFilters() {
    return [
      CameraFilter(
        id: 'beauty',
        name: 'Beauty',
        description: 'Smooth skin and enhance features',
        icon: '✨',
        isPremium: false,
        settings: {
          'skinSmooth': 0.6,
          'eyeEnhance': 0.3,
          'faceShape': 0.2,
        },
      ),
      CameraFilter(
        id: 'vintage',
        name: 'Vintage',
        description: 'Classic film look',
        icon: '📸',
        isPremium: true,
        settings: {
          'sepia': 0.7,
          'grain': 0.3,
          'vignette': 0.4,
        },
      ),
      CameraFilter(
        id: 'vibrant',
        name: 'Vibrant',
        description: 'Enhanced colors and saturation',
        icon: '🌈',
        isPremium: false,
        settings: {
          'saturation': 0.8,
          'contrast': 0.3,
          'brightness': 0.1,
        },
      ),
      CameraFilter(
        id: 'cool',
        name: 'Cool Tone',
        description: 'Blue and cool color tones',
        icon: '❄️',
        isPremium: true,
        settings: {
          'temperature': -0.3,
          'tint': 0.2,
          'contrast': 0.2,
        },
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    _effectsController.close();
    _backgroundsController.close();
  }
}

/// Virtual Background model
class VirtualBackground {
  final String id;
  final String name;
  final String type; // 'blur', 'image', 'video'
  final String? url;
  final String? thumbnail;
  final bool isPremium;

  VirtualBackground({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.thumbnail,
    this.isPremium = false,
  });

  factory VirtualBackground.fromJson(Map<String, dynamic> json) {
    return VirtualBackground(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'blur',
      url: json['url'],
      thumbnail: json['thumbnail'],
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'thumbnail': thumbnail,
      'isPremium': isPremium,
    };
  }
}

/// Camera Filter model
class CameraFilter {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isPremium;
  final Map<String, dynamic> settings;

  CameraFilter({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isPremium = false,
    this.settings = const {},
  });

  factory CameraFilter.fromJson(Map<String, dynamic> json) {
    return CameraFilter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🎨',
      isPremium: json['isPremium'] ?? false,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isPremium': isPremium,
      'settings': settings,
    };
  }
}