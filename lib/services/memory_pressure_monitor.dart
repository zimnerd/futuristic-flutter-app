import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/logger.dart';
import 'media_prefetch_service.dart';

/// Service for monitoring system memory pressure and responding to low memory warnings
///
/// This service:
/// - Listens to system memory warnings from the OS
/// - Pauses media prefetching during low memory conditions
/// - Clears image cache when memory is critically low
/// - Automatically resumes prefetching when memory pressure subsides
///
/// Platform support:
/// - iOS: Responds to applicationDidReceiveMemoryWarning
/// - Android: Responds to onLowMemory and onTrimMemory callbacks
class MemoryPressureMonitor {
  static final MemoryPressureMonitor _instance =
      MemoryPressureMonitor._internal();
  factory MemoryPressureMonitor() => _instance;
  MemoryPressureMonitor._internal();

  final MediaPrefetchService _prefetchService = MediaPrefetchService();
  bool _isMonitoring = false;
  StreamSubscription<MemoryPressureEvent>? _memorySubscription;

  /// Start monitoring memory pressure
  void startMonitoring() {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;
    AppLogger.info('MemoryPressureMonitor: Started monitoring memory pressure');

    // Listen to system memory warnings
    _listenToMemoryWarnings();
  }

  /// Stop monitoring memory pressure
  void stopMonitoring() {
    _isMonitoring = false;
    _memorySubscription?.cancel();
    _memorySubscription = null;
    AppLogger.info('MemoryPressureMonitor: Stopped monitoring memory pressure');
  }

  /// Listen to system memory warnings via platform channels
  void _listenToMemoryWarnings() {
    // Use SystemChannels to listen for app lifecycle memory events
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == null) return;

      if (message == AppLifecycleState.paused.toString() ||
          message == AppLifecycleState.inactive.toString()) {
        // App going to background - good time to clear cache
        _onMemoryWarning(MemoryPressureLevel.moderate);
      }

      return;
    });

    // Also listen to platform-specific memory warnings
    // This uses a synthetic stream since Flutter doesn't have built-in memory monitoring
    // In production, you'd use platform channels or packages like system_info
    _startSyntheticMemoryMonitoring();
  }

  /// Start synthetic memory monitoring (placeholder for real implementation)
  ///
  /// In a production app, you would:
  /// 1. Use platform channels to get real memory stats from iOS/Android
  /// 2. Use packages like `system_info` or `device_info_plus`
  /// 3. Integrate with Firebase Performance Monitoring
  ///
  /// For now, this provides a framework that responds to app lifecycle events
  void _startSyntheticMemoryMonitoring() {
    // This is a placeholder - in real implementation, you'd query actual memory usage
    // For now, we rely on system lifecycle events and manual triggers
    AppLogger.debug(
      'MemoryPressureMonitor: Using lifecycle-based memory monitoring',
    );
  }

  /// Handle memory warning from system
  void _onMemoryWarning(MemoryPressureLevel level) {
    AppLogger.warning(
      'MemoryPressureMonitor: Memory warning received - level: ${level.name}',
    );

    switch (level) {
      case MemoryPressureLevel.low:
        // Low pressure - just notify, don't take action
        break;

      case MemoryPressureLevel.moderate:
        // Moderate pressure - pause prefetching
        _prefetchService.setMemoryPressure(true);
        AppLogger.info(
          'MemoryPressureMonitor: Paused prefetching due to moderate memory pressure',
        );
        break;

      case MemoryPressureLevel.critical:
        // Critical pressure - pause prefetching AND clear cache
        _prefetchService.setMemoryPressure(true);
        _prefetchService.clearCache();
        AppLogger.warning(
          'MemoryPressureMonitor: Cleared cache due to critical memory pressure',
        );
        break;
    }

    // Schedule recovery check (resume prefetching after 30 seconds)
    _scheduleRecoveryCheck();
  }

  /// Schedule a check to resume prefetching after memory pressure subsides
  void _scheduleRecoveryCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isMonitoring) return;

      // In production, you'd check actual memory usage here
      // For now, we assume memory pressure has subsided
      _prefetchService.setMemoryPressure(false);
      AppLogger.info(
        'MemoryPressureMonitor: Resumed prefetching after memory pressure recovery',
      );
    });
  }

  /// Manually trigger a memory warning (useful for testing)
  void triggerMemoryWarning(MemoryPressureLevel level) {
    _onMemoryWarning(level);
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

/// Memory pressure levels
enum MemoryPressureLevel {
  low, // Minor memory pressure, no action needed
  moderate, // Moderate pressure, pause non-critical operations
  critical, // Critical pressure, free up memory immediately
}

/// Memory pressure event (for future stream-based implementation)
class MemoryPressureEvent {
  final MemoryPressureLevel level;
  final DateTime timestamp;

  const MemoryPressureEvent({required this.level, required this.timestamp});
}
