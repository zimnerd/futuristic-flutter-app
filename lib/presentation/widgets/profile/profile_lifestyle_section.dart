import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Lifestyle preference selector for user profile
/// Maps to Profile.lifestyle field in backend Prisma schema
class ProfileLifestyleSection extends StatelessWidget {
  final String? selectedLifestyle;
  final Function(String?) onChanged;
  final String title;
  final String subtitle;

  const ProfileLifestyleSection({
    super.key,
    required this.selectedLifestyle,
    required this.onChanged,
    this.title = 'Lifestyle',
    this.subtitle = 'How would you describe your lifestyle?',
  });

  static const List<Map<String, dynamic>> lifestyleOptions = [
    {
      'value': 'active',
      'label': 'Active',
      'icon': Icons.directions_run,
      'description': 'Always on the move',
    },
    {
      'value': 'relaxed',
      'label': 'Relaxed',
      'icon': Icons.spa,
      'description': 'Taking it easy',
    },
    {
      'value': 'adventurous',
      'label': 'Adventurous',
      'icon': Icons.explore,
      'description': 'Love new experiences',
    },
    {
      'value': 'homebody',
      'label': 'Homebody',
      'icon': Icons.home,
      'description': 'Comfort is key',
    },
    {
      'value': 'social',
      'label': 'Social',
      'icon': Icons.people,
      'description': 'Love being around people',
    },
    {
      'value': 'independent',
      'label': 'Independent',
      'icon': Icons.person,
      'description': 'Value my alone time',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final subtitleColor = textColor.withValues(alpha: 0.6);
    final containerColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.2);

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
                  color: PulseColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: PulseColors.primary,
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
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lifestyle Options Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: lifestyleOptions.map((option) {
              final isSelected = selectedLifestyle == option['value'];
              return InkWell(
                onTap: () {
                  // Toggle: if already selected, deselect; otherwise select
                  onChanged(isSelected ? null : option['value'] as String);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PulseColors.primary.withValues(alpha: 0.2)
                        : containerColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? PulseColors.primary : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        color: isSelected
                            ? PulseColors.primary
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
                                  ? textColor
                                  : textColor.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            option['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? subtitleColor
                                  : subtitleColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Helper text
          if (selectedLifestyle != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: PulseColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This helps us match you with compatible people',
                      style: TextStyle(
                        fontSize: 12,
                        color: PulseColors.primary,
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
