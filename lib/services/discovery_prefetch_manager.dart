import 'package:flutter/material.dart';
import '../core/utils/logger.dart';
import '../core/network/api_client.dart';
import '../data/services/discovery_service.dart';
import '../domain/entities/user_profile.dart';
import 'media_prefetch_service.dart';

/// Manages discovery feed prefetching for background sync and app launch
///
/// This service ensures that discovery profiles are preloaded and cached
/// before users navigate to the discovery screen, providing zero-wait-time
/// experience.
///
/// Features:
/// - Background prefetch during app idle time
/// - App launch prefetch for instant discovery feed
/// - Integration with MediaPrefetchService for image caching
/// - Smart caching with configurable limits
class DiscoveryPrefetchManager {
  static final DiscoveryPrefetchManager _instance =
      DiscoveryPrefetchManager._internal();
  static DiscoveryPrefetchManager get instance => _instance;
  factory DiscoveryPrefetchManager() => _instance;

  DiscoveryPrefetchManager._internal();

  DiscoveryService? _discoveryService;

  /// Get discovery service instance (lazy initialization)
  DiscoveryService get _service {
    _discoveryService ??= DiscoveryService(apiClient: ApiClient.instance);
    return _discoveryService!;
  }

  List<UserProfile>? _cachedProfiles;
  DateTime? _lastPrefetchTime;
  bool _isPrefetching = false;

  // Configuration
  static const int _prefetchLimit =
      10; // Prefetch 10 profiles for smooth browsing
  static const Duration _cacheDuration = Duration(
    minutes: 15,
  ); // Cache valid for 15 minutes

  /// Get cached profiles if available and valid
  List<UserProfile>? get cachedProfiles {
    if (_cachedProfiles == null) return null;

    // Check if cache is still valid
    if (_lastPrefetchTime != null) {
      final cacheAge = DateTime.now().difference(_lastPrefetchTime!);
      if (cacheAge > _cacheDuration) {
        AppLogger.info('Cache expired (age: ${cacheAge.inMinutes}m)');
        _cachedProfiles = null;
        return null;
      }
    }

    return _cachedProfiles;
  }

  /// Check if we have valid cached profiles
  bool get hasCachedProfiles {
    return cachedProfiles != null && cachedProfiles!.isNotEmpty;
  }

  /// Prefetch discovery profiles and cache their images
  ///
  /// This method should be called:
  /// - During app launch (after authentication)
  /// - During background sync operations
  /// - When returning to app from background
  ///
  /// [context] is optional - if provided, will also prefetch images
  /// [force] will ignore cache and fetch fresh profiles
  Future<List<UserProfile>> prefetchProfiles({
    BuildContext? context,
    bool force = false,
  }) async {
    // Prevent concurrent prefetch operations
    if (_isPrefetching) {
      AppLogger.info('Prefetch already in progress, skipping');
      return _cachedProfiles ?? [];
    }

    // Return cached profiles if valid and not forcing refresh
    if (!force && hasCachedProfiles) {
      AppLogger.info('Returning ${_cachedProfiles!.length} cached profiles');
      return _cachedProfiles!;
    }

    _isPrefetching = true;

    try {
      AppLogger.info(
        'Starting discovery profile prefetch (limit: $_prefetchLimit)',
      );

      // Fetch profiles from API
      final profiles = await _service.getDiscoverableUsers(
        limit: _prefetchLimit,
        offset: 0,
      );

      AppLogger.info('Fetched ${profiles.length} discovery profiles');

      // Update cache
      _cachedProfiles = profiles;
      _lastPrefetchTime = DateTime.now();

      // Prefetch images if context provided
      if (context != null && profiles.isNotEmpty) {
        AppLogger.info('Prefetching images for ${profiles.length} profiles');

        // Use MediaPrefetchService to cache images
        // Pass profiles with currentIndex=0 to prefetch from start of list
        await MediaPrefetchService().prefetchProfiles(
          profiles: profiles,
          currentIndex: 0,
        );

        AppLogger.info('Image prefetch complete');
      }

      AppLogger.info(
        'Discovery prefetch complete: ${profiles.length} profiles cached',
      );

      return profiles;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error prefetching discovery profiles: $e',
        e,
        stackTrace,
      );

      // Return empty list on error but don't clear existing cache
      return _cachedProfiles ?? [];
    } finally {
      _isPrefetching = false;
    }
  }

  /// Prefetch profiles without context (background sync)
  ///
  /// This is used during background sync operations where BuildContext
  /// is not available. Profiles will be cached but images won't be prefetched.
  Future<void> prefetchProfilesBackground() async {
    try {
      AppLogger.info('Background prefetch triggered');

      await prefetchProfiles(
        context: null,
        force: false, // Use cache if valid
      );

      AppLogger.info('Background prefetch complete');
    } catch (e, stackTrace) {
      AppLogger.error('Background prefetch error: $e', e, stackTrace);
    }
  }

  /// Prefetch profiles with context (app launch or screen entry)
  ///
  /// This is used when BuildContext is available, allowing both profile
  /// fetching and image prefetching for zero-wait-time experience.
  Future<void> prefetchProfilesWithImages(BuildContext context) async {
    try {
      AppLogger.info('Prefetch with images triggered');

      await prefetchProfiles(
        context: context,
        force: false, // Use cache if valid
      );

      AppLogger.info('Prefetch with images complete');
    } catch (e, stackTrace) {
      AppLogger.error('Prefetch with images error: $e', e, stackTrace);
    }
  }

  /// Force refresh profiles (ignore cache)
  Future<void> refreshProfiles({BuildContext? context}) async {
    AppLogger.info('Force refresh triggered');

    await prefetchProfiles(context: context, force: true);
  }

  /// Clear cached profiles
  void clearCache() {
    AppLogger.info('Clearing discovery cache');
    _cachedProfiles = null;
    _lastPrefetchTime = null;
  }

  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo() {
    return {
      'hasCachedProfiles': hasCachedProfiles,
      'cachedProfileCount': _cachedProfiles?.length ?? 0,
      'lastPrefetchTime': _lastPrefetchTime?.toIso8601String(),
      'cacheAge': _lastPrefetchTime != null
          ? DateTime.now().difference(_lastPrefetchTime!).inMinutes
          : null,
      'isPrefetching': _isPrefetching,
    };
  }
}
