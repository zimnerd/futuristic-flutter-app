import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/pulse_toast.dart';

/// User intent selection screen
/// Allows users to select their primary purpose for using the app
class IntentSelectionScreen extends StatefulWidget {
  const IntentSelectionScreen({super.key});

  @override
  State<IntentSelectionScreen> createState() => _IntentSelectionScreenState();
}

class _IntentSelectionScreenState extends State<IntentSelectionScreen> {
  String? _selectedIntent;
  final List<String> _secondaryIntents = [];

  final List<IntentOption> _intentOptions = [
    IntentOption(
      id: 'dating',
      title: 'Dating',
      description: 'Find romantic connections and meaningful relationships',
      icon: Icons.favorite,
      color: Color(0xFFFF6B9D),
    ),
    IntentOption(
      id: 'friendship',
      title: 'Friendship',
      description: 'Make new friends and expand your social circle',
      icon: Icons.people,
      color: Color(0xFF4ECDC4),
    ),
    IntentOption(
      id: 'events',
      title: 'Events & Activities',
      description: 'Find people to attend events and activities with',
      icon: Icons.event,
      color: Color(0xFFFFA726),
    ),
    IntentOption(
      id: 'companion',
      title: 'AI Companion',
      description: 'Chat with AI for advice, support, and conversation',
      icon: Icons.psychology,
      color: Color(0xFF9C27B0),
    ),
    IntentOption(
      id: 'support',
      title: 'Emotional Support',
      description: 'Connect with understanding people and find support',
      icon: Icons.favorite_border,
      color: Color(0xFF66BB6A),
    ),
    IntentOption(
      id: 'explore',
      title: 'Explore Everything',
      description: 'I want to explore all features and decide later',
      icon: Icons.explore,
      color: Color(0xFF7E57C2),
    ),
  ];

  void _toggleSecondaryIntent(String intentId) {
    setState(() {
      if (_secondaryIntents.contains(intentId)) {
        _secondaryIntents.remove(intentId);
      } else {
        _secondaryIntents.add(intentId);
      }
    });
  }

  Future<void> _continue() async {
    if (_selectedIntent == null) {
      PulseToast.error(context, message: 'Please select your primary intent');
      return;
    }

    // Save intent to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_intent_primary', _selectedIntent!);
      await prefs.setStringList('user_intent_secondary', _secondaryIntents);
      await prefs.setString(
        'user_intent_timestamp',
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        // Pop with true to signal step completion to profile setup wizard
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Failed to save preferences: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PulseColors.primary.withValues(alpha: 0.1),
              PulseColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(PulseSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What brings you here?',
                              style: PulseTextStyles.displaySmall.copyWith(
                                color: PulseColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: PulseSpacing.md),
                            Text(
                              'Choose your primary intent. You can explore other features anytime.',
                              style: PulseTextStyles.bodyLarge.copyWith(
                                color: PulseColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Intent Options
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PulseSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final option = _intentOptions[index];
                          final isSelected = _selectedIntent == option.id;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: PulseSpacing.md,
                            ),
                            child: IntentCard(
                              option: option,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedIntent = option.id;
                                  // Remove from secondary if selected as primary
                                  _secondaryIntents.remove(option.id);
                                });
                              },
                            ),
                          );
                        }, childCount: _intentOptions.length),
                      ),
                    ),

                    // Secondary Intents Section
                    if (_selectedIntent != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(PulseSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: PulseSpacing.lg),
                              Text(
                                'Also interested in? (Optional)',
                                style: PulseTextStyles.titleMedium.copyWith(
                                  color: PulseColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: PulseSpacing.sm),
                              Text(
                                'Select additional interests to personalize your experience',
                                style: PulseTextStyles.bodyMedium.copyWith(
                                  color: PulseColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: PulseSpacing.md),
                              Wrap(
                                spacing: PulseSpacing.sm,
                                runSpacing: PulseSpacing.sm,
                                children: _intentOptions
                                    .where((opt) => opt.id != _selectedIntent)
                                    .map((option) {
                                      final isSelected = _secondaryIntents
                                          .contains(option.id);
                                      return ChoiceChip(
                                        label: Text(option.title),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          _toggleSecondaryIntent(option.id);
                                        },
                                        avatar: Icon(
                                          option.icon,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : option.color,
                                        ),
                                        selectedColor: option.color,
                                        backgroundColor: option.color
                                            .withValues(alpha: 0.1),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : PulseColors.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bottom Spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),

              // Continue Button
              Container(
                padding: const EdgeInsets.all(PulseSpacing.lg),
                decoration: BoxDecoration(
                  color: PulseColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedIntent != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: PulseSpacing.md),
                        child: Text(
                          _secondaryIntents.isEmpty
                              ? 'Primary: ${_intentOptions.firstWhere((o) => o.id == _selectedIntent).title}'
                              : 'Primary: ${_intentOptions.firstWhere((o) => o.id == _selectedIntent).title} + ${_secondaryIntents.length} more',
                          style: PulseTextStyles.bodySmall.copyWith(
                            color: PulseColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    PulseButton(
                      text: 'Continue',
                      onPressed: _selectedIntent != null ? _continue : null,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Intent option data model
class IntentOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const IntentOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Intent card widget
class IntentCard extends StatelessWidget {
  final IntentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const IntentCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PulseRadii.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(PulseSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.1)
              : PulseColors.surface,
          border: Border.all(
            color: isSelected ? option.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(PulseRadii.lg),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color
                    : option.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(PulseRadii.md),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? Colors.white : option.color,
                size: 28,
              ),
            ),
            const SizedBox(width: PulseSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: PulseTextStyles.titleMedium.copyWith(
                      color: PulseColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: PulseSpacing.xs),
                  Text(
                    option.description,
                    style: PulseTextStyles.bodyMedium.copyWith(
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Selected Indicator
            if (isSelected)
              Icon(Icons.check_circle, color: option.color, size: 28),
          ],
        ),
      ),
    );
  }
}
