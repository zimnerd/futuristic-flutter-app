import 'package:flutter/material.dart';
import '../services/relationship_goals_service.dart';

/// Shared intent options used across the app
/// Fetches from backend API - single source of truth for relationship goals
class IntentOptions {
  // Map Material Design icon names to IconData
  static final Map<String, IconData> _iconMap = {
    'favorite': Icons.favorite,
    'sentiment_satisfied': Icons.sentiment_satisfied,
    'favorite_border': Icons.favorite_border,
    'people': Icons.people,
    'celebration': Icons.celebration,
    'handshake': Icons.handshake,
    'whatshot': Icons.whatshot,
    'event': Icons.event,
    'psychology': Icons.psychology,
    'explore': Icons.explore,
  };

  static final RelationshipGoalsService _goalService =
      RelationshipGoalsService.instance;

  /// Get all available intent options from backend
  /// Returns list with: id, slug, title, description, icon, color, displayOrder
  static Future<List<Map<String, dynamic>>> getAll({
    bool forceRefresh = false,
  }) async {
    final goals = await _goalService.getAvailableGoals(
      forceRefresh: forceRefresh,
    );

    // Convert icon names to IconData objects
    return goals.map((goal) {
      final iconName = goal['icon'] as String? ?? 'explore';
      return {...goal, 'iconData': _iconMap[iconName] ?? Icons.explore};
    }).toList();
  }

  /// Get option by slug/ID
  static Future<Map<String, dynamic>?> getById(String id) async {
    final goals = await getAll();
    try {
      return goals.firstWhere(
        (option) => option['slug'] == id || option['id'] == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all option IDs/slugs
  static Future<List<String>> getAllIds() async {
    final goals = await getAll();
    return goals.map((option) => option['slug'] as String).toList();
  }

  /// Get option title by ID
  static Future<String?> getTitleById(String id) async {
    final option = await getById(id);
    return option?['title'] as String?;
  }

  /// Get option description by ID
  static Future<String?> getDescriptionById(String id) async {
    final option = await getById(id);
    return option?['description'] as String?;
  }

  /// Get option icon by ID
  static Future<IconData?> getIconById(String id) async {
    final option = await getById(id);
    return option?['iconData'] as IconData?;
  }

  /// Get option color by ID (converts hex string to Color)
  static Future<Color?> getColorById(String id) async {
    final option = await getById(id);
    if (option == null) return null;

    final colorHex = option['color'] as String? ?? '#7E57C2';
    return _parseColorFromHex(colorHex);
  }

  /// Parse color from hex string
  static Color _parseColorFromHex(String hexString) {
    try {
      final hex = hexString.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF7E57C2); // Fallback color
    }
  }

  /// Clear cached goals (useful when logging out)
  static void clearCache() {
    _goalService.clearCache();
  }
}
