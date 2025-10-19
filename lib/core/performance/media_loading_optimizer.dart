import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'chat_performance_config.dart';
import '../../data/services/cache_ttl_service.dart';

/// Optimizes media loading and caching for better performance
/// Now integrated with CacheTTLService for persistent cache metadata
class MediaLoadingOptimizer {
  static final MediaLoadingOptimizer _instance =
      MediaLoadingOptimizer._internal();
  factory MediaLoadingOptimizer() => _instance;
  MediaLoadingOptimizer._internal();

  final Map<String, Future<String?>> _downloadTasks = {};
  final Set<String> _preloadedUrls = {};
  final Map<String, DateTime> _lastAccessTimes = {};
  final CacheTTLService _cacheTTLService = CacheTTLService();

  /// Generate cache key from URL
  String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Preload media URL for faster display
  Future<void> preloadMedia(
    String mediaUrl, {
    bool isVideo = false,
    String? cacheType,
  }) async {
    if (_preloadedUrls.contains(mediaUrl)) {
      // Still record access for TTL tracking
      final cacheKey = _getCacheKey(mediaUrl);
      await _cacheTTLService.recordAccess(cacheKey);
      return;
    }

    try {
      // Add small delay to avoid blocking main thread
      await Future.delayed(ChatPerformanceConfig.mediaPreloadDelay);

      // Record access time
      _lastAccessTimes[mediaUrl] = DateTime.now();
      _preloadedUrls.add(mediaUrl);

      // Record in persistent cache TTL service
      final cacheKey = _getCacheKey(mediaUrl);
      final type = cacheType ?? (isVideo ? 'video' : 'image');
      await _cacheTTLService.recordCachedItem(
        cacheKey: cacheKey,
        cacheType: type,
        url: mediaUrl,
      );

      if (kDebugMode) {
        print(
          'MediaOptimizer: Preloaded ${isVideo ? 'video' : 'image'}: ${mediaUrl.substring(mediaUrl.length - 20)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error optimizing image: $e');
      }
    }
  }

  /// Batch preload multiple media URLs
  Future<void> batchPreloadMedia(
    List<String> mediaUrls, {
    List<bool>? isVideoFlags,
  }) async {
    final futures = <Future<void>>[];

    for (int i = 0; i < mediaUrls.length; i++) {
      final isVideo = isVideoFlags?[i] ?? false;
      futures.add(preloadMedia(mediaUrls[i], isVideo: isVideo));
    }

    await Future.wait(futures);
  }

  /// Check if media is already preloaded
  bool isMediaPreloaded(String mediaUrl) {
    return _preloadedUrls.contains(mediaUrl);
  }

  /// Get optimized loading priority for media
  int getLoadingPriority(String mediaUrl, bool isVisible) {
    if (isVisible && !isMediaPreloaded(mediaUrl)) {
      return 1; // High priority - visible and not cached
    } else if (isVisible) {
      return 2; // Medium priority - visible but cached
    } else {
      return 3; // Low priority - not visible
    }
  }

  /// Clean up old cache entries
  /// Now uses CacheTTLService for persistent expiration tracking
  Future<void> cleanupOldCache() async {
    try {
      // Get expired items from persistent cache
      final expiredItems = await _cacheTTLService.getExpiredCacheItems();
      final expiredUrls = <String>[];

      // Clean up in-memory cache
      for (final item in expiredItems) {
        final url = item['url'] as String;
        _preloadedUrls.remove(url);
        _lastAccessTimes.remove(url);
        expiredUrls.add(url);
      }

      // Remove expired metadata from database
      final deletedCount = await _cacheTTLService.removeExpiredMetadata();

      if (kDebugMode && expiredUrls.isNotEmpty) {
        debugPrint(
          'MediaOptimizer: Cleaned up ${expiredUrls.length} expired cache entries ($deletedCount from DB)',
        );
      }

      // Also extend TTL for frequently accessed items
      await _cacheTTLService.extendTTLForFrequentItems();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cleaning up cache: $e');
      }
    }
  }

  /// Get cache statistics
  /// Now includes persistent cache TTL data
  Future<Map<String, dynamic>> getCacheStats() async {
    final now = DateTime.now();
    int recentlyAccessed = 0;

    for (final accessTime in _lastAccessTimes.values) {
      if (now.difference(accessTime).inHours < 1) {
        recentlyAccessed++;
      }
    }

    // Get persistent cache stats
    final ttlStats = await _cacheTTLService.getCacheStats();

    return {
      // In-memory stats
      'inMemoryCached': _preloadedUrls.length,
      'recentlyAccessed': recentlyAccessed,
      'cacheHitRate': _preloadedUrls.isEmpty
          ? 0
          : (recentlyAccessed / _preloadedUrls.length * 100).round(),
      'memoryStatus': _preloadedUrls.length < 100 ? 'Good' : 'High',

      // Persistent cache stats (from CacheTTLService)
      'persistentStats': ttlStats,
    };
  }

  /// Clear specific media from cache
  Future<void> clearMediaFromCache(String mediaUrl) async {
    _preloadedUrls.remove(mediaUrl);
    _lastAccessTimes.remove(mediaUrl);
    _downloadTasks.remove(mediaUrl);

    // Remove from persistent cache
    final cacheKey = _getCacheKey(mediaUrl);
    await _cacheTTLService.removeCacheMetadata([cacheKey]);
  }

  /// Clear all media cache
  Future<void> clearAllCache() async {
    _preloadedUrls.clear();
    _lastAccessTimes.clear();
    _downloadTasks.clear();

    // Clear persistent cache metadata
    await _cacheTTLService.clearAllCacheMetadata();

    if (kDebugMode) {
      print('MediaOptimizer: Cleared all media cache');
    }
  }

  /// Optimize memory usage by removing least recently used items
  void optimizeMemoryUsage() {
    if (_preloadedUrls.length <= 50)
      return; // Only optimize if we have many cached items

    // Sort by access time and remove oldest 25%
    final sortedEntries = _lastAccessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final toRemove = (sortedEntries.length * 0.25).floor();
    for (int i = 0; i < toRemove; i++) {
      final url = sortedEntries[i].key;
      clearMediaFromCache(url);
    }

    if (kDebugMode) {
      print(
        'MediaOptimizer: Removed $toRemove LRU cache entries for memory optimization',
      );
    }
  }

  /// Cleanup resources
  void dispose() {
    _preloadedUrls.clear();
    _lastAccessTimes.clear();
    _downloadTasks.clear();

    if (kDebugMode) {
      print('MediaOptimizer: Disposed all cached resources');
    }
  }
}

/// Widget-level media optimization helper
class MediaOptimizationHelper {
  /// Should we show low-res placeholder first?
  static bool shouldShowPlaceholder(String mediaUrl, bool isVisible) {
    final optimizer = MediaLoadingOptimizer();
    return !optimizer.isMediaPreloaded(mediaUrl) && !isVisible;
  }

  /// Get recommended image quality based on context
  static double getRecommendedImageQuality(bool isFullScreen, bool isVisible) {
    if (isFullScreen) return 1.0; // Full quality for full screen
    if (!isVisible) return 0.5; // Lower quality for non-visible
    return 0.8; // Good quality for visible thumbnails
  }

  /// Should we prioritize this media loading?
  static bool shouldPrioritizeLoading(bool isVisible, bool isInViewport) {
    return isVisible && isInViewport;
  }
}
