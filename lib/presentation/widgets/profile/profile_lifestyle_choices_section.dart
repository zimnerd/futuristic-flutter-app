import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Lifestyle choices section for user profile
/// Maps to Profile.drinking, Profile.smoking, Profile.drugs, Profile.children fields
class ProfileLifestyleChoicesSection extends StatelessWidget {
  final String? drinking;
  final String? smoking;
  final String? drugs;
  final String? children;
  final Function(String?) onDrinkingChanged;
  final Function(String?) onSmokingChanged;
  final Function(String?) onDrugsChanged;
  final Function(String?) onChildrenChanged;
  final String title;
  final String subtitle;

  const ProfileLifestyleChoicesSection({
    super.key,
    required this.drinking,
    required this.smoking,
    required this.drugs,
    required this.children,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
    required this.onDrugsChanged,
    required this.onChildrenChanged,
    this.title = 'Lifestyle Choices',
    this.subtitle = 'Share your lifestyle preferences',
  });

  static const List<String> frequencyOptions = [
    'Never',
    'Occasionally',
    'Regularly',
    'Prefer not to say',
  ];

  static const List<String> childrenOptions = [
    'Don\'t have, don\'t want',
    'Don\'t have, want someday',
    'Don\'t have, not sure',
    'Have, want more',
    'Have, don\'t want more',
    'Prefer not to say',
  ];

  static const Map<String, IconData> categoryIcons = {
    'drinking': Icons.local_bar_outlined,
    'smoking': Icons.smoking_rooms_outlined,
    'drugs': Icons.healing_outlined,
    'children': Icons.child_care_outlined,
  };

  Widget _buildChoiceSelector({
    required String label,
    required String category,
    required String? value,
    required Function(String?) onChanged,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              categoryIcons[category],
              size: 18,
              color: PulseColors.warning.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
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
                      ? PulseColors.warning.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? PulseColors.warning
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                  color: PulseColors.warning.withOpacity(0.2),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
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
            label: 'Drinking',
            category: 'drinking',
            value: drinking,
            onChanged: onDrinkingChanged,
            options: frequencyOptions,
          ),
          const SizedBox(height: 20),

          // Smoking
          _buildChoiceSelector(
            label: 'Smoking',
            category: 'smoking',
            value: smoking,
            onChanged: onSmokingChanged,
            options: frequencyOptions,
          ),
          const SizedBox(height: 20),

          // Drugs
          _buildChoiceSelector(
            label: 'Drugs',
            category: 'drugs',
            value: drugs,
            onChanged: onDrugsChanged,
            options: frequencyOptions,
          ),
          const SizedBox(height: 20),

          // Children
          _buildChoiceSelector(
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
              color: PulseColors.warning.withOpacity(0.1),
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
                      color: Colors.white.withOpacity(0.7),
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
