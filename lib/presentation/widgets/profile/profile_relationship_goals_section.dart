import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

final logger = Logger();

/// Relationship goals multi-selector for user profile
/// Maps to Profile.relationshipGoals field in backend Prisma schema
/// 
/// This is a FULLY CONTROLLED widget - all state is managed by parent.
/// Parent passes selectedGoals and onChanged callback.
class ProfileRelationshipGoalsSection extends StatelessWidget {
  final List<String> selectedGoals;
  final Function(List<String>) onChanged;
  final String title;
  final String subtitle;
  final int? maxSelections;

  const ProfileRelationshipGoalsSection({
    super.key,
    required this.selectedGoals,
    required this.onChanged,
    this.title = 'Relationship Goals',
    this.subtitle = 'What are you looking for? (Select all that apply)',
    this.maxSelections,
  });

  static const List<Map<String, dynamic>> goalOptions = [
    {
      'value': 'dating',
      'label': 'Dating',
      'icon': Icons.favorite,
      'description': 'Looking for romance',
    },
    {
      'value': 'fun',
      'label': 'Fun',
      'icon': Icons.celebration,
      'description': 'Just having a good time',
    },
    {
      'value': 'intimacy-without-commitment',
      'label': 'Casual',
      'icon': Icons.nightlife,
      'description': 'No strings attached',
    },
    {
      'value': 'companionship',
      'label': 'Companionship',
      'icon': Icons.people_alt,
      'description': 'Meaningful connection',
    },
    {
      'value': 'friendship',
      'label': 'Friendship',
      'icon': Icons.handshake,
      'description': 'Building friendships',
    },
    {
      'value': 'event-companion',
      'label': 'Event Buddy',
      'icon': Icons.event,
      'description': 'Someone to go places with',
    },
  ];

  void _toggleGoal(String goalValue) {
    logger.i('🎯 _toggleGoal called for: $goalValue');
    logger.i('  Current selections: $selectedGoals');
    
    final updatedGoals = List<String>.from(selectedGoals);

    if (updatedGoals.contains(goalValue)) {
      logger.i('  ➖ Removing: $goalValue');
      updatedGoals.remove(goalValue);
    } else {
      logger.i('  ➕ Adding: $goalValue');
      if (maxSelections == null || updatedGoals.length < maxSelections!) {
        updatedGoals.add(goalValue);
      } else {
        logger.w('  ⚠️ Max selections reached, ignoring');
        return;
      }
    }

    logger.i('  ✅ Updated goals: $updatedGoals');
    logger.i('  🔔 Calling onChanged callback...');
    onChanged(updatedGoals);
  }

  /// Builds individual intent option widget
  /// Extracted to ensure proper tap handling and state synchronization
  Widget _buildGoalOption({
    required BuildContext context,
    required Map<String, dynamic> option,
    required bool isSelected,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
  }) {
    final optionValue = option['value'] as String;
    final canSelect =
        maxSelections == null ||
        selectedGoals.length < maxSelections! ||
        isSelected;
    final isDisabled = !canSelect;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                logger.i('💎 InkWell.onTap detected for: $optionValue');
                _toggleGoal(optionValue);
              },
        borderRadius: BorderRadius.circular(12),
        splashColor: PulseColors.secondary.withValues(alpha: 0.3),
        highlightColor: PulseColors.secondary.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? PulseColors.secondary.withValues(alpha: 0.2)
                : isDisabled
                ? context.borderColor.withValues(alpha: 0.2)
                : context.surfaceElevated.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? PulseColors.secondary
                  : isDisabled
                  ? context.borderLight
                  : borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option['icon'] as IconData,
                color: isSelected
                    ? PulseColors.secondary
                    : isDisabled
                    ? textColor.withValues(alpha: 0.3)
                    : textColor.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? context.textOnPrimary
                          : isDisabled
                          ? textColor.withValues(alpha: 0.4)
                          : textColor,
                    ),
                  ),
                  Text(
                    option['description'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? textColor.withValues(alpha: 0.7)
                          : isDisabled
                          ? textColor.withValues(alpha: 0.3)
                          : textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: PulseColors.secondary,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : context.outlineColor.shade50;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : context.outlineColor.withValues(alpha: 0.3);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.favorite_border,
                  color: PulseColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (maxSelections != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PulseColors.secondary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selectedGoals.length}/$maxSelections',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PulseColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Goals Options Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: goalOptions.map((option) {
              final optionValue = option['value'] as String;
              final isSelected = selectedGoals.contains(optionValue);

              return _buildGoalOption(
                context: context,
                option: option,
                isSelected: isSelected,
                isDark: isDark,
                textColor: textColor,
                borderColor: borderColor,
              );
            }).toList(),
          ),

          // Helper text
          if (selectedGoals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: PulseColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      maxSelections != null &&
                              selectedGoals.length >= maxSelections!
                          ? 'Maximum selections reached. Tap to deselect.'
                          : 'Being clear about your goals helps find the right match',
                      style: TextStyle(
                        fontSize: 12,
                        color: PulseColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
