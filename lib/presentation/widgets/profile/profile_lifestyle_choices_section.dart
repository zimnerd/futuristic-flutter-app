import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Lifestyle choices section for user profile
/// Maps to User.drinkingHabit, User.smokingHabit, User.exerciseHabit fields (backend enums)
/// and Profile.drugs, Profile.children fields
class ProfileLifestyleChoicesSection extends StatelessWidget {
  final String? drinking;
  final String? smoking;
  final String? exercise;
  final String? drugs;
  final String? children;
  final Function(String?) onDrinkingChanged;
  final Function(String?) onSmokingChanged;
  final Function(String?) onExerciseChanged;
  final Function(String?) onDrugsChanged;
  final Function(String?) onChildrenChanged;
  final String title;
  final String subtitle;

  const ProfileLifestyleChoicesSection({
    super.key,
    required this.drinking,
    required this.smoking,
    required this.exercise,
    required this.drugs,
    required this.children,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
    required this.onExerciseChanged,
    required this.onDrugsChanged,
    required this.onChildrenChanged,
    this.title = 'Lifestyle Choices',
    this.subtitle = 'Share your lifestyle preferences',
  });

  static const List<String> drinkingOptions = [
    'Never',
    'Rarely',
    'Socially',
    'Regularly',
    'Prefer not to say',
  ];

  static const List<String> smokingOptions = [
    'Never',
    'Socially',
    'Regularly',
    'Trying to quit',
    'Prefer not to say',
  ];

  static const List<String> exerciseOptions = [
    'Never',
    'Rarely',
    'Sometimes',
    'Regularly',
    'Daily',
  ];

  static const List<String> childrenOptions = [
    'Don\'t have, don\'t want',
    'Don\'t have, want someday',
    'Don\'t have, not sure',
    'Have, want more',
    'Have, don\'t want more',
    'Prefer not to say',
  ];

  // Map UI labels to backend enum values
  static String? mapDrinkingToBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Never':
        return 'NEVER';
      case 'Rarely':
        return 'RARELY';
      case 'Socially':
        return 'SOCIALLY';
      case 'Regularly':
        return 'REGULARLY';
      case 'Prefer not to say':
        return 'PREFER_NOT_TO_SAY';
      default:
        return value.toUpperCase();
    }
  }

  static String? mapSmokingToBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Never':
        return 'NEVER';
      case 'Socially':
        return 'SOCIALLY';
      case 'Regularly':
        return 'REGULARLY';
      case 'Trying to quit':
        return 'TRYING_TO_QUIT';
      case 'Prefer not to say':
        return 'PREFER_NOT_TO_SAY';
      default:
        return value.toUpperCase();
    }
  }

  static String? mapExerciseToBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Never':
        return 'NEVER';
      case 'Rarely':
        return 'RARELY';
      case 'Sometimes':
        return 'SOMETIMES';
      case 'Regularly':
        return 'REGULARLY';
      case 'Daily':
        return 'DAILY';
      default:
        return value.toUpperCase();
    }
  }

  static String? mapChildrenToBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Don\'t have, don\'t want':
        return 'doesnt-want';
      case 'Don\'t have, want someday':
        return 'wants';
      case 'Don\'t have, not sure':
        return 'open-to';
      case 'Have, want more':
        return 'has';
      case 'Have, don\'t want more':
        return 'has';
      case 'Prefer not to say':
        return 'prefer-not-to-say';
      default:
        return value.toLowerCase();
    }
  }

  // Map backend values to UI labels
  static String? mapDrinkingFromBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'NEVER':
        return 'Never';
      case 'RARELY':
        return 'Rarely';
      case 'SOCIALLY':
        return 'Socially';
      case 'REGULARLY':
        return 'Regularly';
      case 'PREFER_NOT_TO_SAY':
        return 'Prefer not to say';
      default:
        return value;
    }
  }

  static String? mapSmokingFromBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'NEVER':
        return 'Never';
      case 'SOCIALLY':
        return 'Socially';
      case 'REGULARLY':
        return 'Regularly';
      case 'TRYING_TO_QUIT':
        return 'Trying to quit';
      case 'PREFER_NOT_TO_SAY':
        return 'Prefer not to say';
      default:
        return value;
    }
  }

  static String? mapExerciseFromBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'NEVER':
        return 'Never';
      case 'RARELY':
        return 'Rarely';
      case 'SOMETIMES':
        return 'Sometimes';
      case 'REGULARLY':
        return 'Regularly';
      case 'DAILY':
        return 'Daily';
      default:
        return value;
    }
  }

  static String? mapChildrenFromBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'doesnt-want':
        return 'Don\'t have, don\'t want';
      case 'wants':
        return 'Don\'t have, want someday';
      case 'open-to':
        return 'Don\'t have, not sure';
      case 'has':
        return 'Have, want more';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return value;
    }
  }

  static const Map<String, IconData> categoryIcons = {
    'drinking': Icons.local_bar_outlined,
    'smoking': Icons.smoking_rooms_outlined,
    'exercise': Icons.fitness_center_outlined,
    'drugs': Icons.healing_outlined,
    'children': Icons.child_care_outlined,
  };

  Widget _buildChoiceSelector({
    required BuildContext context,
    required String label,
    required String category,
    required String? value,
    required Function(String?) onChanged,
    required List<String> options,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final subtitleColor = textColor.withValues(alpha: 0.7);
    final containerColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.shade50; // Light grey for better contrast
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.3);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              categoryIcons[category],
              size: 18,
              color: PulseColors.warning.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = value == option;
            return InkWell(
              onTap: () => onChanged(isSelected ? null : option),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PulseColors.warning.withValues(alpha: 0.2)
                      : containerColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? PulseColors.warning
                        : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? PulseColors.warning : subtitleColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final subtitleColor = textColor.withValues(alpha: 0.6);
    final containerColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.shade50; // Light grey background for better contrast
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.3);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
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
                  color: PulseColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: PulseColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Drinking
          _buildChoiceSelector(
            context: context,
            label: 'Drinking',
            category: 'drinking',
            value: drinking,
            onChanged: onDrinkingChanged,
            options: drinkingOptions,
          ),
          const SizedBox(height: 20),

          // Smoking
          _buildChoiceSelector(
            context: context,
            label: 'Smoking',
            category: 'smoking',
            value: smoking,
            onChanged: onSmokingChanged,
            options: smokingOptions,
          ),
          const SizedBox(height: 20),

          // Exercise
          _buildChoiceSelector(
            context: context,
            label: 'Exercise',
            category: 'exercise',
            value: exercise,
            onChanged: onExerciseChanged,
            options: exerciseOptions,
          ),
          const SizedBox(height: 20),

          // Drugs
          _buildChoiceSelector(
            context: context,
            label: 'Drugs',
            category: 'drugs',
            value: drugs,
            onChanged: onDrugsChanged,
            options: drinkingOptions, // Reuse drinking options for drugs
          ),
          const SizedBox(height: 20),

          // Children
          _buildChoiceSelector(
            context: context,
            label: 'Children',
            category: 'children',
            value: children,
            onChanged: onChildrenChanged,
            options: childrenOptions,
          ),

          // Info banner
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PulseColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: PulseColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Being honest helps find compatible matches',
                    style: TextStyle(
                      fontSize: 12,
                      color: PulseColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
