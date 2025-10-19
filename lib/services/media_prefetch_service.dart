import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart' show AppLogger;
import '../domain/entities/user_profile.dart';

/// Configuration for media prefetching behavior
class PrefetchConfig {
  /// Number of profiles ahead to prefetch (default: 3)
  final int prefetchCount;

  /// Whether to prefetch on cellular data (default: false)
  final bool enableOnCellular;

  /// Maximum cache size in MB (default: 100)
  final int maxCacheSizeMB;

  /// Cache TTL in hours (default: 24)
  final int cacheTTLHours;

  /// Whether prefetching is enabled (default: true)
  final bool enabled;

  const PrefetchConfig({
    this.prefetchCount = 3,
    this.enableOnCellular = false,
    this.maxCacheSizeMB = 100,
    this.cacheTTLHours = 24,
    this.enabled = true,
  });

  PrefetchConfig copyWith({
    int? prefetchCount,
    bool? enableOnCellular,
    int? maxCacheSizeMB,
    int? cacheTTLHours,
    bool? enabled,
  }) {
    return PrefetchConfig(
      prefetchCount: prefetchCount ?? this.prefetchCount,
      enableOnCellular: enableOnCellular ?? this.enableOnCellular,
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      cacheTTLHours: cacheTTLHours ?? this.cacheTTLHours,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Service for prefetching profile images in discovery feed
///
/// Optimizes user experience by preloading images for upcoming profiles
/// before they are visible on screen. Uses intelligent network and memory
/// aware logic to avoid wasting bandwidth or causing memory issues.
///
/// Features:
/// - Priority queue (current + next N profiles)
/// - Network-aware (WiFi vs cellular)
/// - Memory pressure monitoring
/// - Configurable prefetch behavior
class MediaPrefetchService {
  static final MediaPrefetchService _instance =
      MediaPrefetchService._internal();
  factory MediaPrefetchService() => _instance;
  MediaPrefetchService._internal();

  final Connectivity _connectivity = Connectivity();
  PrefetchConfig _config = const PrefetchConfig();

  /// Currently prefetching URLs (to avoid duplicates)
  final Set<String> _prefetchingUrls = {};

  /// Memory pressure flag (set by system or when low memory detected)
  bool _memoryPressure = false;

  /// Prefetch operation subscriptions for cancellation
  final Map<String, StreamSubscription?> _prefetchSubscriptions = {};

  /// Update prefetch configuration
  void updateConfig(PrefetchConfig config) {
    _config = config;
    AppLogger.info(
      'MediaPrefetchService: Config updated - prefetchCount: ${config.prefetchCount}, cellular: ${config.enableOnCellular}',
    );
  }

  /// Get current configuration
  PrefetchConfig get config => _config;

  /// Set memory pressure flag (true = pause prefetching)
  void setMemoryPressure(bool pressure) {
    _memoryPressure = pressure;
    if (pressure) {
      AppLogger.warning(
        'MediaPrefetchService: Memory pressure detected, pausing prefetch',
      );
      _cancelAllPrefetch();
    }
  }

  /// Prefetch images for a list of profiles
  ///
  /// [profiles] - List of profiles to prefetch (current + upcoming)
  /// [currentIndex] - Index of currently visible profile
  Future<void> prefetchProfiles({
    required List<UserProfile> profiles,
    required int currentIndex,
  }) async {
    // Skip if disabled
    if (!_config.enabled) {
      return;
    }

    // Skip if memory pressure
    if (_memoryPressure) {
      AppLogger.debug(
        'MediaPrefetchService: Skipping prefetch due to memory pressure',
      );
      return;
    }

    // Check network connectivity
    final shouldPrefetch = await _shouldPrefetch();
    if (!shouldPrefetch) {
      AppLogger.debug(
        'MediaPrefetchService: Skipping prefetch due to network conditions',
      );
      return;
    }

    // Calculate range to prefetch (current + next N profiles)
    final startIndex = currentIndex;
    final endIndex = (currentIndex + _config.prefetchCount + 1).clamp(
      0,
      profiles.length,
    );

    if (startIndex >= profiles.length) {
      return;
    }

    final profilesToPrefetch = profiles.sublist(startIndex, endIndex);
    AppLogger.info(
      'MediaPrefetchService: Prefetching ${profilesToPrefetch.length} profiles (index $startIndex to ${endIndex - 1})',
    );

    // Prefetch each profile's images
    for (final profile in profilesToPrefetch) {
      if (_memoryPressure) {
        AppLogger.debug(
          'MediaPrefetchService: Stopping prefetch due to memory pressure',
        );
        break;
      }
      await _prefetchProfileImages(profile);
    }
  }

  /// Prefetch all images for a single profile
  Future<void> _prefetchProfileImages(UserProfile profile) async {
    if (profile.photos.isEmpty) {
      return;
    }

    // Prefetch all photos in priority order
    for (int i = 0; i < profile.photos.length; i++) {
      final photo = profile.photos[i];
      if (photo.url.isEmpty) {
        continue;
      }

      // Skip if already prefetching or memory pressure
      if (_prefetchingUrls.contains(photo.url) || _memoryPressure) {
        continue;
      }

      await _prefetchImage(photo.url);
    }
  }

  /// Prefetch a single image URL
  Future<void> _prefetchImage(String url) async {
    if (_prefetchingUrls.contains(url)) {
      return;
    }

    _prefetchingUrls.add(url);

    try {
      // Use CachedNetworkImage's prefetch functionality
      // This downloads and caches the image without displaying it
      final imageProvider = CachedNetworkImageProvider(url);

      // Precache the image (loads into memory cache)
      // Get context from NavigationService if available
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        await precacheImage(imageProvider, context);
        AppLogger.debug(
          'MediaPrefetchService: ✅ Prefetched image: ${_truncateUrl(url)}',
        );
      } else {
        // If no context available, just trigger the image provider
        // which will still download and cache the image
        AppLogger.debug(
          'MediaPrefetchService: ⚠️ No context for prefetch, skipping: ${_truncateUrl(url)}',
        );
      }
    } catch (e) {
      // Silently fail for prefetch errors (non-critical)
      AppLogger.debug(
        'MediaPrefetchService: ⚠️ Failed to prefetch ${_truncateUrl(url)}: $e',
      );
    } finally {
      _prefetchingUrls.remove(url);
    }
  }

  /// Check if prefetching should proceed based on network conditions
  Future<bool> _shouldPrefetch() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Always allow on WiFi
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return true;
      }

      // Check cellular setting
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return _config.enableOnCellular;
      }

      // No connectivity
      return false;
    } catch (e) {
      AppLogger.error('MediaPrefetchService: Failed to check connectivity: $e');
      return false; // Fail safe - don't prefetch if connectivity check fails
    }
  }

  /// Cancel all active prefetch operations
  void _cancelAllPrefetch() {
    _prefetchingUrls.clear();
    for (final subscription in _prefetchSubscriptions.values) {
      subscription?.cancel();
    }
    _prefetchSubscriptions.clear();
    AppLogger.info('MediaPrefetchService: Cancelled all prefetch operations');
  }

  /// Clear image cache (useful for low memory situations)
  Future<void> clearCache() async {
    try {
      await CachedNetworkImage.evictFromCache(''); // Clears entire cache
      AppLogger.info('MediaPrefetchService: Cache cleared');
    } catch (e) {
      AppLogger.error('MediaPrefetchService: Failed to clear cache: $e');
    }
  }

  /// Dispose resources (call when app terminates)
  void dispose() {
    _cancelAllPrefetch();
  }

  /// Truncate URL for logging (avoid long logs)
  String _truncateUrl(String url) {
    if (url.length <= 50) return url;
    return '${url.substring(0, 25)}...${url.substring(url.length - 20)}';
  }
}

/// Navigation service for global context access
/// Required for precacheImage which needs BuildContext
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
