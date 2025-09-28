import 'package:flutter/foundation.dart';

/// Performance configuration for PulseLink chat
class ChatPerformanceConfig {
  static const int messagesPerPage = 50;
  static const int maxCachedMessages = 500;
  static const Duration messageLoadTimeout = Duration(seconds: 10);
  static const Duration mediaPreloadDelay = Duration(milliseconds: 500);
  
  // Memory optimization settings
  static const int maxImageCacheSize = 100; // MB
  static const int maxVideoCacheSize = 200; // MB
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // UI performance settings
  static const double scrollPhysicsThreshold = 0.85;
  static const int visibleMessageBuffer = 5;
  static const Duration debounceTyping = Duration(milliseconds: 300);
}

/// Performance metrics tracker for chat
class ChatPerformanceMetrics {
  static final Map<String, DateTime> _loadTimes = {};
  static final Map<String, int> _messageCounts = {};
  
  static void recordMessageLoad(String conversationId, int messageCount) {
    _loadTimes[conversationId] = DateTime.now();
    _messageCounts[conversationId] = messageCount;
  }
  
  static Duration? getLoadTime(String conversationId) {
    final startTime = _loadTimes[conversationId];
    if (startTime == null) return null;
    return DateTime.now().difference(startTime);
  }
  
  static int getMessageCount(String conversationId) {
    return _messageCounts[conversationId] ?? 0;
  }
  
  static void clearMetrics(String conversationId) {
    _loadTimes.remove(conversationId);
    _messageCounts.remove(conversationId);
  }
  
  static void debugPrint(String conversationId) {
    if (kDebugMode) {
      final loadTime = getLoadTime(conversationId);
      final messageCount = getMessageCount(conversationId);
      print('Chat Performance - ID: $conversationId, Messages: $messageCount, Load Time: ${loadTime?.inMilliseconds}ms');
    }
  }
}