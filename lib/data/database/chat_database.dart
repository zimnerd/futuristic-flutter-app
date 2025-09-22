import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

/// Local SQLite database for chat messages and conversations
/// Optimized for WhatsApp-style messaging with pagination and offline support
class ChatDatabase {
  static const String _databaseName = 'pulse_chat.db';
  static const int _databaseVersion = 1;
  
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
    );
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
    
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE messages ADD COLUMN new_field TEXT');
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
    _logger.d('All chat data cleared');
  }

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    final db = await database;
    
    final conversationsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM conversations'),
    ) ?? 0;
    
    final messagesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM messages'),
    ) ?? 0;
    
    return {
      'conversations': conversationsCount,
      'messages': messagesCount,
    };
  }
}