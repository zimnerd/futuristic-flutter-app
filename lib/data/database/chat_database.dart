import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../services/cache_ttl_service.dart';

/// Local SQLite database for chat messages and conversations
/// Optimized for WhatsApp-style messaging with pagination and offline support
class ChatDatabase {
  static const String _databaseName = 'pulse_chat.db';
  static const int _databaseVersion = 3;

  static Database? _database;
  static final Logger _logger = Logger();

  /// Singleton instance
  static final ChatDatabase instance = ChatDatabase._internal();
  ChatDatabase._internal();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with optimized schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _logger.d('Initializing chat database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database for optimal performance
  Future<void> _onConfigure(Database db) async {
    _logger.d('Configuring database for optimal performance...');

    // Try to enable Write-Ahead Logging for better concurrency
    // WAL mode allows readers and writers to work simultaneously
    // Note: WAL mode may fail on iOS Simulator, so we catch and fallback
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      _logger.d('WAL mode enabled successfully');
    } catch (e) {
      _logger.w(
        'WAL mode failed (common on iOS Simulator), using DELETE mode: $e',
      );
      // Fallback to DELETE mode (default SQLite journaling)
      try {
        await db.execute('PRAGMA journal_mode = DELETE');
        _logger.d('DELETE mode enabled as fallback');
      } catch (fallbackError) {
        _logger.e('Failed to set journal mode: $fallbackError');
        // Continue anyway - database will use default journal mode
      }
    }

    // Set cache size to 10MB for better performance
    await db.execute('PRAGMA cache_size = -10000');

    // Set synchronous mode to NORMAL for balance between safety and speed
    // NORMAL is safe for most use cases and much faster than FULL
    await db.execute('PRAGMA synchronous = NORMAL');

    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');

    _logger.d('Database configuration complete');
  }

  /// Create database tables with proper indexing
  Future<void> _onCreate(Database db, int version) async {
    _logger.d('Creating chat database tables...');

    // Conversations table - cached conversation metadata
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        participant_ids TEXT NOT NULL,
        name TEXT,
        description TEXT,
        image_url TEXT,
        last_message_id TEXT,
        last_message_at INTEGER,
        unread_count INTEGER DEFAULT 0,
        settings TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Messages table - optimized for pagination and search
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_username TEXT,
        sender_avatar TEXT,
        type TEXT NOT NULL,
        content TEXT,
        media_urls TEXT,
        metadata TEXT,
        status TEXT NOT NULL,
        reactions TEXT,
        reply_to_id TEXT,
        temp_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Pagination metadata table - track loading states
    await db.execute('''
      CREATE TABLE pagination_metadata (
        conversation_id TEXT PRIMARY KEY,
        oldest_message_id TEXT,
        has_more_messages INTEGER DEFAULT 1,
        last_sync_at INTEGER,
        total_messages_count INTEGER DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for optimal query performance
    await _createIndexes(db);

    _logger.d('Chat database tables created successfully');
  }

  /// Create performance-optimized indexes
  Future<void> _createIndexes(Database db) async {
    _logger.d('Creating database indexes...');

    // Messages indexes for pagination and real-time queries
    await db.execute('''
      CREATE INDEX idx_messages_conversation_created 
      ON messages (conversation_id, created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_sender 
      ON messages (sender_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_temp_id 
      ON messages (temp_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_status 
      ON messages (status)
    ''');

    // Conversations indexes
    await db.execute('''
      CREATE INDEX idx_conversations_updated 
      ON conversations (updated_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_conversations_participant 
      ON conversations (participant_ids)
    ''');

    _logger.d('Database indexes created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.d('Upgrading database from version $oldVersion to $newVersion');

    // Migration to version 2: Add outbox table for offline message sending
    if (oldVersion < 2) {
      _logger.d('Adding message_outbox table for offline send retry...');

      // Outbox table for queuing messages when offline
      await db.execute('''
        CREATE TABLE IF NOT EXISTS message_outbox (
          temp_id TEXT PRIMARY KEY,
          conversation_id TEXT NOT NULL,
          content TEXT NOT NULL,
          type TEXT DEFAULT 'text',
          media_local_path TEXT,
          created_at INTEGER NOT NULL,
          retry_count INTEGER DEFAULT 0,
          last_error TEXT,
          last_retry_at INTEGER,
          FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
        )
      ''');

      // Index for efficient outbox queries
      await db.execute('''
        CREATE INDEX idx_outbox_conversation
        ON message_outbox(conversation_id)
      ''');

      // Index for retry processing
      await db.execute('''
        CREATE INDEX idx_outbox_retry
        ON message_outbox(retry_count, created_at)
      ''');

      _logger.d('Message outbox table created successfully');
    }

    // Migration to version 3: Add cache metadata table for TTL tracking
    if (oldVersion < 3) {
      _logger.d('Adding cache_metadata table for cache TTL tracking...');
      await CacheTTLService.createCacheMetadataTable(db);
      _logger.d('Cache metadata table created successfully');
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.d('Chat database closed');
    }
  }

  /// Clear all data (for debugging/testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('pagination_metadata');
    await db.delete('message_outbox');
    await db.delete('cache_metadata');
    _logger.d('All chat data cleared');
  }

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    final db = await database;

    final conversationsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM conversations'),
        ) ??
        0;

    final messagesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM messages'),
        ) ??
        0;

    final outboxCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM message_outbox'),
        ) ??
        0;

    final cacheCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cache_metadata'),
        ) ??
        0;

    return {
      'conversations': conversationsCount,
      'messages': messagesCount,
      'outbox_pending': outboxCount,
      'cached_items': cacheCount,
    };
  }

  /// Perform database maintenance (VACUUM, ANALYZE, WAL checkpoint)
  /// Should be run periodically (e.g., weekly) to optimize performance
  Future<void> performMaintenance() async {
    try {
      final db = await database;

      _logger.d('Starting database maintenance...');

      // Checkpoint WAL file (merge WAL into main database)
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      _logger.d('WAL checkpoint completed');

      // Run VACUUM to reclaim unused space and defragment
      await db.execute('VACUUM');
      _logger.d('VACUUM completed');

      // Run ANALYZE to update query planner statistics
      await db.execute('ANALYZE');
      _logger.d('ANALYZE completed');

      _logger.i('Database maintenance completed successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Database maintenance failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get detailed database information for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;

      // Get journal mode
      final journalModeResult = await db.rawQuery('PRAGMA journal_mode');
      final journalMode = journalModeResult.first.values.first;

      // Get page count and size
      final pageCountResult = await db.rawQuery('PRAGMA page_count');
      final pageCount = pageCountResult.first.values.first as int;

      final pageSizeResult = await db.rawQuery('PRAGMA page_size');
      final pageSize = pageSizeResult.first.values.first as int;

      final dbSizeMB = (pageCount * pageSize) / (1024 * 1024);

      // Get cache size
      final cacheSizeResult = await db.rawQuery('PRAGMA cache_size');
      final cacheSize = cacheSizeResult.first.values.first;

      return {
        'journalMode': journalMode,
        'dbSizeMB': dbSizeMB.toStringAsFixed(2),
        'pageCount': pageCount,
        'pageSize': pageSize,
        'cacheSize': cacheSize,
      };
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get database info',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }
}
