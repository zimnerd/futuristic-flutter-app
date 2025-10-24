import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../core/constants/relationship_goals_options.dart';

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
  late Future<List<Map<String, dynamic>>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsFuture = RelationshipGoalsOptions.getAll();
  }

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
    logger.w('🔵 Continue button pressed');
    logger.w('  Selected intents: $_selectedIntents');
    
    // ✅ Validate
    if (!_validateSelection()) {
      logger.e('❌ Validation failed');
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

  /// Build intent option widgets - fetches from API
  Widget _buildIntentOptions() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading goals: ${snapshot.error}'),
          );
        }

        final goals = snapshot.data ?? [];

        if (goals.isEmpty) {
          return const Center(child: Text('No goals available'));
        }

        return Column(
          children: goals.map((option) {
            final optionSlug = option['slug'] as String;
            final isSelected = _selectedIntents.contains(optionSlug);
            final colorHex = option['color'] as String? ?? '#7E57C2';
            final color = _parseColorFromHex(colorHex);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GestureDetector(
                onTap: () {
                  logger.i(
                    '🎯 GestureDetector.onTap - Goal selected: $optionSlug',
                  );
                  setState(() {
                    if (isSelected) {
                      _selectedIntents.remove(optionSlug);
                      logger.i('  ➖ Removed: $optionSlug');
                    } else {
                      // Max 1 selection
                      _selectedIntents.clear();
                      _selectedIntents.add(optionSlug);
                      logger.i('  ➕ Added: $optionSlug');
                    }
                    logger.i('  Current selections: $_selectedIntents');
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Radio button
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          option['iconData'] as IconData? ?? Icons.explore,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['title'] as String? ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option['description'] as String? ?? 'No description',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Parse color from hex string
  Color _parseColorFromHex(String hexString) {
    try {
      final hex = hexString.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF7E57C2); // Fallback color
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('🎨 IntentSelectionScreen.build() called');
    logger.i('  Current selections: $_selectedIntents');
    logger.i('  Button enabled: ${_selectedIntents.length == 1}');
    
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
          'Your Primary Intent?',
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

            // Intent Options - Direct Implementation (No DRY)
            // Breaking DRY principle for guaranteed functionality
            // Using the same pattern from profile_section_edit_screen.dart that works
            Text(
              'What brings you here?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: PulseColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your primary intent. You can explore other features anytime.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            _buildIntentOptions(),
            const SizedBox(height: 32),

            // Continue Button
            // ✅ Only enabled when exactly 1 intent selected
            PulseButton(
              text: 'Continue',
              onPressed: _selectedIntents.length == 1 ? _continue : null,
              fullWidth: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
