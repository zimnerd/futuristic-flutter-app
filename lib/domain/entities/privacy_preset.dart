import 'package:flutter/material.dart';

/// Privacy preset levels for quick privacy configuration
enum PrivacyPresetLevel {
  public,
  balanced,
  private,
  stealth,
}

/// Privacy preset configuration
class PrivacyPreset {
  final PrivacyPresetLevel level;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> settings;

  const PrivacyPreset({
    required this.level,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.settings,
  });

  /// Get all available privacy presets
  static List<PrivacyPreset> get all => [
        public,
        balanced,
        private,
        stealth,
      ];

  /// Public preset - Maximum visibility
  static const PrivacyPreset public = PrivacyPreset(
    level: PrivacyPresetLevel.public,
    title: 'Public',
    description: 'Maximum visibility. Great for making new connections.',
    icon: Icons.public_rounded,
    color: Color(0xFF4CAF50), // Green
    settings: {
      'showAge': true,
      'showDistance': true,
      'showLastActive': true,
      'showOnlineStatus': true,
      'incognitoMode': false,
      'readReceipts': true,
      'whoCanMessageMe': 'everyone',
      'whoCanSeeMyProfile': 'everyone',
    },
  );

  /// Balanced preset - Moderate privacy
  static const PrivacyPreset balanced = PrivacyPreset(
    level: PrivacyPresetLevel.balanced,
    title: 'Balanced',
    description: 'Balance between visibility and privacy. Recommended.',
    icon: Icons.balance_rounded,
    color: Color(0xFF2196F3), // Blue
    settings: {
      'showAge': true,
      'showDistance': true,
      'showLastActive': false,
      'showOnlineStatus': true,
      'incognitoMode': false,
      'readReceipts': true,
      'whoCanMessageMe': 'everyone',
      'whoCanSeeMyProfile': 'everyone',
    },
  );

  /// Private preset - Limited visibility
  static const PrivacyPreset private = PrivacyPreset(
    level: PrivacyPresetLevel.private,
    title: 'Private',
    description: 'Limited visibility. Only matches can see most details.',
    icon: Icons.shield_rounded,
    color: Color(0xFFFF9800), // Orange
    settings: {
      'showAge': true,
      'showDistance': false,
      'showLastActive': false,
      'showOnlineStatus': false,
      'incognitoMode': false,
      'readReceipts': false,
      'whoCanMessageMe': 'matches',
      'whoCanSeeMyProfile': 'matches',
    },
  );

  /// Stealth preset - Minimum visibility
  static const PrivacyPreset stealth = PrivacyPreset(
    level: PrivacyPresetLevel.stealth,
    title: 'Stealth',
    description: 'Maximum privacy. Browse anonymously.',
    icon: Icons.visibility_off_rounded,
    color: Color(0xFF9E9E9E), // Grey
    settings: {
      'showAge': false,
      'showDistance': false,
      'showLastActive': false,
      'showOnlineStatus': false,
      'incognitoMode': true,
      'readReceipts': false,
      'whoCanMessageMe': 'matches',
      'whoCanSeeMyProfile': 'none',
    },
  );

  /// Detect which preset matches the given settings (if any)
  static PrivacyPresetLevel? detectPreset(Map<String, dynamic> settings) {
    for (final preset in all) {
      if (_settingsMatch(settings, preset.settings)) {
        return preset.level;
      }
    }
    return null; // Custom settings
  }

  /// Check if two settings maps match
  static bool _settingsMatch(
    Map<String, dynamic> settings1,
    Map<String, dynamic> settings2,
  ) {
    for (final key in settings2.keys) {
      if (settings1[key] != settings2[key]) {
        return false;
      }
    }
    return true;
  }

  /// Get preset by level
  static PrivacyPreset getByLevel(PrivacyPresetLevel level) {
    switch (level) {
      case PrivacyPresetLevel.public:
        return public;
      case PrivacyPresetLevel.balanced:
        return balanced;
      case PrivacyPresetLevel.private:
        return private;
      case PrivacyPresetLevel.stealth:
        return stealth;
    }
  }

  /// Get settings comparison for display
  static Map<String, Map<PrivacyPresetLevel, dynamic>> getComparison() {
    return {
      'showAge': {
        PrivacyPresetLevel.public: true,
        PrivacyPresetLevel.balanced: true,
        PrivacyPresetLevel.private: true,
        PrivacyPresetLevel.stealth: false,
      },
      'showDistance': {
        PrivacyPresetLevel.public: true,
        PrivacyPresetLevel.balanced: true,
        PrivacyPresetLevel.private: false,
        PrivacyPresetLevel.stealth: false,
      },
      'showLastActive': {
        PrivacyPresetLevel.public: true,
        PrivacyPresetLevel.balanced: false,
        PrivacyPresetLevel.private: false,
        PrivacyPresetLevel.stealth: false,
      },
      'showOnlineStatus': {
        PrivacyPresetLevel.public: true,
        PrivacyPresetLevel.balanced: true,
        PrivacyPresetLevel.private: false,
        PrivacyPresetLevel.stealth: false,
      },
      'readReceipts': {
        PrivacyPresetLevel.public: true,
        PrivacyPresetLevel.balanced: true,
        PrivacyPresetLevel.private: false,
        PrivacyPresetLevel.stealth: false,
      },
      'whoCanSeeMyProfile': {
        PrivacyPresetLevel.public: 'Everyone',
        PrivacyPresetLevel.balanced: 'Everyone',
        PrivacyPresetLevel.private: 'Matches',
        PrivacyPresetLevel.stealth: 'None',
      },
      'whoCanMessageMe': {
        PrivacyPresetLevel.public: 'Everyone',
        PrivacyPresetLevel.balanced: 'Everyone',
        PrivacyPresetLevel.private: 'Matches',
        PrivacyPresetLevel.stealth: 'Matches',
      },
      'incognitoMode': {
        PrivacyPresetLevel.public: false,
        PrivacyPresetLevel.balanced: false,
        PrivacyPresetLevel.private: false,
        PrivacyPresetLevel.stealth: true,
      },
    };
  }

  /// Get feature labels for UI display
  static Map<String, String> get featureLabels => {
        'showAge': 'Show Age',
        'showDistance': 'Show Distance',
        'showLastActive': 'Show Last Active',
        'showOnlineStatus': 'Show Online Status',
        'readReceipts': 'Read Receipts',
        'whoCanSeeMyProfile': 'Profile Visibility',
        'whoCanMessageMe': 'Who Can Message',
        'incognitoMode': 'Incognito Mode',
      };

  /// Get feature descriptions
  static Map<String, String> get featureDescriptions => {
        'showAge': 'Display your age on your profile',
        'showDistance': 'Show how far away you are',
        'showLastActive': 'Display when you were last online',
        'showOnlineStatus': 'Show when you\'re currently active',
        'readReceipts': 'Let others know when you\'ve read their messages',
        'whoCanSeeMyProfile': 'Control who can view your full profile',
        'whoCanMessageMe': 'Control who can send you messages',
        'incognitoMode': 'Browse profiles without appearing in discovery',
      };
}
