import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/event.dart';

/// Local SQLite database for events and categories
/// Provides offline caching and faster loading
class EventsDatabase {
  static const String _databaseName = 'pulse_events.db';
  static const int _databaseVersion = 2; // Incremented for event_count column
  
  static Database? _database;
  static final Logger _logger = Logger();

  /// Singleton instance
  static final EventsDatabase instance = EventsDatabase._internal();
  EventsDatabase._internal();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with optimized schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    _logger.d('Initializing events database at: $path');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.d('Creating events database tables...');
    
    // Event categories table - cached categories
    await db.execute('''
      CREATE TABLE event_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        description TEXT,
        icon TEXT,
        color TEXT,
        event_count INTEGER DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        order_index INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Events cache table (optional for future use)
    await db.execute('''
      CREATE TABLE cached_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        start_time TEXT,
        max_attendees INTEGER,
        current_attendees INTEGER,
        creator_id TEXT,
        category_id TEXT,
        category_slug TEXT,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES event_categories (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_categories_slug ON event_categories (slug)');
    await db.execute('CREATE INDEX idx_categories_active ON event_categories (is_active)');
    await db.execute('CREATE INDEX idx_events_category ON cached_events (category_slug)');
    
    _logger.d('Events database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.d('Upgrading events database from v$oldVersion to v$newVersion');
    
    // Upgrade from v1 to v2: Add event_count column
    if (oldVersion == 1 && newVersion >= 2) {
      await db.execute(
        'ALTER TABLE event_categories ADD COLUMN event_count INTEGER DEFAULT 0',
      );
      _logger.d('Added event_count column to event_categories table');
    }
  }

  /// Cache event categories locally
  Future<void> cacheCategories(List<EventCategory> categories) async {
    final db = await database;
    final batch = db.batch();
    
    // Clear existing categories
    batch.delete('event_categories');
    
    // Insert new categories
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final category in categories) {
      batch.insert('event_categories', {
        'id': category.id,
        'name': category.name,
        'slug': category.slug,
        'description': category.description,
        'icon': category.icon,
        'color': category.color,
        'event_count':
            category.eventCount, // Store event count for offline access
        'is_active': 1, // All API categories are active
        'order_index': 0, // Default order, can be customized later
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
        'cached_at': now,
      });
    }
    
    await batch.commit();
    _logger.d('Cached ${categories.length} event categories');
  }

  /// Get cached event categories
  Future<List<EventCategory>> getCachedCategories({Duration? maxAge}) async {
    final db = await database;
    
    // Build query with optional age filter
    String whereClause = 'is_active = 1';
    List<Object?> whereArgs = [];
    
    if (maxAge != null) {
      final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
      whereClause += ' AND cached_at > ?';
      whereArgs.add(cutoff);
    }
    
    final List<Map<String, Object?>> maps = await db.query(
      'event_categories',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'order_index ASC, name ASC',
    );

    return maps.map((map) => EventCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
            eventCount:
                (map['event_count'] as int?) ?? 0, // Read cached event count
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  /// Check if categories cache is fresh
  Future<bool> isCategoriesCacheFresh({Duration maxAge = const Duration(hours: 1)}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    
    final result = await db.query(
      'event_categories',
      where: 'cached_at > ?',
      whereArgs: [cutoff],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('event_categories');
    await db.delete('cached_events');
    _logger.d('Cleared events cache');
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final db = await database;
    
    final categoriesCount = (await db.query('event_categories')).length;
    final eventsCount = (await db.query('cached_events')).length;
    
    return {
      'categories': categoriesCount,
      'events': eventsCount,
    };
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _logger.d('Events database closed');
    }
  }
}