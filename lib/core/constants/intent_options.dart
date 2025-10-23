import 'package:flutter/material.dart';

/// Shared intent options used across the app
/// Single source of truth for intent/relationship goals selection
class IntentOptions {
  /// All available intent options
  static const List<Map<String, dynamic>> all = [
    {
      'id': 'dating',
      'title': 'Dating',
      'description': 'Find romantic connections and meaningful relationships',
      'icon': Icons.favorite,
      'color': Color(0xFFFF6B9D),
    },
    {
      'id': 'friendship',
      'title': 'Friendship',
      'description': 'Make new friends and expand your social circle',
      'icon': Icons.people,
      'color': Color(0xFF4ECDC4),
    },
    {
      'id': 'events',
      'title': 'Events & Activities',
      'description': 'Find people to attend events and activities with',
      'icon': Icons.event,
      'color': Color(0xFFFFA726),
    },
    {
      'id': 'companion',
      'title': 'AI Companion',
      'description': 'Chat with AI for advice, support, and conversation',
      'icon': Icons.psychology,
      'color': Color(0xFF9C27B0),
    },
    {
      'id': 'support',
      'title': 'Emotional Support',
      'description': 'Connect with understanding people and find support',
      'icon': Icons.favorite_border,
      'color': Color(0xFF66BB6A),
    },
    {
      'id': 'explore',
      'title': 'Explore Everything',
      'description': 'I want to explore all features and decide later',
      'icon': Icons.explore,
      'color': Color(0xFF7E57C2),
    },
  ];

  /// Get option by ID
  static Map<String, dynamic>? getById(String id) {
    try {
      return all.firstWhere((option) => option['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all option IDs
  static List<String> getAllIds() {
    return all.map((option) => option['id'] as String).toList();
  }

  /// Get option title by ID
  static String? getTitleById(String id) {
    final option = getById(id);
    return option?['title'] as String?;
  }

  /// Get option description by ID
  static String? getDescriptionById(String id) {
    final option = getById(id);
    return option?['description'] as String?;
  }

  /// Get option icon by ID
  static IconData? getIconById(String id) {
    final option = getById(id);
    return option?['icon'] as IconData?;
  }

  /// Get option color by ID
  static Color? getColorById(String id) {
    final option = getById(id);
    return option?['color'] as Color?;
  }
}
