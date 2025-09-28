import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/chat_model.dart';
import 'chat_performance_config.dart';

/// Optimizes message loading and pagination for better performance
class MessagePaginationOptimizer {
  final Map<String, List<MessageModel>> _messageCache = {};
  final Map<String, bool> _isLoadingMore = {};
  final Map<String, StreamController<List<MessageModel>>> _messageControllers = {};
  
  /// Get messages with pagination and caching
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] = StreamController<List<MessageModel>>.broadcast();
    }
    return _messageControllers[conversationId]!.stream;
  }
  
  /// Add new messages to cache and stream
  void addMessages(String conversationId, List<MessageModel> newMessages, {bool isNewMessage = false}) {
    if (!_messageCache.containsKey(conversationId)) {
      _messageCache[conversationId] = [];
    }
    
    final cachedMessages = _messageCache[conversationId]!;
    
    if (isNewMessage) {
      // Add new message to the end (most recent)
      cachedMessages.addAll(newMessages);
    } else {
      // Add older messages to the beginning (pagination)
      cachedMessages.insertAll(0, newMessages);
    }
    
    // Limit cache size for memory management
    if (cachedMessages.length > ChatPerformanceConfig.maxCachedMessages) {
      final excess = cachedMessages.length - ChatPerformanceConfig.maxCachedMessages;
      cachedMessages.removeRange(0, excess);
      
      if (kDebugMode) {
        print('MessageCache: Trimmed $excess old messages for conversation $conversationId');
      }
    }
    
    // Update stream
    _messageControllers[conversationId]?.add(List.from(cachedMessages));
    
    // Record performance metrics
    ChatPerformanceMetrics.recordMessageLoad(conversationId, cachedMessages.length);
  }
  
  /// Check if we're currently loading more messages
  bool isLoadingMore(String conversationId) {
    return _isLoadingMore[conversationId] ?? false;
  }
  
  /// Set loading state
  void setLoadingMore(String conversationId, bool loading) {
    _isLoadingMore[conversationId] = loading;
  }
  
  /// Get cached message count
  int getCachedMessageCount(String conversationId) {
    return _messageCache[conversationId]?.length ?? 0;
  }
  
  /// Check if we should load more messages (pagination trigger)
  bool shouldLoadMore(String conversationId, int currentScrollIndex) {
    final cachedCount = getCachedMessageCount(conversationId);
    
    // Load more if we're near the beginning of cached messages
    return currentScrollIndex <= ChatPerformanceConfig.visibleMessageBuffer && 
           !isLoadingMore(conversationId) &&
           cachedCount > 0;
  }
  
  /// Get messages for a specific range (for virtualization)
  List<MessageModel> getMessagesRange(String conversationId, int start, int end) {
    final cachedMessages = _messageCache[conversationId];
    if (cachedMessages == null || cachedMessages.isEmpty) return [];
    
    final safeStart = start.clamp(0, cachedMessages.length);
    final safeEnd = end.clamp(safeStart, cachedMessages.length);
    
    return cachedMessages.sublist(safeStart, safeEnd);
  }
  
  /// Clear cache for specific conversation
  void clearConversationCache(String conversationId) {
    _messageCache.remove(conversationId);
    _isLoadingMore.remove(conversationId);
    _messageControllers[conversationId]?.close();
    _messageControllers.remove(conversationId);
    ChatPerformanceMetrics.clearMetrics(conversationId);
    
    if (kDebugMode) {
      print('MessageCache: Cleared cache for conversation $conversationId');
    }
  }
  
  /// Clear all caches (memory cleanup)
  void clearAllCaches() {
    for (final conversationId in _messageControllers.keys) {
      _messageControllers[conversationId]?.close();
    }
    
    _messageCache.clear();
    _isLoadingMore.clear();
    _messageControllers.clear();
    
    if (kDebugMode) {
      print('MessageCache: Cleared all caches');
    }
  }
  
  /// Get memory usage info
  Map<String, dynamic> getMemoryInfo() {
    int totalMessages = 0;
    for (final messages in _messageCache.values) {
      totalMessages += messages.length;
    }
    
    return {
      'conversations': _messageCache.length,
      'totalMessages': totalMessages,
      'averageMessagesPerConversation': _messageCache.isEmpty ? 0 : totalMessages / _messageCache.length,
      'memoryEfficiencyScore': totalMessages <= ChatPerformanceConfig.maxCachedMessages ? 'Good' : 'Needs Optimization',
    };
  }
  
  void dispose() {
    clearAllCaches();
  }
}