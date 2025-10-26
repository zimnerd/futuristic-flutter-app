import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import 'app_router.dart';

/// Extension methods for easy navigation to advanced features
extension AppNavigationExtension on BuildContext {
  // Core navigation
  void goToHome() => go(AppRoutes.home);
  void goToMatches() => go(AppRoutes.matches);
  void goToMessages() => go(AppRoutes.messages);
  void goToProfile() => go(AppRoutes.profile);

  // Discovery and matching
  void goToDiscovery() => go(AppRoutes.discovery);
  void goToFilters() => go(AppRoutes.filters);
  void goToAdvancedFeatures() => go(AppRoutes.advancedFeatures);

  // Advanced features
  void goToVirtualGifts({String? recipientId, String? recipientName}) {
    final uri = Uri(
      path: AppRoutes.virtualGifts,
      queryParameters: {
        if (recipientId != null) 'recipientId': recipientId,
        if (recipientName != null) 'recipientName': recipientName,
      },
    );
    go(uri.toString());
  }

  void goToPremium() => go(AppRoutes.premium);

  void goToSafety() => go(AppRoutes.safety);

  void goToAiCompanion() => go(AppRoutes.aiCompanion);

  void goToSpeedDating() => go(AppRoutes.speedDating);

  void goToLiveStreaming() => go(AppRoutes.liveStreaming);

  void goToDatePlanning() => go(AppRoutes.datePlanning);

  void goToVoiceMessages() => go(AppRoutes.voiceMessages);

  void goToProfileCreation() => go(AppRoutes.profileCreation);

  void goToVideoCall(String callId) => go('/video-call/$callId');

  // Settings and management
  void goToSettings() => go(AppRoutes.settings);
  void goToSubscription() => go(AppRoutes.subscription);

  // Auth navigation
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToWelcome() => go(AppRoutes.welcome);

  // Navigation with bottom sheet alternatives
  void showVirtualGiftsBottomSheet({
    String? recipientId,
    String? recipientName,
  }) {
    showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: context.onSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: context.outlineColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Virtual Gifts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recipientName != null
                          ? 'Send a gift to $recipientName'
                          : 'Choose a virtual gift to send',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        goToVirtualGifts(
                          recipientId: recipientId,
                          recipientName: recipientName,
                        );
                      },
                      child: Text('Open Virtual Gifts'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick action navigation helpers
  void navigateToFeature(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'discovery':
      case 'swipe':
      case 'discover':
        goToDiscovery();
        break;
      case 'gifts':
      case 'virtual gifts':
      case 'virtualgifts':
        goToVirtualGifts();
        break;
      case 'premium':
      case 'subscription':
        goToPremium();
        break;
      case 'safety':
      case 'security':
        goToSafety();
        break;
      case 'ai':
      case 'aicompanion':
      case 'ai companion':
        goToAiCompanion();
        break;
      case 'speed dating':
      case 'speeddating':
        goToSpeedDating();
        break;
      case 'live':
      case 'streaming':
      case 'livestreaming':
      case 'live streaming':
        goToLiveStreaming();
        break;
      case 'dates':
      case 'dating':
      case 'dateplanning':
      case 'date planning':
        goToDatePlanning();
        break;
      case 'voice':
      case 'voicemessages':
      case 'voice messages':
        goToVoiceMessages();
        break;
      case 'settings':
        goToSettings();
        break;
      case 'profile':
        goToProfile();
        break;
      case 'matches':
        goToMatches();
        break;
      case 'messages':
      case 'chat':
        goToMessages();
        break;
      case 'home':
      default:
        goToHome();
        break;
    }
  }
}

/// Helper class for navigation constants and utilities
class NavigationHelper {
  NavigationHelper._();

  /// Common navigation destinations with metadata
  static const Map<String, Map<String, dynamic>> destinations = {
    'home': {
      'route': AppRoutes.home,
      'title': 'Home',
      'icon': Icons.home,
      'description': 'Main dashboard',
    },
    'discovery': {
      'route': AppRoutes.discovery,
      'title': 'Discover',
      'icon': Icons.explore,
      'description': 'Find new matches',
    },
    'matches': {
      'route': AppRoutes.matches,
      'title': 'Matches',
      'icon': Icons.favorite,
      'description': 'Your matches',
    },
    'messages': {
      'route': AppRoutes.messages,
      'title': 'Messages',
      'icon': Icons.chat_bubble,
      'description': 'Chat with matches',
    },
    'virtualGifts': {
      'route': AppRoutes.virtualGifts,
      'title': 'Virtual Gifts',
      'icon': Icons.card_giftcard,
      'description': 'Send and receive gifts',
    },
    'premium': {
      'route': AppRoutes.premium,
      'title': 'Premium',
      'icon': Icons.star,
      'description': 'Upgrade your experience',
    },
    'safety': {
      'route': AppRoutes.safety,
      'title': 'Safety',
      'icon': Icons.shield,
      'description': 'Safety and security tools',
    },
    'aiCompanion': {
      'route': AppRoutes.aiCompanion,
      'title': 'AI Companion',
      'icon': Icons.psychology,
      'description': 'AI-powered dating assistant',
    },
    'speedDating': {
      'route': AppRoutes.speedDating,
      'title': 'Speed Dating',
      'icon': Icons.timer,
      'description': 'Quick connections',
    },
    'liveStreaming': {
      'route': AppRoutes.liveStreaming,
      'title': 'Live Streaming',
      'icon': Icons.videocam,
      'description': 'Live video experiences',
    },
    'datePlanning': {
      'route': AppRoutes.datePlanning,
      'title': 'Date Planning',
      'icon': Icons.event,
      'description': 'Plan amazing dates',
    },
    'voiceMessages': {
      'route': AppRoutes.voiceMessages,
      'title': 'Voice Messages',
      'icon': Icons.mic,
      'description': 'Voice chat features',
    },
  };

  /// Get destination metadata by key
  static Map<String, dynamic>? getDestination(String key) {
    return destinations[key];
  }

  /// Get all premium features
  static List<String> get premiumFeatures => [
    'virtualGifts',
    'premium',
    'aiCompanion',
    'speedDating',
    'liveStreaming',
    'datePlanning',
  ];

  /// Get core features (available to all users)
  static List<String> get coreFeatures => [
    'home',
    'discovery',
    'matches',
    'messages',
    'safety',
    'voiceMessages',
  ];

  /// Check if a feature requires premium
  static bool isPremiumFeature(String feature) {
    return premiumFeatures.contains(feature);
  }
}
