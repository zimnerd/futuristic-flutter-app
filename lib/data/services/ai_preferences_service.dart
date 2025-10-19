import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_preferences.dart';

/// Service for managing AI preferences and settings
class AiPreferencesService {
  static const String _preferencesKey = 'ai_preferences';
  static AiPreferences? _cachedPreferences;

  /// Get current AI preferences
  Future<AiPreferences> getAiPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = prefs.getString(_preferencesKey);

    if (preferencesJson != null) {
      final Map<String, dynamic> json = jsonDecode(preferencesJson);
      _cachedPreferences = AiPreferences.fromJson(json);
      return _cachedPreferences!;
    }

    // Return default preferences if none exist
    _cachedPreferences = const AiPreferences();
    return _cachedPreferences!;
  }

  /// Update AI preferences
  Future<void> updateAiPreferences(AiPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = jsonEncode(preferences.toJson());

    await prefs.setString(_preferencesKey, preferencesJson);
    _cachedPreferences = preferences;
  }

  /// Enable/disable main AI functionality
  Future<void> setAiEnabled(bool enabled) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(
      isAiEnabled: enabled,
    );
    await updateAiPreferences(updatedPreferences);
  }

  /// Update conversation settings
  Future<void> updateConversationSettings(
    AiConversationSettings settings,
  ) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(
      conversations: settings,
    );
    await updateAiPreferences(updatedPreferences);
  }

  /// Update companion settings
  Future<void> updateCompanionSettings(AiCompanionSettings settings) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(companion: settings);
    await updateAiPreferences(updatedPreferences);
  }

  /// Update profile settings
  Future<void> updateProfileSettings(AiProfileSettings settings) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(profile: settings);
    await updateAiPreferences(updatedPreferences);
  }

  /// Update matching settings
  Future<void> updateMatchingSettings(AiMatchingSettings settings) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(matching: settings);
    await updateAiPreferences(updatedPreferences);
  }

  /// Update icebreaker settings
  Future<void> updateIcebreakerSettings(AiIcebreakerSettings settings) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(
      icebreakers: settings,
    );
    await updateAiPreferences(updatedPreferences);
  }

  /// Update general settings
  Future<void> updateGeneralSettings(AiGeneralSettings settings) async {
    final currentPreferences = await getAiPreferences();
    final updatedPreferences = currentPreferences.copyWith(general: settings);
    await updateAiPreferences(updatedPreferences);
  }

  /// Check if a specific feature is enabled
  Future<bool> isFeatureEnabled(String feature) async {
    final preferences = await getAiPreferences();

    if (!preferences.isAiEnabled) {
      return false;
    }

    switch (feature) {
      case 'smart_replies':
        return preferences.conversations.smartRepliesEnabled;
      case 'custom_reply':
        return preferences.conversations.customReplyEnabled;
      case 'auto_suggestions':
        return preferences.conversations.autoSuggestionsEnabled;
      case 'companion_chat':
        return preferences.companion.companionChatEnabled;
      case 'companion_advice':
        return preferences.companion.companionAdviceEnabled;
      case 'profile_optimization':
        return preferences.profile.profileOptimizationEnabled;
      case 'bio_suggestions':
        return preferences.profile.bioSuggestionsEnabled;
      case 'smart_matching':
        return preferences.matching.smartMatchingEnabled;
      case 'icebreaker_suggestions':
        return preferences.icebreakers.icebreakerSuggestionsEnabled;
      case 'personalized_icebreakers':
        return preferences.icebreakers.personalizedIcebreakersEnabled;
      default:
        return false;
    }
  }

  /// Get conversation preferences for current settings
  Future<Map<String, dynamic>> getConversationPreferences() async {
    final preferences = await getAiPreferences();
    return {
      'maxSuggestions': preferences.conversations.maxSuggestions,
      'replyTone': preferences.conversations.replyTone,
      'adaptToUserStyle': preferences.conversations.adaptToUserStyle,
      'contextAware': preferences.conversations.contextAwareReplies,
    };
  }

  /// Get icebreaker preferences for current settings
  Future<Map<String, dynamic>> getIcebreakerPreferences() async {
    final preferences = await getAiPreferences();
    return {
      'style': preferences.icebreakers.icebreakerStyle,
      'maxIcebreakers': preferences.icebreakers.maxIcebreakers,
      'personalized': preferences.icebreakers.personalizedIcebreakersEnabled,
      'contextual': preferences.icebreakers.contextualIcebreakersEnabled,
    };
  }

  /// Get matching preferences for current settings
  Future<Map<String, dynamic>> getMatchingPreferences() async {
    final preferences = await getAiPreferences();
    return {
      'threshold': preferences.matching.matchingThreshold,
      'personalityInsights': preferences.matching.personalityInsightsEnabled,
      'behaviorAnalysis': preferences.matching.behaviorAnalysisEnabled,
      'compatibilityAnalysis':
          preferences.matching.compatibilityAnalysisEnabled,
    };
  }

  /// Clear all AI preferences (reset to defaults)
  Future<void> resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferencesKey);
    _cachedPreferences = const AiPreferences();
  }

  /// Check if user has gone through AI onboarding
  Future<bool> hasCompletedAiOnboarding() async {
    final preferences = await getAiPreferences();
    return preferences.general.dataCollectionConsent;
  }

  /// Mark AI onboarding as completed
  Future<void> completeAiOnboarding() async {
    final preferences = await getAiPreferences();
    final updatedGeneral = preferences.general.copyWith(
      dataCollectionConsent: true,
    );
    await updateGeneralSettings(updatedGeneral);
  }

  /// Get privacy-safe preferences for analytics
  Future<Map<String, dynamic>> getAnonymousPreferences() async {
    final preferences = await getAiPreferences();

    if (!preferences.general.shareAnonymousUsage) {
      return {};
    }

    return {
      'ai_enabled': preferences.isAiEnabled,
      'conversations_enabled': preferences.conversations.smartRepliesEnabled,
      'companion_enabled': preferences.companion.companionChatEnabled,
      'profile_optimization_enabled':
          preferences.profile.profileOptimizationEnabled,
      'matching_enabled': preferences.matching.smartMatchingEnabled,
      'icebreakers_enabled':
          preferences.icebreakers.icebreakerSuggestionsEnabled,
      'privacy_level': preferences.general.privacyLevel,
    };
  }
}
