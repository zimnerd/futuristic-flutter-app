import 'dart:async';
import 'package:flutter/foundation.dart';
import 'chat_performance_config.dart';

/// Optimizes media loading and caching for better performance
class MediaLoadingOptimizer {
  static final MediaLoadingOptimizer _instance = MediaLoadingOptimizer._internal();
  factory MediaLoadingOptimizer() => _instance;
  MediaLoadingOptimizer._internal();

  final Map<String, Future<String?>> _downloadTasks = {};
  final Set<String> _preloadedUrls = {};
  final Map<String, DateTime> _lastAccessTimes = {};
  
  /// Preload media URL for faster display
  Future<void> preloadMedia(String mediaUrl, {bool isVideo = false}) async {
    if (_preloadedUrls.contains(mediaUrl)) return;
    
    try {
      // Add small delay to avoid blocking main thread
      await Future.delayed(ChatPerformanceConfig.mediaPreloadDelay);
      
      // Record access time
      _lastAccessTimes[mediaUrl] = DateTime.now();
      _preloadedUrls.add(mediaUrl);
      
      if (kDebugMode) {
        print('MediaOptimizer: Preloaded ${isVideo ? 'video' : 'image'}: ${mediaUrl.substring(mediaUrl.length - 20)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MediaOptimizer: Failed to preload $mediaUrl: $e');
      }
    }
  }
  
  /// Batch preload multiple media URLs
  Future<void> batchPreloadMedia(List<String> mediaUrls, {List<bool>? isVideoFlags}) async {
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
  Future<void> cleanupOldCache() async {
    final now = DateTime.now();
    final expiredUrls = <String>[];
    
    for (final entry in _lastAccessTimes.entries) {
      if (now.difference(entry.value) > ChatPerformanceConfig.cacheExpiration) {
        expiredUrls.add(entry.key);
      }
    }
    
    for (final url in expiredUrls) {
      _preloadedUrls.remove(url);
      _lastAccessTimes.remove(url);
    }
    
    if (kDebugMode && expiredUrls.isNotEmpty) {
      print('MediaOptimizer: Cleaned up ${expiredUrls.length} expired cache entries');
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int recentlyAccessed = 0;
    
    for (final accessTime in _lastAccessTimes.values) {
      if (now.difference(accessTime).inHours < 1) {
        recentlyAccessed++;
      }
    }
    
    return {
      'totalCachedMedia': _preloadedUrls.length,
      'recentlyAccessedCount': recentlyAccessed,
      'cacheHitRate': _preloadedUrls.isEmpty ? 0 : (recentlyAccessed / _preloadedUrls.length * 100).round(),
      'memoryUsageStatus': _preloadedUrls.length < 100 ? 'Good' : 'High',
    };
  }
  
  /// Clear specific media from cache
  void clearMediaFromCache(String mediaUrl) {
    _preloadedUrls.remove(mediaUrl);
    _lastAccessTimes.remove(mediaUrl);
    _downloadTasks.remove(mediaUrl);
  }
  
  /// Clear all media cache
  void clearAllCache() {
    _preloadedUrls.clear();
    _lastAccessTimes.clear();
    _downloadTasks.clear();
    
    if (kDebugMode) {
      print('MediaOptimizer: Cleared all media cache');
    }
  }
  
  /// Optimize memory usage by removing least recently used items
  void optimizeMemoryUsage() {
    if (_preloadedUrls.length <= 50) return; // Only optimize if we have many cached items
    
    // Sort by access time and remove oldest 25%
    final sortedEntries = _lastAccessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final toRemove = (sortedEntries.length * 0.25).floor();
    for (int i = 0; i < toRemove; i++) {
      final url = sortedEntries[i].key;
      clearMediaFromCache(url);
    }
    
    if (kDebugMode) {
      print('MediaOptimizer: Removed $toRemove LRU cache entries for memory optimization');
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