import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Languages multi-selector for user profile
/// Maps to Profile.languages field in backend Prisma schema
class ProfileLanguagesSection extends StatelessWidget {
  final List<String> selectedLanguages;
  final Function(List<String>) onChanged;
  final String title;
  final String subtitle;
  final int? maxSelections;

  const ProfileLanguagesSection({
    super.key,
    required this.selectedLanguages,
    required this.onChanged,
    this.title = 'Languages',
    this.subtitle = 'Select the languages you speak',
    this.maxSelections,
  });

  static const List<Map<String, dynamic>> languageOptions = [
    {'value': 'English', 'icon': '🇬🇧'},
    {'value': 'Spanish', 'icon': '🇪🇸'},
    {'value': 'French', 'icon': '🇫🇷'},
    {'value': 'German', 'icon': '🇩🇪'},
    {'value': 'Italian', 'icon': '🇮🇹'},
    {'value': 'Portuguese', 'icon': '🇵🇹'},
    {'value': 'Russian', 'icon': '🇷🇺'},
    {'value': 'Chinese', 'icon': '🇨🇳'},
    {'value': 'Japanese', 'icon': '🇯🇵'},
    {'value': 'Korean', 'icon': '🇰🇷'},
    {'value': 'Arabic', 'icon': '🇸🇦'},
    {'value': 'Hindi', 'icon': '🇮🇳'},
    {'value': 'Turkish', 'icon': '🇹🇷'},
    {'value': 'Dutch', 'icon': '🇳🇱'},
    {'value': 'Swedish', 'icon': '🇸🇪'},
    {'value': 'Polish', 'icon': '🇵🇱'},
    {'value': 'Greek', 'icon': '🇬🇷'},
    {'value': 'Thai', 'icon': '🇹🇭'},
    {'value': 'Vietnamese', 'icon': '🇻🇳'},
    {'value': 'Indonesian', 'icon': '🇮🇩'},
    {'value': 'Other', 'icon': '🌐'},
  ];

  void _toggleLanguage(String language) {
    final updatedLanguages = List<String>.from(selectedLanguages);
    
    if (updatedLanguages.contains(language)) {
      updatedLanguages.remove(language);
    } else {
      if (maxSelections == null || updatedLanguages.length < maxSelections!) {
        updatedLanguages.add(language);
      }
    }
    
    onChanged(updatedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.shade50;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.3);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    
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
                  color: PulseColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.language,
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
                        if (selectedLanguages.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PulseColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              maxSelections != null
                                  ? '${selectedLanguages.length}/$maxSelections'
                                  : '${selectedLanguages.length}',
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

          // Languages Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: languageOptions.map((option) {
              final language = option['value'] as String;
              final icon = option['icon'] as String;
              final isSelected = selectedLanguages.contains(language);
              final canSelect = maxSelections == null || 
                  selectedLanguages.length < maxSelections! || 
                  isSelected;
              final isDisabled = !canSelect;

              return InkWell(
                onTap: isDisabled ? null : () => _toggleLanguage(language),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PulseColors.secondary.withValues(alpha: 0.2)
                        : isDisabled
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.grey.shade100)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? PulseColors.secondary
                          : isDisabled
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade200)
                          : borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        icon,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDisabled
                              ? textColor.withValues(alpha: 0.3)
                              : textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        language,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? textColor
                              : isDisabled
                              ? textColor.withValues(alpha: 0.4)
                              : textColor.withValues(alpha: 0.8),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          color: PulseColors.secondary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Helper text
          if (selectedLanguages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.translate,
                    size: 16,
                    color: PulseColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      maxSelections != null && selectedLanguages.length >= maxSelections!
                          ? 'Maximum languages selected. Tap to deselect.'
                          : 'Speaking multiple languages expands your potential matches',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
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
