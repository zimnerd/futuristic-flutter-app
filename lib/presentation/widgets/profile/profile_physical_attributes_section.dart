import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Physical attributes and beliefs section for user profile
/// Maps to Profile.height, Profile.religion, Profile.politics fields
class ProfilePhysicalAttributesSection extends StatelessWidget {
  final int? height; // Height in cm
  final String? religion;
  final String? politics;
  final Function(int?) onHeightChanged;
  final Function(String?) onReligionChanged;
  final Function(String?) onPoliticsChanged;
  final String title;
  final String subtitle;

  const ProfilePhysicalAttributesSection({
    super.key,
    required this.height,
    required this.religion,
    required this.politics,
    required this.onHeightChanged,
    required this.onReligionChanged,
    required this.onPoliticsChanged,
    this.title = 'About You',
    this.subtitle = 'Help others get to know you better',
  });

  static const List<String> religionOptions = [
    'Agnostic',
    'Atheist',
    'Buddhist',
    'Catholic',
    'Christian',
    'Hindu',
    'Jewish',
    'Muslim',
    'Sikh',
    'Spiritual',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> politicsOptions = [
    'Liberal',
    'Moderate',
    'Conservative',
    'Prefer not to say',
  ];

  // Map UI labels to backend enum values
  static String? mapPoliticsToBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Liberal':
        return 'liberal';
      case 'Moderate':
        return 'moderate';
      case 'Conservative':
        return 'conservative';
      case 'Prefer not to say':
        return 'prefer-not-to-say';
      default:
        return value.toLowerCase();
    }
  }

  // Map backend values to UI labels
  static String? mapPoliticsFromBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'liberal':
        return 'Liberal';
      case 'moderate':
        return 'Moderate';
      case 'conservative':
        return 'Conservative';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return value;
    }
  }

  String _formatHeight(int cm) {
    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$cm cm ($feet\'$inches")';
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors (matching Languages section pattern)
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
                  color: PulseColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: PulseColors.success,
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
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Height Slider with Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Height',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                  ),
                  // Always show formatted height value
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: height != null
                          ? PulseColors.success.withValues(alpha: 0.2)
                          : textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      height != null ? _formatHeight(height!) : 'Not set',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: height != null
                            ? PulseColors.success
                            : textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: PulseColors.success,
                  inactiveTrackColor: textColor.withValues(alpha: 0.1),
                  thumbColor: PulseColors.success,
                  overlayColor: PulseColors.success.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: (height ?? 170).toDouble(),
                  min: 120,
                  max: 220,
                  divisions: 100,
                  label: height != null ? _formatHeight(height!) : '170 cm',
                  onChanged: (value) => onHeightChanged(value.toInt()),
                ),
              ),

              // Direct input field
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: height != null
                        ? PulseColors.success.withValues(alpha: 0.5)
                        : borderColor,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  key: ValueKey(height), // Rebuild when height changes
                  initialValue: height?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter height in cm (120-220)',
                    hintStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixText: 'cm',
                    suffixStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      onHeightChanged(null);
                      return;
                    }
                    final numValue = int.tryParse(value);
                    if (numValue != null &&
                        numValue >= 120 &&
                        numValue <= 220) {
                      onHeightChanged(numValue);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Religion Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Religion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: religion != null
                        ? PulseColors.success.withValues(alpha: 0.5)
                        : borderColor,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: religion,
                    hint: Text(
                      'Select your religion',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1A1F3A)
                        : Colors.white,
                    style: TextStyle(color: textColor, fontSize: 14),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Select your religion',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      ...religionOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }),
                    ],
                    onChanged: onReligionChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Politics Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Political Views',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: politics != null
                        ? PulseColors.success.withValues(alpha: 0.5)
                        : borderColor,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: politics,
                    hint: Text(
                      'Select your political views',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1A1F3A)
                        : Colors.white,
                    style: TextStyle(color: textColor, fontSize: 14),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Select your political views',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      ...politicsOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }),
                    ],
                    onChanged: onPoliticsChanged,
                  ),
                ),
              ),
            ],
          ),

          // Info banner
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PulseColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This information is optional and helps find compatible matches',
                    style: TextStyle(fontSize: 12, color: PulseColors.success),
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
