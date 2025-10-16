import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../database/chat_database.dart';

/// Service for managing cache TTL (Time-To-Live) metadata
/// Tracks when cached items should be refreshed or invalidated
class CacheTTLService {
  static final CacheTTLService _instance = CacheTTLService._internal();
  factory CacheTTLService() => _instance;
  CacheTTLService._internal();

  static final Logger _logger = Logger();

  // Cache TTL durations (configurable per content type)
  static const Duration profileImageTTL = Duration(days: 7);
  static const Duration messageImageTTL = Duration(days: 30);
  static const Duration thumbnailTTL = Duration(days: 14);
  static const Duration eventImageTTL = Duration(days: 3);
  static const Duration defaultTTL = Duration(days: 7);

  /// Get database instance
  Future<Database> get _db async => await ChatDatabase.instance.database;

  /// Initialize cache metadata table (called during database setup)
  static Future<void> createCacheMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_metadata (
        cache_key TEXT PRIMARY KEY,
        cache_type TEXT NOT NULL,
        url TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        last_accessed_at INTEGER NOT NULL,
        access_count INTEGER DEFAULT 0,
        size_bytes INTEGER DEFAULT 0
      )
    ''');

    // Index for efficient expiration queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_expires
      ON cache_metadata(expires_at)
    ''');

    // Index for cleanup by access time
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_access
      ON cache_metadata(last_accessed_at)
    ''');

    _logger.d('Cache metadata table created successfully');
  }

  /// Record a cached item with TTL
  Future<void> recordCachedItem({
    required String cacheKey,
    required String cacheType,
    required String url,
    Duration? ttl,
    int? sizeBytes,
  }) async {
    try {
      final db = await _db;
      final now = DateTime.now();
      final ttlDuration = ttl ?? _getTTLForType(cacheType);
      final expiresAt = now.add(ttlDuration);

      await db.insert(
        'cache_metadata',
        {
          'cache_key': cacheKey,
          'cache_type': cacheType,
          'url': url,
          'cached_at': now.millisecondsSinceEpoch,
          'expires_at': expiresAt.millisecondsSinceEpoch,
          'last_accessed_at': now.millisecondsSinceEpoch,
          'access_count': 1,
          'size_bytes': sizeBytes ?? 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Recorded cache item: $cacheKey ($cacheType) - expires ${expiresAt.toIso8601String()}');
    } catch (e, stackTrace) {
      _logger.e('Error recording cached item', error: e, stackTrace: stackTrace);
    }
  }

  /// Update last accessed time and increment access count
  Future<void> recordAccess(String cacheKey) async {
    try {
      final db = await _db;
      await db.rawUpdate(
        '''UPDATE cache_metadata
           SET last_accessed_at = ?,
               access_count = access_count + 1
           WHERE cache_key = ?''',
        [DateTime.now().millisecondsSinceEpoch, cacheKey],
      );
    } catch (e, stackTrace) {
      _logger.e('Error recording cache access', error: e, stackTrace: stackTrace);
    }
  }

  /// Check if cache item is expired
  Future<bool> isCacheExpired(String cacheKey) async {
    try {
      final db = await _db;
      final result = await db.query(
        'cache_metadata',
        columns: ['expires_at'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );

      if (result.isEmpty) {
        return true; // Not in cache metadata = expired
      }

      final expiresAt = result.first['expires_at'] as int;
      final isExpired = DateTime.now().millisecondsSinceEpoch > expiresAt;

      return isExpired;
    } catch (e, stackTrace) {
      _logger.e('Error checking cache expiration', error: e, stackTrace: stackTrace);
      return true; // On error, treat as expired
    }
  }

  /// Get all expired cache items
  Future<List<Map<String, dynamic>>> getExpiredCacheItems() async {
    try {
      final db = await _db;
      final result = await db.query(
        'cache_metadata',
        where: 'expires_at < ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch],
        orderBy: 'expires_at ASC',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.e('Error getting expired cache items', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Remove expired cache metadata
  Future<int> removeExpiredMetadata() async {
    try {
      final db = await _db;
      final deletedCount = await db.delete(
        'cache_metadata',
        where: 'expires_at < ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch],
      );

      if (deletedCount > 0) {
        _logger.d('Removed $deletedCount expired cache metadata entries');
      }

      return deletedCount;
    } catch (e, stackTrace) {
      _logger.e('Error removing expired metadata', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Remove least recently used cache items (LRU eviction)
  Future<List<String>> getLRUCacheKeys(int limit) async {
    try {
      final db = await _db;
      final result = await db.query(
        'cache_metadata',
        columns: ['cache_key'],
        orderBy: 'last_accessed_at ASC',
        limit: limit,
      );

      return result.map((row) => row['cache_key'] as String).toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting LRU cache keys', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Remove cache metadata for specific keys
  Future<void> removeCacheMetadata(List<String> cacheKeys) async {
    if (cacheKeys.isEmpty) return;

    try {
      final db = await _db;
      final batch = db.batch();

      for (final key in cacheKeys) {
        batch.delete('cache_metadata', where: 'cache_key = ?', whereArgs: [key]);
      }

      await batch.commit(noResult: true);
      _logger.d('Removed ${cacheKeys.length} cache metadata entries');
    } catch (e, stackTrace) {
      _logger.e('Error removing cache metadata', error: e, stackTrace: stackTrace);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await _db;

      // Total cached items
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_metadata');
      final total = totalResult.first['count'] as int;

      // Expired items
      final expiredResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cache_metadata WHERE expires_at < ?',
        [DateTime.now().millisecondsSinceEpoch],
      );
      final expired = expiredResult.first['count'] as int;

      // Total cache size
      final sizeResult = await db.rawQuery('SELECT SUM(size_bytes) as total_size FROM cache_metadata');
      final totalSize = (sizeResult.first['total_size'] as int?) ?? 0;

      // Most accessed items
      final topAccessedResult = await db.query(
        'cache_metadata',
        columns: ['cache_type', 'access_count'],
        orderBy: 'access_count DESC',
        limit: 5,
      );

      // Stats by type
      final typeStatsResult = await db.rawQuery('''
        SELECT cache_type, COUNT(*) as count, SUM(size_bytes) as size
        FROM cache_metadata
        GROUP BY cache_type
      ''');

      return {
        'total_items': total,
        'expired_items': expired,
        'valid_items': total - expired,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'top_accessed': topAccessedResult,
        'stats_by_type': typeStatsResult,
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting cache stats', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Clear all cache metadata
  Future<void> clearAllCacheMetadata() async {
    try {
      final db = await _db;
      await db.delete('cache_metadata');
      _logger.d('Cleared all cache metadata');
    } catch (e, stackTrace) {
      _logger.e('Error clearing cache metadata', error: e, stackTrace: stackTrace);
    }
  }

  /// Extend TTL for frequently accessed items
  Future<void> extendTTLForFrequentItems({
    int accessThreshold = 10,
    Duration extension = const Duration(days: 7),
  }) async {
    try {
      final db = await _db;
      final now = DateTime.now();
      final newExpiresAt = now.add(extension);

      final updatedCount = await db.rawUpdate(
        '''UPDATE cache_metadata
           SET expires_at = ?
           WHERE access_count >= ? AND expires_at < ?''',
        [
          newExpiresAt.millisecondsSinceEpoch,
          accessThreshold,
          now.millisecondsSinceEpoch,
        ],
      );

      if (updatedCount > 0) {
        _logger.d('Extended TTL for $updatedCount frequently accessed items');
      }
    } catch (e, stackTrace) {
      _logger.e('Error extending TTL', error: e, stackTrace: stackTrace);
    }
  }

  /// Get TTL duration based on cache type
  Duration _getTTLForType(String cacheType) {
    switch (cacheType.toLowerCase()) {
      case 'profile_image':
        return profileImageTTL;
      case 'message_image':
        return messageImageTTL;
      case 'thumbnail':
        return thumbnailTTL;
      case 'event_image':
        return eventImageTTL;
      default:
        return defaultTTL;
    }
  }
}
