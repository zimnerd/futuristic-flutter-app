import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/profile/profile_relationship_goals_section.dart';
import '../../../domain/entities/user_profile.dart';

final logger = Logger();

/// User intent selection screen - Initial profile setup step
/// Reuses ProfileRelationshipGoalsSection widget for DRY principles
/// Allows users to select their primary purpose(s) for using the app
/// Integrated with ProfileBloc for backend sync
class IntentSelectionScreen extends StatefulWidget {
  const IntentSelectionScreen({super.key});

  @override
  State<IntentSelectionScreen> createState() => _IntentSelectionScreenState();
}

class _IntentSelectionScreenState extends State<IntentSelectionScreen> {
  // ✅ REUSING ProfileRelationshipGoalsSection - stores as list of selected goals
  List<String> _selectedIntents = [];

  /// Validate selection before saving
  bool _validateSelection() {
    if (_selectedIntents.isEmpty) {
      PulseToast.error(
        context,
        message: 'Please select at least one primary intent',
      );
      return false;
    }
    return true;
  }

  Future<void> _continue() async {
    // ✅ Validate
    if (!_validateSelection()) {
      return;
    }

    try {
      logger.i('💾 Saving intents to backend...');
      logger.i('  Selected intents: ${_selectedIntents.join(", ")}');

      // ✅ Save locally to SharedPreferences for profile setup tracking
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_intent_list', _selectedIntents);
      await prefs.setString(
        'user_intent_timestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setBool(
        'setup_intent_completed',
        true,
      ); // ✅ Mark step complete

      logger.i('✅ Intents saved to SharedPreferences');

      // ✅ Also save to backend via ProfileBloc
      // This ensures backend has user's selected intents
      final profileBloc = context.read<ProfileBloc>();
      final currentState = profileBloc.state;

      // Check if profile is loaded
      if (currentState.status == ProfileStatus.loaded &&
          currentState.profile != null) {
        final currentProfile = currentState.profile!;

        // Create updated profile with new intent data
        final updatedProfile = UserProfile(
          id: currentProfile.id,
          name: currentProfile.name,
          bio: currentProfile.bio,
          age: currentProfile.age,
          dateOfBirth: currentProfile.dateOfBirth,
          photos: currentProfile.photos,
          interests: currentProfile.interests,
          location: currentProfile.location,
          gender: currentProfile.gender,
          job: currentProfile.job,
          company: currentProfile.company,
          school: currentProfile.school,
          isOnline: currentProfile.isOnline,
          lastSeen: currentProfile.lastSeen,
          verified: currentProfile.verified,
          // ✅ Update relationshipGoals with selected intents
          relationshipGoals: _selectedIntents,
          // Keep all other fields
          lifestyleChoice: currentProfile.lifestyleChoice,
          height: currentProfile.height,
          religion: currentProfile.religion,
          politics: currentProfile.politics,
          drinking: currentProfile.drinking,
          smoking: currentProfile.smoking,
          drugs: currentProfile.drugs,
          children: currentProfile.children,
          languages: currentProfile.languages,
        );

        // Dispatch to backend
        logger.i('🚀 Dispatching UpdateProfile event to ProfileBloc...');
        if (mounted) {
          context.read<ProfileBloc>().add(
            UpdateProfile(profile: updatedProfile),
          );
        }

        logger.i('✅ Profile update sent to backend');
      } else {
        logger.w(
          '⚠️ Profile not loaded yet, will save intents to SharedPreferences only',
        );
      }

      if (mounted) {
        // Pop with true to signal step completion to profile setup wizard
        logger.i('✅ Intent selection complete - navigating back');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      logger.e('❌ Error saving intents: $e');
      if (mounted) {
        PulseToast.error(context, message: 'Failed to save preferences: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Your Primary Intent',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: PulseColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Help us personalize your experience and show you relevant connections.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ✅ REUSING ProfileRelationshipGoalsSection widget
            // This maintains consistency with ProfileEditScreen implementation
            // No duplicate code - single source of truth for intent selection UI
            ProfileRelationshipGoalsSection(
              selectedGoals: _selectedIntents,
              onChanged: (intents) {
                setState(() {
                  _selectedIntents = intents;
                });
              },
              title: 'What brings you here?',
              subtitle:
                  'Select one or more. You can change this anytime in your profile.',
              maxSelections: 3, // Allow up to 3 primary intents
            ),
            const SizedBox(height: 32),

            // Continue Button
            PulseButton(
              text: _selectedIntents.isEmpty
                  ? 'Select to Continue'
                  : 'Continue (${_selectedIntents.length} selected)',
              onPressed: _selectedIntents.isNotEmpty ? _continue : null,
              fullWidth: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
