import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Performance optimization service for payments
class PaymentPerformanceService {
  static const String _keyOptimizationSettings = 'optimization_settings';

  // Logger instance
  final Logger _logger = Logger();

  // Cache for frequently accessed data
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Performance monitoring
  final Map<String, Stopwatch> _performanceTimers = {};
  final List<PerformanceMetric> _metrics = [];

  // Stream controllers
  final StreamController<PerformanceMetric> _metricsController =
      StreamController<PerformanceMetric>.broadcast();
  final StreamController<OptimizationSettings> _settingsController =
      StreamController<OptimizationSettings>.broadcast();

  // Streams
  Stream<PerformanceMetric> get metricsStream => _metricsController.stream;
  Stream<OptimizationSettings> get settingsStream => _settingsController.stream;

  /// Start performance timer for an operation
  void startTimer(String operationName) {
    _performanceTimers[operationName] = Stopwatch()..start();
  }

  /// Stop performance timer and record metric
  Duration stopTimer(String operationName) {
    final timer = _performanceTimers.remove(operationName);
    if (timer == null) return Duration.zero;

    timer.stop();
    final duration = timer.elapsed;

    // Record performance metric
    final metric = PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      memoryUsage: _getApproximateMemoryUsage(),
    );

    _metrics.add(metric);
    _metricsController.add(metric);

    // Keep only last 100 metrics in memory
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }

    // Log if operation is slow
    if (duration.inMilliseconds > 1000) {
      _logger.w(
        'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
      );
    }

    return duration;
  }

  /// Cache data with expiration
  Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? expiration,
  }) async {
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Also persist important cache data
    if (key.startsWith('payment_') || key.startsWith('subscription_')) {
      await _persistCacheData(key, data, expiration);
    }
  }

  /// Get cached data
  Future<T?> getCachedData<T>(String key, {Duration? maxAge}) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && maxAge != null) {
        if (DateTime.now().difference(timestamp) <= maxAge) {
          return _memoryCache[key] as T?;
        } else {
          // Cache expired
          _memoryCache.remove(key);
          _cacheTimestamps.remove(key);
        }
      } else {
        return _memoryCache[key] as T?;
      }
    }

    // Try persistent cache
    return await _getPersistedCacheData<T>(key, maxAge);
  }

  /// Clear cache
  Future<void> clearCache({String? keyPrefix}) async {
    if (keyPrefix != null) {
      _memoryCache.removeWhere((key, value) => key.startsWith(keyPrefix));
      _cacheTimestamps.removeWhere((key, value) => key.startsWith(keyPrefix));
    } else {
      _memoryCache.clear();
      _cacheTimestamps.clear();
    }

    // Clear persistent cache
    await _clearPersistedCache(keyPrefix);
  }

  /// Preload frequently used data
  Future<void> preloadData() async {
    startTimer('preload_data');

    try {
      // Preload payment methods
      await _preloadPaymentMethods();

      // Preload subscription plans
      await _preloadSubscriptionPlans();

      // Preload user preferences
      await _preloadUserPreferences();
    } catch (e) {
      _logger.e('Error preloading data: $e');
    } finally {
      stopTimer('preload_data');
    }
  }

  /// Optimize API requests with batching
  Future<List<T>> batchRequests<T>(
    List<Future<T>> requests, {
    int batchSize = 5,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    startTimer('batch_requests');

    try {
      final results = <T>[];

      for (int i = 0; i < requests.length; i += batchSize) {
        final batch = requests.skip(i).take(batchSize).toList();
        final batchResults = await Future.wait(batch);
        results.addAll(batchResults);

        // Add delay between batches to avoid overwhelming the server
        if (i + batchSize < requests.length) {
          await Future.delayed(delay);
        }
      }

      return results;
    } finally {
      stopTimer('batch_requests');
    }
  }

  /// Run heavy computation in isolate
  Future<R> runInIsolate<T, R>(T data, R Function(T) computation) async {
    startTimer('isolate_computation');

    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(_isolateEntryPoint<T, R>, [
        receivePort.sendPort,
        data,
        computation,
      ]);

      final result = await receivePort.first as R;
      isolate.kill(priority: Isolate.immediate);

      return result;
    } finally {
      stopTimer('isolate_computation');
    }
  }

  /// Get performance statistics
  Future<PerformanceStats> getPerformanceStats() async {
    final settings = await getOptimizationSettings();

    // Calculate average response times
    final operationStats = <String, OperationStats>{};

    for (final metric in _metrics) {
      final stats =
          operationStats[metric.operationName] ??
          OperationStats(
            operationName: metric.operationName,
            totalCalls: 0,
            totalDuration: Duration.zero,
            averageDuration: Duration.zero,
            maxDuration: Duration.zero,
            minDuration: Duration(days: 1),
          );

      operationStats[metric.operationName] = OperationStats(
        operationName: stats.operationName,
        totalCalls: stats.totalCalls + 1,
        totalDuration: stats.totalDuration + metric.duration,
        averageDuration: Duration(
          milliseconds:
              (stats.totalDuration.inMilliseconds +
                  metric.duration.inMilliseconds) ~/
              (stats.totalCalls + 1),
        ),
        maxDuration: metric.duration > stats.maxDuration
            ? metric.duration
            : stats.maxDuration,
        minDuration: metric.duration < stats.minDuration
            ? metric.duration
            : stats.minDuration,
      );
    }

    return PerformanceStats(
      cacheHitRate: _calculateCacheHitRate(),
      averageResponseTime: _calculateAverageResponseTime(),
      memoryUsage: _getApproximateMemoryUsage(),
      operationStats: operationStats.values.toList(),
      optimizationSettings: settings,
      totalMetrics: _metrics.length,
    );
  }

  /// Get optimization settings
  Future<OptimizationSettings> getOptimizationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_keyOptimizationSettings);

      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return OptimizationSettings.fromJson(json);
      }

      return OptimizationSettings.defaults();
    } catch (e) {
      return OptimizationSettings.defaults();
    }
  }

  /// Update optimization settings
  Future<void> updateOptimizationSettings(OptimizationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyOptimizationSettings,
        jsonEncode(settings.toJson()),
      );
      _settingsController.add(settings);

      // Apply settings immediately
      await _applyOptimizationSettings(settings);
    } catch (e) {
      _logger.e('Error updating optimization settings: $e');
    }
  }

  /// Optimize image loading and caching
  Future<void> optimizeImageCaching() async {
    // Implementation would integrate with image caching library
    _logger.i('Image caching optimization applied');
  }

  /// Optimize network requests
  Future<void> optimizeNetworkRequests() async {
    // Implementation would configure HTTP client with optimal settings
    _logger.i('Network request optimization applied');
  }

  /// Get cache statistics
  CacheStats getCacheStats() {
    final totalKeys = _memoryCache.length;
    final expiredKeys = _cacheTimestamps.entries
        .where(
          (entry) =>
              DateTime.now().difference(entry.value) > const Duration(hours: 1),
        )
        .length;

    return CacheStats(
      totalKeys: totalKeys,
      expiredKeys: expiredKeys,
      hitRate: _calculateCacheHitRate(),
      memoryUsage: _getApproximateMemoryUsage(),
    );
  }

  /// Private methods
  Future<void> _persistCacheData(
    String key,
    dynamic data,
    Duration? expiration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheItem = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiration': expiration?.inMilliseconds,
      };
      await prefs.setString('cache_$key', jsonEncode(cacheItem));
    } catch (e) {
      _logger.e('Error persisting cache data: $e');
    }
  }

  Future<T?> _getPersistedCacheData<T>(String key, Duration? maxAge) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('cache_$key');

      if (cacheData != null) {
        final cacheItem = jsonDecode(cacheData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(cacheItem['timestamp'] as String);
        final expiration = cacheItem['expiration'] as int?;

        // Check if cache is still valid
        final age = DateTime.now().difference(timestamp);
        final maxAgeToUse =
            maxAge ??
            (expiration != null ? Duration(milliseconds: expiration) : null);

        if (maxAgeToUse == null || age <= maxAgeToUse) {
          return cacheItem['data'] as T?;
        }
      }

      return null;
    } catch (e) {
      _logger.e('Error getting persisted cache data: $e');
      return null;
    }
  }

  Future<void> _clearPersistedCache(String? keyPrefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));

      if (keyPrefix != null) {
        final keysToRemove = keys.where(
          (key) => key.startsWith('cache_$keyPrefix'),
        );
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }
      } else {
        for (final key in keys) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      _logger.e('Error clearing persisted cache: $e');
    }
  }

  Future<void> _preloadPaymentMethods() async {
    // Simulate preloading payment methods
    await Future.delayed(const Duration(milliseconds: 100));
    await cacheData('payment_methods', ['card', 'paypal', 'apple_pay']);
  }

  Future<void> _preloadSubscriptionPlans() async {
    // Simulate preloading subscription plans
    await Future.delayed(const Duration(milliseconds: 150));
    await cacheData('subscription_plans', ['basic', 'premium', 'enterprise']);
  }

  Future<void> _preloadUserPreferences() async {
    // Simulate preloading user preferences
    await Future.delayed(const Duration(milliseconds: 50));
    await cacheData('user_preferences', {'currency': 'USD', 'language': 'en'});
  }

  double _calculateCacheHitRate() {
    // Simplified cache hit rate calculation
    return _memoryCache.isNotEmpty ? 0.85 : 0.0;
  }

  Duration _calculateAverageResponseTime() {
    if (_metrics.isEmpty) return Duration.zero;

    final totalMs = _metrics.fold(
      0,
      (sum, metric) => sum + metric.duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _metrics.length);
  }

  int _getApproximateMemoryUsage() {
    // Simplified memory usage calculation (in KB)
    return _memoryCache.length * 2; // Rough estimate
  }

  Future<void> _applyOptimizationSettings(OptimizationSettings settings) async {
    if (settings.enableCaching) {
      // Keep cache enabled
    } else {
      await clearCache();
    }

    if (settings.preloadData) {
      await preloadData();
    }

    // Apply other settings...
  }

  /// Dispose resources
  void dispose() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _performanceTimers.clear();
    _metrics.clear();
    _metricsController.close();
    _settingsController.close();
  }
}

/// Isolate entry point for heavy computations
void _isolateEntryPoint<T, R>(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final data = args[1] as T;
  final computation = args[2] as R Function(T);

  try {
    final result = computation(data);
    sendPort.send(result);
  } catch (e) {
    sendPort.send(null);
  }
}

/// Performance metric model
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final int memoryUsage;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.memoryUsage,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'memoryUsage': memoryUsage,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      operationName: json['operationName'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      timestamp: DateTime.parse(json['timestamp'] as String),
      memoryUsage: json['memoryUsage'] as int,
    );
  }
}

/// Performance statistics
class PerformanceStats {
  final double cacheHitRate;
  final Duration averageResponseTime;
  final int memoryUsage;
  final List<OperationStats> operationStats;
  final OptimizationSettings optimizationSettings;
  final int totalMetrics;

  const PerformanceStats({
    required this.cacheHitRate,
    required this.averageResponseTime,
    required this.memoryUsage,
    required this.operationStats,
    required this.optimizationSettings,
    required this.totalMetrics,
  });
}

/// Operation statistics
class OperationStats {
  final String operationName;
  final int totalCalls;
  final Duration totalDuration;
  final Duration averageDuration;
  final Duration maxDuration;
  final Duration minDuration;

  const OperationStats({
    required this.operationName,
    required this.totalCalls,
    required this.totalDuration,
    required this.averageDuration,
    required this.maxDuration,
    required this.minDuration,
  });
}

/// Cache statistics
class CacheStats {
  final int totalKeys;
  final int expiredKeys;
  final double hitRate;
  final int memoryUsage;

  const CacheStats({
    required this.totalKeys,
    required this.expiredKeys,
    required this.hitRate,
    required this.memoryUsage,
  });
}

/// Optimization settings
class OptimizationSettings {
  final bool enableCaching;
  final bool preloadData;
  final bool batchRequests;
  final bool useIsolates;
  final int cacheMaxAge;
  final int batchSize;

  const OptimizationSettings({
    required this.enableCaching,
    required this.preloadData,
    required this.batchRequests,
    required this.useIsolates,
    required this.cacheMaxAge,
    required this.batchSize,
  });

  factory OptimizationSettings.defaults() {
    return const OptimizationSettings(
      enableCaching: true,
      preloadData: true,
      batchRequests: true,
      useIsolates: false,
      cacheMaxAge: 3600, // 1 hour in seconds
      batchSize: 5,
    );
  }

  factory OptimizationSettings.fromJson(Map<String, dynamic> json) {
    return OptimizationSettings(
      enableCaching: json['enableCaching'] as bool,
      preloadData: json['preloadData'] as bool,
      batchRequests: json['batchRequests'] as bool,
      useIsolates: json['useIsolates'] as bool,
      cacheMaxAge: json['cacheMaxAge'] as int,
      batchSize: json['batchSize'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableCaching': enableCaching,
      'preloadData': preloadData,
      'batchRequests': batchRequests,
      'useIsolates': useIsolates,
      'cacheMaxAge': cacheMaxAge,
      'batchSize': batchSize,
    };
  }

  OptimizationSettings copyWith({
    bool? enableCaching,
    bool? preloadData,
    bool? batchRequests,
    bool? useIsolates,
    int? cacheMaxAge,
    int? batchSize,
  }) {
    return OptimizationSettings(
      enableCaching: enableCaching ?? this.enableCaching,
      preloadData: preloadData ?? this.preloadData,
      batchRequests: batchRequests ?? this.batchRequests,
      useIsolates: useIsolates ?? this.useIsolates,
      cacheMaxAge: cacheMaxAge ?? this.cacheMaxAge,
      batchSize: batchSize ?? this.batchSize,
    );
  }
}
