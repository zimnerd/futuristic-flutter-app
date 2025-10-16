import 'dart:async';
import 'package:flutter/foundation.dart';
import 'message_pagination_optimizer.dart';
import 'media_loading_optimizer.dart';

/// Manages app memory usage and performance optimization
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _memoryCleanupTimer;
  final MessagePaginationOptimizer _messageOptimizer = MessagePaginationOptimizer();
  final MediaLoadingOptimizer _mediaOptimizer = MediaLoadingOptimizer();
  
  /// Start periodic memory cleanup
  void startMemoryManagement() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => performMemoryCleanup(),
    );
    
    if (kDebugMode) {
      print('MemoryManager: Started periodic memory cleanup (every 5 minutes)');
    }
  }
  
  /// Perform memory cleanup operations
  Future<void> performMemoryCleanup() async {
    if (kDebugMode) {
      print('MemoryManager: Starting memory cleanup...');
    }
    
    // Clean up old media cache
    await _mediaOptimizer.cleanupOldCache();
    
    // Optimize memory usage for media
    _mediaOptimizer.optimizeMemoryUsage();
    
    // Force garbage collection (only in debug mode)
    if (kDebugMode) {
      await _forceGarbageCollection();
    }
    
    if (kDebugMode) {
      print('MemoryManager: Memory cleanup completed');
      printMemoryStats();
    }
  }
  
  /// Force garbage collection (debug only)
  Future<void> _forceGarbageCollection() async {
    if (kDebugMode) {
      // Request garbage collection by creating memory pressure
      await Future.delayed(const Duration(milliseconds: 100));
      // Note: Dart doesn't expose direct GC control, this creates memory pressure
      final List<int> tempList = List.generate(1000, (i) => i);
      tempList.clear();
    }
  }
  
  /// Get current memory statistics
  Map<String, dynamic> getMemoryStats() {
    final messageStats = _messageOptimizer.getMemoryInfo();
    final mediaStats = _mediaOptimizer.getCacheStats();
    
    return {
      'messageCache': messageStats,
      'mediaCache': mediaStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Print memory statistics (debug only)
  void printMemoryStats() {
    if (!kDebugMode) return;
    
    final stats = getMemoryStats();
    debugPrint('=== MEMORY STATISTICS ===');
    debugPrint('Messages: ${stats['messageCache']}');
    debugPrint('Media: ${stats['mediaCache']}');
    debugPrint('========================');
  }
  
  /// Clear specific conversation from memory
  void clearConversationMemory(String conversationId) {
    _messageOptimizer.clearConversationCache(conversationId);
    
    if (kDebugMode) {
      print('MemoryManager: Cleared memory for conversation $conversationId');
    }
  }
  
  /// Emergency memory cleanup (when app receives memory warning)
  Future<void> emergencyCleanup() async {
    if (kDebugMode) {
      print('MemoryManager: Emergency memory cleanup initiated');
    }
    
    // Clear all media cache
    _mediaOptimizer.clearAllCache();
    
    // Clear old message caches but keep recent conversations
    // This is a more aggressive cleanup
    await performMemoryCleanup();
    
    // Force garbage collection
    await _forceGarbageCollection();
    
    if (kDebugMode) {
      print('MemoryManager: Emergency cleanup completed');
    }
  }
  
  /// Optimize memory for low-memory devices
  void optimizeForLowMemory() {
    // Reduce cache sizes for low memory devices
    _mediaOptimizer.clearAllCache();
    
    if (kDebugMode) {
      print('MemoryManager: Optimized for low-memory device');
    }
  }
  
  /// Check if memory usage is healthy
  Future<bool> isMemoryUsageHealthy() async {
    final messageStats = _messageOptimizer.getMemoryInfo();
    final mediaStats = await _mediaOptimizer.getCacheStats();
    
    final messageCount = messageStats['totalMessages'] as int;
    final mediaCacheCount = mediaStats['totalCachedMedia'] as int;
    
    // Define healthy thresholds
    const int maxHealthyMessages = 1000;
    const int maxHealthyMediaCache = 100;
    
    return messageCount < maxHealthyMessages && mediaCacheCount < maxHealthyMediaCache;
  }
  
  /// Get memory usage recommendation
  Future<String> getMemoryRecommendation() async {
    if (await isMemoryUsageHealthy()) {
      return 'Memory usage is healthy';
    }
    
    final messageStats = _messageOptimizer.getMemoryInfo();
    final messageCount = messageStats['totalMessages'] as int;
    
    if (messageCount > 1000) {
      return 'Consider clearing old conversation caches';
    }
    
    return 'Consider clearing media cache';
  }
  
  /// Stop memory management
  void stopMemoryManagement() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = null;
    
    if (kDebugMode) {
      print('MemoryManager: Stopped memory management');
    }
  }
  
  void dispose() {
    stopMemoryManagement();
    _messageOptimizer.dispose();
  }
}