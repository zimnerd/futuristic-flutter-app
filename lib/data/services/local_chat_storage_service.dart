import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/ai_companion.dart';
import '../models/conversation.dart';

/// Local storage service for chat messages and conversations
/// Enables offline access to chat history
class LocalChatStorageService {
  static const String _conversationsKey = 'local_conversations';
  static const String _messagesPrefix = 'local_messages_';
  static const String _aiMessagesPrefix = 'local_ai_messages_';
  static const String _lastSyncPrefix = 'last_sync_';

  /// Save a regular chat message locally
  Future<void> saveMessage(Message message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_messagesPrefix${message.conversationId}';

      // Get existing messages
      final existing = await getMessages(message.conversationId);

      // Add new message if not already exists
      final existingIndex = existing.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        existing[existingIndex] = message; // Update existing
      } else {
        existing.add(message); // Add new
      }

      // Sort by timestamp
      existing.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Keep only last 1000 messages per conversation
      if (existing.length > 1000) {
        existing.removeRange(0, existing.length - 1000);
      }

      // Save to local storage
      final jsonList = existing.map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      // Silent fail - offline storage is not critical
    }
  }

  /// Save an AI companion message locally
  Future<void> saveAiMessage(CompanionMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_aiMessagesPrefix${message.companionId}';

      // Get existing messages
      final existing = await getAiMessages(message.companionId);

      // Add new message if not already exists
      final existingIndex = existing.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        existing[existingIndex] = message; // Update existing
      } else {
        existing.add(message); // Add new
      }

      // Sort by timestamp
      existing.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Keep only last 1000 messages per companion
      if (existing.length > 1000) {
        existing.removeRange(0, existing.length - 1000);
      }

      // Save to local storage
      final jsonList = existing.map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      // Silent fail - offline storage is not critical
    }
  }

  /// Get regular chat messages from local storage
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_messagesPrefix$conversationId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final messages = jsonList.map((json) => Message.fromJson(json)).toList();

      return messages;
    } catch (e) {
      return [];
    }
  }

  /// Get AI companion messages from local storage
  Future<List<CompanionMessage>> getAiMessages(String companionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_aiMessagesPrefix$companionId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final messages = jsonList
          .map((json) => CompanionMessage.fromJson(json))
          .toList();

      return messages;
    } catch (e) {
      return [];
    }
  }

  /// Save conversation metadata locally
  Future<void> saveConversation(Conversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing conversations
      final existing = await getConversations();

      // Update or add conversation
      final existingIndex = existing.indexWhere((c) => c.id == conversation.id);
      if (existingIndex >= 0) {
        existing[existingIndex] = conversation;
      } else {
        existing.add(conversation);
      }

      // Sort by creation time (since lastMessageAt may not exist)
      existing.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save to local storage
      final jsonList = existing.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(jsonList));
    } catch (e) {
      // Silent fail - offline storage is not critical
    }
  }

  /// Get conversations from local storage
  Future<List<Conversation>> getConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationsKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final conversations = jsonList
          .map((json) => Conversation.fromJson(json))
          .toList();

      return conversations;
    } catch (e) {
      return [];
    }
  }

  /// Mark messages as synced with server
  Future<void> markMessagesSynced(
    String conversationId,
    DateTime syncTime,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_lastSyncPrefix$conversationId';
      await prefs.setString(key, syncTime.toIso8601String());
    } catch (e) {
      // Silent fail
    }
  }

  /// Get last sync time for a conversation
  Future<DateTime?> getLastSyncTime(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_lastSyncPrefix$conversationId';
      final timeString = prefs.getString(key);

      if (timeString == null) return null;

      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  /// Clear all local chat data (useful for logout)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith(_messagesPrefix) ||
                key.startsWith(_aiMessagesPrefix) ||
                key.startsWith(_lastSyncPrefix) ||
                key == _conversationsKey,
          )
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Clear data for specific conversation
  Future<void> clearConversationData(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_messagesPrefix$conversationId');
      await prefs.remove('$_lastSyncPrefix$conversationId');
    } catch (e) {
      // Silent fail
    }
  }

  /// Clear data for specific AI companion
  Future<void> clearAiCompanionData(String companionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_aiMessagesPrefix$companionId');
      await prefs.remove('$_lastSyncPrefix$companionId');
    } catch (e) {
      // Silent fail
    }
  }

  /// Get storage usage statistics
  Future<Map<String, int>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int messageCount = 0;
      int aiMessageCount = 0;
      int conversationCount = 0;

      for (final key in keys) {
        if (key.startsWith(_messagesPrefix)) {
          final jsonString = prefs.getString(key);
          if (jsonString != null) {
            final List<dynamic> jsonList = jsonDecode(jsonString);
            messageCount += jsonList.length;
          }
        } else if (key.startsWith(_aiMessagesPrefix)) {
          final jsonString = prefs.getString(key);
          if (jsonString != null) {
            final List<dynamic> jsonList = jsonDecode(jsonString);
            aiMessageCount += jsonList.length;
          }
        } else if (key == _conversationsKey) {
          final jsonString = prefs.getString(key);
          if (jsonString != null) {
            final List<dynamic> jsonList = jsonDecode(jsonString);
            conversationCount = jsonList.length;
          }
        }
      }

      return {
        'totalMessages': messageCount,
        'totalAiMessages': aiMessageCount,
        'totalConversations': conversationCount,
      };
    } catch (e) {
      return {};
    }
  }
}
