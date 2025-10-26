import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Personality traits section for profile editing
/// Allows users to select multiple personality traits that define them
class ProfilePersonalityTraitsSection extends StatefulWidget {
  final List<String> initialTraits;
  final void Function(List<String>) onTraitsChanged;

  const ProfilePersonalityTraitsSection({
    super.key,
    required this.initialTraits,
    required this.onTraitsChanged,
  });

  /// Available personality traits for the user to select
  static const List<String> availableTraits = [
    'Adventurous',
    'Ambitious',
    'Artistic',
    'Athletic',
    'Calm',
    'Charming',
    'Compassionate',
    'Confident',
    'Creative',
    'Curious',
    'Dependable',
    'Down-to-earth',
    'Driven',
    'Empathetic',
    'Energetic',
    'Funny',
    'Generous',
    'Genuine',
    'Goofy',
    'Grounded',
    'Helpful',
    'Honest',
    'Humble',
    'Independent',
    'Intelligent',
    'Intuitive',
    'Joyful',
    'Kind',
    'Loyal',
    'Mindful',
    'Observant',
    'Optimistic',
    'Outgoing',
    'Passionate',
    'Patient',
    'Perceptive',
    'Playful',
    'Principled',
    'Quirky',
    'Reflective',
    'Responsible',
    'Romantic',
    'Sarcastic',
    'Sensitive',
    'Sincere',
    'Soulful',
    'Spontaneous',
    'Thoughtful',
    'Trustworthy',
    'Unconventional',
    'Warm',
    'Wise',
    'Witty',
  ];

  @override
  State<ProfilePersonalityTraitsSection> createState() =>
      _ProfilePersonalityTraitsSectionState();
}

class _ProfilePersonalityTraitsSectionState
    extends State<ProfilePersonalityTraitsSection> {
  late List<String> _selectedTraits;

  @override
  void initState() {
    super.initState();
    _selectedTraits = List.from(widget.initialTraits);
  }

  void _toggleTrait(String trait) {
    setState(() {
      if (_selectedTraits.contains(trait)) {
        _selectedTraits.remove(trait);
      } else {
        // Limit to 5 traits max (best practice for dating apps)
        if (_selectedTraits.length < 5) {
          _selectedTraits.add(trait);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maximum 5 traits allowed'),
              backgroundColor: PulseColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
    widget.onTraitsChanged(_selectedTraits);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Personality',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select traits that best describe you (up to 5)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.onSurfaceVariantColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selected traits counter
            if (_selectedTraits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            PulseColors.primary,
                            PulseColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${_selectedTraits.length}/5',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selected: ${_selectedTraits.join(", ")}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.onSurfaceVariantColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Traits grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ProfilePersonalityTraitsSection.availableTraits
                  .map((trait) {
                final isSelected = _selectedTraits.contains(trait);
                return GestureDetector(
                  onTap: () => _toggleTrait(trait),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? PulseColors.primary
                            : context.outlineColor,
                        width: isSelected ? 2 : 1.5,
                      ),
                      color: isSelected
                          ? PulseColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: PulseColors.primary,
                            ),
                          ),
                        Text(
                          trait,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? PulseColors.primary
                                        : context.onSurfaceColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Info box
            Container(
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PulseColors.primary.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: PulseColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These traits help us find better matches for you',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.onSurfaceVariantColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
