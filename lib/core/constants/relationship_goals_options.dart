import 'package:flutter/material.dart';
import '../services/relationship_goals_service.dart';

/// Relationship goals options used across the app
/// Fetches from backend API - single source of truth for relationship goals
class RelationshipGoalsOptions {
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

  /// Get all available relationship goals from backend
  /// Returns list with: slug, title, description, icon, color, displayOrder
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

  /// Get goal by slug/ID
  static Future<Map<String, dynamic>?> getBySlug(String slug) async {
    final goals = await getAll();
    try {
      return goals.firstWhere(
        (option) => option['slug'] == slug || option['id'] == slug,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all goal slugs
  static Future<List<String>> getAllSlugs() async {
    final goals = await getAll();
    return goals.map((option) => option['slug'] as String).toList();
  }

  /// Get goal title by slug
  static Future<String?> getTitleBySlug(String slug) async {
    final option = await getBySlug(slug);
    return option?['title'] as String?;
  }

  /// Get goal description by slug
  static Future<String?> getDescriptionBySlug(String slug) async {
    final option = await getBySlug(slug);
    return option?['description'] as String?;
  }

  /// Get goal icon by slug
  static Future<IconData?> getIconBySlug(String slug) async {
    final option = await getBySlug(slug);
    return option?['iconData'] as IconData?;
  }

  /// Get goal color by slug (converts hex string to Color)
  static Future<Color?> getColorBySlug(String slug) async {
    final option = await getBySlug(slug);
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
