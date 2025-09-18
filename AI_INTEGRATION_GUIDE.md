# AI Preferences Integration Guide

This guide shows how to integrate the AI preferences system into your Flutter app.

## Overview

The AI preferences system provides granular user control over AI features including:
- Smart conversations (auto-replies, suggestions)
- AI companion chat
- Profile optimization assistance
- Smart matching algorithms
- Icebreaker suggestions

## Files Created

### Models & Services
- `lib/data/models/ai_preferences.dart` - Preference data models
- `lib/data/services/ai_preferences_service.dart` - Service for managing preferences
- `lib/business_logic/blocs/ai_preferences_bloc.dart` - BLoC for state management

### UI Components
- `lib/presentation/screens/settings/ai_settings_screen.dart` - Main settings screen
- `lib/presentation/widgets/ai/ai_feature_card.dart` - Feature toggle cards
- `lib/presentation/widgets/ai/ai_onboarding_dialog.dart` - First-time setup
- `lib/presentation/widgets/common/loading_overlay.dart` - Loading states

### Examples
- `lib/presentation/screens/examples/ai_integration_example.dart` - Full demo app
- `lib/presentation/widgets/chat/ai_message_input.dart` - Chat integration example

## Integration Steps

### 1. Service Registration

The AI preferences service is already registered in `service_locator.dart`:

```dart
// Already done:
AiPreferencesService get aiPreferences {
  assert(_aiPreferencesService != null, 'AI Preferences service not initialized');
  return _aiPreferencesService!;
}
```

### 2. BLoC Integration

Add the AI preferences BLoC to your app's BLoC providers:

```dart
// In your main app or specific screens:
BlocProvider(
  create: (context) => AiPreferencesBloc(
    preferencesService: ServiceLocator.instance.aiPreferences,
  )..add(LoadAiPreferences()),
  child: YourScreen(),
)
```

### 3. Settings Screen Integration

Add the AI settings to your app's settings navigation:

```dart
// In your settings menu:
ListTile(
  leading: const Icon(Icons.psychology),
  title: const Text('AI Assistant'),
  subtitle: const Text('Manage AI features'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AiPreferencesBloc>(),
          child: const AiSettingsScreen(),
        ),
      ),
    );
  },
)
```

### 4. Feature Gating

Use the `AiFeatureWrapper` widget to conditionally show AI features:

```dart
// Only show AI features when enabled
AiFeatureWrapper(
  feature: 'smart_replies', // or other feature keys
  child: YourAiWidget(),
  fallback: YourRegularWidget(), // optional
)
```

### 5. Direct Preference Checks

Check preferences directly in your services:

```dart
// In your services (like auto_reply_service.dart):
final aiPreferences = ServiceLocator.instance.aiPreferences;
final preferences = await aiPreferences.getPreferences();

if (preferences.isAiEnabled && 
    preferences.conversations.smartRepliesEnabled) {
  // Show AI features
}
```

### 6. Real-time Updates

Listen to preference changes in your BLoCs:

```dart
BlocBuilder<AiPreferencesBloc, AiPreferencesState>(
  builder: (context, state) {
    if (state is AiPreferencesLoaded) {
      final isEnabled = state.preferences.conversations.smartRepliesEnabled;
      return isEnabled ? AiWidget() : RegularWidget();
    }
    return LoadingWidget();
  },
)
```

## Feature Keys

Use these keys when checking specific features:

- `'ai_enabled'` - Overall AI toggle
- `'smart_replies'` - Conversation smart replies
- `'auto_suggestions'` - Auto-generated suggestions  
- `'custom_replies'` - Custom AI-generated responses
- `'companion_chat'` - AI companion feature
- `'profile_optimization'` - Profile improvement suggestions
- `'smart_matching'` - AI-enhanced matching
- `'icebreaker_suggestions'` - Conversation starter suggestions

## State Management

The system provides these BLoC events:

```dart
// Load preferences
context.read<AiPreferencesBloc>().add(LoadAiPreferences());

// Toggle main AI
context.read<AiPreferencesBloc>().add(SetAiEnabled(true));

// Update specific feature settings
context.read<AiPreferencesBloc>().add(
  UpdateConversationSettings(newSettings)
);
```

## Privacy & Onboarding

The system includes:
- First-time AI onboarding dialog
- Privacy-focused default settings (opt-in required)
- Granular control over each AI feature
- Clear explanations of what each feature does

## Testing

To test the integration:

1. Run the demo app: `ai_integration_example.dart`
2. Check the AI settings screen functionality
3. Verify feature gating works correctly
4. Test onboarding flow for new users

## Migration

If you have existing AI features, update them to check preferences:

```dart
// Before:
Widget buildAiSuggestions() {
  return AiSuggestionsWidget();
}

// After:
Widget buildAiSuggestions() {
  return AiFeatureWrapper(
    feature: 'smart_replies',
    child: AiSuggestionsWidget(),
    fallback: SizedBox.shrink(),
  );
}
```

This ensures a smooth transition while respecting user preferences.