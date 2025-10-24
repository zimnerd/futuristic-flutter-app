import 'package:logger/logger.dart';
import '../network/api_client.dart';

/// Service for managing relationship goals
/// Fetches metadata from backend API - single source of truth
class RelationshipGoalsService {
  static RelationshipGoalsService? _instance;
  static RelationshipGoalsService get instance =>
      _instance ??= RelationshipGoalsService._();

  RelationshipGoalsService._();

  final ApiClient _apiClient = ApiClient.instance;
  final Logger _logger = Logger();

  List<Map<String, dynamic>>? _cachedGoals;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Get all available relationship goals from backend
  /// Returns list with: id, slug, title, description, icon, color, displayOrder
  Future<List<Map<String, dynamic>>> getAvailableGoals(
      {bool forceRefresh = false}) async {
    try {
      // Check cache
      if (!forceRefresh &&
          _cachedGoals != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
        _logger.i('✅ Using cached relationship goals');
        return _cachedGoals!;
      }

      _logger.i('📥 Fetching relationship goals from backend...');
      final response = await _apiClient.get(
        '/users/relationship-goals/options',
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle both direct array and nested response
        final data = response.data is List
            ? response.data
            : response.data['data'] ?? response.data['goals'] ?? [];

        _cachedGoals = (data as List).cast<Map<String, dynamic>>();
        _lastFetchTime = DateTime.now();

        _logger.i('✅ Fetched ${_cachedGoals!.length} relationship goals');

        // Log available goals
        for (final goal in _cachedGoals!) {
          _logger.d(
              '  - ${goal['slug']}: ${goal['title']} (icon: ${goal['icon']}, order: ${goal['displayOrder']})');
        }

        return _cachedGoals!;
      } else {
        throw Exception('Failed to fetch relationship goals');
      }
    } catch (e) {
      _logger.e('Error fetching relationship goals: $e');
      // Return empty list on error, don't crash
      return [];
    }
  }

  /// Get goal by slug/id
  Future<Map<String, dynamic>?> getGoalBySlug(String slug) async {
    final goals = await getAvailableGoals();
    try {
      return goals.firstWhere(
        (goal) => goal['slug'] == slug || goal['id'] == slug,
      );
    } catch (e) {
      _logger.w('Goal not found: $slug');
      return null;
    }
  }

  /// Get goal title by slug/id
  Future<String?> getTitleBySlug(String slug) async {
    final goal = await getGoalBySlug(slug);
    return goal?['title'] as String?;
  }

  /// Get goal description by slug/id
  Future<String?> getDescriptionBySlug(String slug) async {
    final goal = await getGoalBySlug(slug);
    return goal?['description'] as String?;
  }

  /// Get goal icon by slug/id
  Future<String?> getIconBySlug(String slug) async {
    final goal = await getGoalBySlug(slug);
    return goal?['icon'] as String?;
  }

  /// Get goal color by slug/id
  Future<String?> getColorBySlug(String slug) async {
    final goal = await getGoalBySlug(slug);
    return goal?['color'] as String?;
  }

  /// Get all goal slugs in display order
  Future<List<String>> getGoalSlugs() async {
    final goals = await getAvailableGoals();
    final sorted = [...goals];
    sorted.sort((a, b) =>
        (a['displayOrder'] as int).compareTo(b['displayOrder'] as int));
    return sorted.map((g) => g['slug'] as String).toList();
  }

  /// Clear cache
  void clearCache() {
    _cachedGoals = null;
    _lastFetchTime = null;
  }
}
