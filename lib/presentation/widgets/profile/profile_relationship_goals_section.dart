import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Relationship goals multi-selector for user profile
/// Maps to Profile.relationshipGoals field in backend Prisma schema
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
    final updatedGoals = List<String>.from(selectedGoals);
    
    if (updatedGoals.contains(goalValue)) {
      // Remove if already selected
      updatedGoals.remove(goalValue);
    } else {
      // Add if not selected and within max limit
      if (maxSelections == null || updatedGoals.length < maxSelections!) {
        updatedGoals.add(goalValue);
      }
    }
    
    onChanged(updatedGoals);
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
                  color: PulseColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                              color: PulseColors.secondary.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.6),
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
              final isSelected = selectedGoals.contains(option['value']);
              final canSelect = maxSelections == null || 
                  selectedGoals.length < maxSelections! || 
                  isSelected;
              final isDisabled = !canSelect;

              return InkWell(
                onTap: isDisabled ? null : () => _toggleGoal(option['value'] as String),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PulseColors.secondary.withOpacity(0.2)
                        : isDisabled
                            ? Colors.white.withOpacity(0.02)
                            : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? PulseColors.secondary
                          : isDisabled
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.1),
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
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.7),
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
                                  ? Colors.white
                                  : isDisabled
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            option['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.7)
                                  : isDisabled
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: PulseColors.secondary,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Helper text
          if (selectedGoals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: PulseColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      maxSelections != null && selectedGoals.length >= maxSelections!
                          ? 'Maximum selections reached. Tap to deselect.'
                          : 'Being clear about your goals helps find the right match',
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
        ],
      ),
    );
  }
}
