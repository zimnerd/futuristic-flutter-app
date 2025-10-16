import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../database/chat_database.dart';
import '../database/models/database_models.dart';

/// Service for managing messages in local SQLite database
/// Handles pagination, caching, and offline synchronization
class MessageDatabaseService {
  static final MessageDatabaseService _instance = MessageDatabaseService._internal();
  factory MessageDatabaseService() => _instance;
  MessageDatabaseService._internal();

  static const int _defaultPageSize = 20;
  static final Logger _logger = Logger();

  /// Get database instance
  Future<Database> get _db async => await ChatDatabase.instance.database;

  // ================== MESSAGE CRUD OPERATIONS ==================

  /// Insert or update message in local database
  Future<void> saveMessage(MessageDbModel message) async {
    try {
      final db = await _db;
      await db.insert(
        'messages',
        message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Update conversation's last message metadata
      await _updateConversationLastMessage(message);
      
      _logger.d('Message saved to database: ${message.id}');
    } catch (e, stackTrace) {
      _logger.e('Error saving message to database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Batch insert messages for efficient loading
  Future<void> saveMessages(List<MessageDbModel> messages) async {
    if (messages.isEmpty) return;
    
    try {
      final db = await _db;
      final batch = db.batch();
      
      for (final message in messages) {
        batch.insert(
          'messages',
          message.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      
      // Update conversation metadata with latest message
      if (messages.isNotEmpty) {
        final latestMessage = messages.reduce((a, b) => 
          a.createdAt.isAfter(b.createdAt) ? a : b
        );
        await _updateConversationLastMessage(latestMessage);
      }
      
      _logger.d('Batch saved ${messages.length} messages to database');
    } catch (e, stackTrace) {
      _logger.e('Error batch saving messages', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get messages with cursor-based pagination
  Future<List<MessageDbModel>> getMessages({
    required String conversationId,
    String? cursorMessageId,
    int limit = _defaultPageSize,
  }) async {
    try {
      final db = await _db;
      
      String whereClause = 'conversation_id = ?';
      List<dynamic> whereArgs = [conversationId];
      
      // Add cursor condition for pagination
      if (cursorMessageId != null) {
        final cursorMessage = await _getMessageById(cursorMessageId);
        if (cursorMessage != null) {
          whereClause += ' AND created_at < ?';
          whereArgs.add(cursorMessage.createdAt.millisecondsSinceEpoch);
        }
      }
      
      final result = await db.query(
        'messages',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      final messages = result.map((map) => MessageDbModel.fromMap(map)).toList();
      
      _logger.d('Retrieved ${messages.length} messages for conversation $conversationId');
      return messages;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get latest messages for conversation (for real-time updates)
  Future<List<MessageDbModel>> getLatestMessages({
    required String conversationId,
    int limit = _defaultPageSize,
  }) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      final messages = result.map((map) => MessageDbModel.fromMap(map)).toList();
      
      _logger.d('Retrieved ${messages.length} latest messages for conversation $conversationId');
      return messages;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving latest messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Find message by temp ID for optimistic updates
  Future<MessageDbModel?> getMessageByTempId(String tempId) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'messages',
        where: 'temp_id = ?',
        whereArgs: [tempId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final message = MessageDbModel.fromMap(result.first);
        _logger.d('Found message by temp ID: $tempId -> ${message.id}');
        return message;
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error finding message by temp ID', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update message status (delivered, read, etc.)
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      final db = await _db;
      
      await db.update(
        'messages',
        {
          'status': status,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'sync_status': 'synced',
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );
      
      _logger.d('Updated message status: $messageId -> $status');
    } catch (e, stackTrace) {
      _logger.e('Error updating message status', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Replace optimistic message with server message
  Future<void> replaceOptimisticMessage({
    required String tempId,
    required MessageDbModel serverMessage,
  }) async {
    try {
      final db = await _db;
      
      // Delete optimistic message
      await db.delete(
        'messages',
        where: 'temp_id = ?',
        whereArgs: [tempId],
      );
      
      // Insert server message
      await db.insert(
        'messages',
        serverMessage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      _logger.d('Replaced optimistic message: $tempId -> ${serverMessage.id}');
    } catch (e, stackTrace) {
      _logger.e('Error replacing optimistic message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ================== CONVERSATION OPERATIONS ==================

  /// Save conversation metadata
  Future<void> saveConversation(ConversationDbModel conversation) async {
    try {
      final db = await _db;
      await db.insert(
        'conversations',
        conversation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      _logger.d('Conversation saved: ${conversation.id}');
    } catch (e, stackTrace) {
      _logger.e('Error saving conversation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get conversation by ID
  Future<ConversationDbModel?> getConversation(String conversationId) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'conversations',
        where: 'id = ?',
        whereArgs: [conversationId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return ConversationDbModel.fromMap(result.first);
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving conversation', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all conversations ordered by last message
  Future<List<ConversationDbModel>> getConversations() async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'conversations',
        orderBy: 'updated_at DESC',
      );
      
      return result.map((map) => ConversationDbModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      _logger.e('Error retrieving conversations', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // ================== PAGINATION METADATA ==================

  /// Save pagination metadata
  Future<void> savePaginationMetadata(PaginationMetadata metadata) async {
    try {
      final db = await _db;
      await db.insert(
        'pagination_metadata',
        metadata.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      _logger.d('Pagination metadata saved for conversation: ${metadata.conversationId}');
    } catch (e, stackTrace) {
      _logger.e('Error saving pagination metadata', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get pagination metadata for conversation
  Future<PaginationMetadata?> getPaginationMetadata(String conversationId) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'pagination_metadata',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return PaginationMetadata.fromMap(result.first);
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving pagination metadata', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ================== HELPER METHODS ==================

  /// Get message by ID (internal helper)
  Future<MessageDbModel?> _getMessageById(String messageId) async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return MessageDbModel.fromMap(result.first);
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving message by ID', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update conversation's last message metadata
  Future<void> _updateConversationLastMessage(MessageDbModel message) async {
    try {
      final db = await _db;
      
      await db.update(
        'conversations',
        {
          'last_message_id': message.id,
          'last_message_at': message.createdAt.millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [message.conversationId],
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating conversation last message', error: e, stackTrace: stackTrace);
    }
  }

  // ================== DATA MANAGEMENT ==================

  /// Get unsynced messages for background sync
  Future<List<MessageDbModel>> getUnsyncedMessages() async {
    try {
      final db = await _db;
      
      final result = await db.query(
        'messages',
        where: 'sync_status != ?',
        whereArgs: ['synced'],
        orderBy: 'created_at ASC',
      );
      
      return result.map((map) => MessageDbModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      _logger.e('Error retrieving unsynced messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Mark messages as synced
  Future<void> markMessagesSynced(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    
    try {
      final db = await _db;
      final batch = db.batch();
      
      for (final messageId in messageIds) {
        batch.update(
          'messages',
          {
            'sync_status': 'synced',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [messageId],
        );
      }
      
      await batch.commit(noResult: true);
      _logger.d('Marked ${messageIds.length} messages as synced');
    } catch (e, stackTrace) {
      _logger.e('Error marking messages as synced', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Clear old messages to manage storage
  Future<void> clearOldMessages({
    required String conversationId,
    required int keepLatestCount,
  }) async {
    try {
      final db = await _db;
      
      // Get messages to keep (latest ones)
      final messagesToKeep = await db.query(
        'messages',
        columns: ['id'],
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at DESC',
        limit: keepLatestCount,
      );
      
      if (messagesToKeep.isEmpty) return;
      
      final keepIds = messagesToKeep.map((m) => "'${m['id']}'").join(',');
      
      // Delete messages not in the keep list
      await db.delete(
        'messages',
        where: 'conversation_id = ? AND id NOT IN ($keepIds)',
        whereArgs: [conversationId],
      );
      
      _logger.d('Cleared old messages for conversation $conversationId, kept latest $keepLatestCount');
    } catch (e, stackTrace) {
      _logger.e('Error clearing old messages', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final dbStats = await ChatDatabase.instance.getStats();
      
      final db = await _db;
      
      // Get unsynced message count
      final unsyncedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM messages WHERE sync_status != ?',
        ['synced'],
      );
      final unsyncedCount = unsyncedResult.first['count'] as int;
      
      return {
        ...dbStats,
        'unsynced_messages': unsyncedCount,
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting database stats', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  // ================== OUTBOX OPERATIONS (OFFLINE MESSAGE QUEUE) ==================

  /// Add message to outbox for retry when offline
  Future<void> addToOutbox(MessageDbModel message) async {
    try {
      final db = await _db;
      await db.insert('message_outbox', {
        'temp_id': message.tempId ?? message.id,
        'conversation_id': message.conversationId,
        'content': message.content ?? '',
        'type': message.type,
        'media_local_path': message.mediaUrls,
        'created_at': message.createdAt.millisecondsSinceEpoch,
        'retry_count': 0,
        'last_error': null,
        'last_retry_at': null,
      });

      _logger.d('Message added to outbox: ${message.tempId ?? message.id}');
    } catch (e, stackTrace) {
      _logger.e('Error adding message to outbox', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all pending messages from outbox (max 3 retries)
  Future<List<Map<String, dynamic>>> getPendingOutbox() async {
    try {
      final db = await _db;
      final result = await db.query(
        'message_outbox',
        where: 'retry_count < ?',
        whereArgs: [3], // Max 3 retries
        orderBy: 'created_at ASC',
      );

      _logger.d('Retrieved ${result.length} pending outbox messages');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving pending outbox', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get outbox messages for a specific conversation
  Future<List<Map<String, dynamic>>> getConversationOutbox(String conversationId) async {
    try {
      final db = await _db;
      final result = await db.query(
        'message_outbox',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving conversation outbox', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Remove message from outbox after successful send
  Future<void> removeFromOutbox(String tempId) async {
    try {
      final db = await _db;
      await db.delete('message_outbox', where: 'temp_id = ?', whereArgs: [tempId]);

      _logger.d('Removed message from outbox: $tempId');
    } catch (e, stackTrace) {
      _logger.e('Error removing message from outbox', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Increment retry count for failed send attempt
  Future<void> incrementRetryCount(String tempId, String? error) async {
    try {
      final db = await _db;
      await db.rawUpdate(
        '''UPDATE message_outbox
           SET retry_count = retry_count + 1,
               last_error = ?,
               last_retry_at = ?
           WHERE temp_id = ?''',
        [error ?? 'Unknown error', DateTime.now().millisecondsSinceEpoch, tempId],
      );

      _logger.d('Incremented retry count for outbox message: $tempId');
    } catch (e, stackTrace) {
      _logger.e('Error incrementing retry count', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Clear all failed messages from outbox (exceeded max retries)
  Future<void> clearFailedOutbox() async {
    try {
      final db = await _db;
      final deletedCount = await db.delete(
        'message_outbox',
        where: 'retry_count >= ?',
        whereArgs: [3],
      );

      _logger.d('Cleared $deletedCount failed outbox messages');
    } catch (e, stackTrace) {
      _logger.e('Error clearing failed outbox', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get outbox statistics
  Future<Map<String, int>> getOutboxStats() async {
    try {
      final db = await _db;

      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM message_outbox');
      final total = totalResult.first['count'] as int;

      final failedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM message_outbox WHERE retry_count >= ?',
        [3],
      );
      final failed = failedResult.first['count'] as int;

      return {
        'total': total,
        'pending': total - failed,
        'failed': failed,
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting outbox stats', error: e, stackTrace: stackTrace);
      return {'total': 0, 'pending': 0, 'failed': 0};
    }
  }

  // ================== BACKGROUND SYNC SUPPORT METHODS ==================

  /// Get all conversations (alias for getConversations for background sync)
  Future<List<ConversationDbModel>> getAllConversations() async {
    return await getConversations();
  }

  /// Get the latest message for a specific conversation
  Future<MessageDbModel?> getLatestMessage(String conversationId) async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return MessageDbModel.fromMap(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e(
        'Error getting latest message for conversation $conversationId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      final db = await _db;
      await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
      _logger.d('Deleted message: $messageId');
    } catch (e, stackTrace) {
      _logger.e(
        'Error deleting message $messageId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get old optimistic messages that should be cleaned up
  Future<List<MessageDbModel>> getOldOptimisticMessages(
    DateTime threshold,
  ) async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'temp_id IS NOT NULL AND created_at < ?',
        whereArgs: [threshold.millisecondsSinceEpoch],
        orderBy: 'created_at ASC',
      );

      return maps.map((map) => MessageDbModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      _logger.e(
        'Error getting old optimistic messages',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Optimize database (vacuum, analyze)
  Future<void> optimizeDatabase() async {
    try {
      final db = await _db;

      // Run VACUUM to reclaim space
      await db.execute('VACUUM');

      // Run ANALYZE to update query planner statistics
      await db.execute('ANALYZE');

      _logger.d('Database optimization completed');
    } catch (e, stackTrace) {
      _logger.e('Error optimizing database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}