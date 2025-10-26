import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Prompt questions and answers section for profile editing
/// Allows users to select from pre-defined prompts and provide personalized answers
class ProfilePromptsSection extends StatefulWidget {
  final Map<String, String> initialPromptAnswers;
  final void Function(Map<String, String>) onPromptsChanged;

  const ProfilePromptsSection({
    super.key,
    required this.initialPromptAnswers,
    required this.onPromptsChanged,
  });

  /// Available prompt questions for users to answer
  static const List<String> availablePrompts = [
    'My ideal weekend is...',
    'I can talk for hours about...',
    'My hidden talent is...',
    'The best travel experience I had was...',
    'You should know that I...',
    'I\'m obsessed with...',
    'If I could live anywhere, I\'d live in...',
    'My go-to karaoke song is...',
    'Life is better with...',
    'My favorite smell is...',
    'I always have...',
    'A perfect day for me looks like...',
    'My most unpopular opinion is...',
    'I\'ll never forget...',
    'The most interesting thing about me is...',
  ];

  @override
  State<ProfilePromptsSection> createState() => _ProfilePromptsSectionState();
}

class _ProfilePromptsSectionState extends State<ProfilePromptsSection> {
  late Map<String, String> _promptAnswers;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _promptAnswers = Map.from(widget.initialPromptAnswers);
    _controllers = {};
    
    // Initialize controllers with existing answers
    for (final prompt in ProfilePromptsSection.availablePrompts) {
      _controllers[prompt] = TextEditingController(
        text: _promptAnswers[prompt] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePromptAnswer(String prompt, String answer) {
    setState(() {
      if (answer.isEmpty) {
        _promptAnswers.remove(prompt);
      } else {
        _promptAnswers[prompt] = answer;
      }
    });
    widget.onPromptsChanged(_promptAnswers);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPrompts = _promptAnswers.keys.toList();
    final maxPrompts = 3;

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
                  'Profile Prompts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose up to $maxPrompts prompts and tell us your answers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.onSurfaceVariantColor,
                      ),
                ),
              ],
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
                    Icons.tips_and_updates_outlined,
                    color: PulseColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Good answers help start great conversations',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.onSurfaceVariantColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Selected prompts counter
            if (selectedPrompts.isNotEmpty)
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
                        '${selectedPrompts.length}/$maxPrompts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'prompts answered',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.onSurfaceVariantColor,
                          ),
                    ),
                  ],
                ),
              ),

            // Prompt cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ProfilePromptsSection.availablePrompts.length,
              itemBuilder: (context, index) {
                final prompt =
                    ProfilePromptsSection.availablePrompts[index];
                final isSelected = _promptAnswers.containsKey(prompt);
                final controller = _controllers[prompt]!;
                final isEnabled = isSelected ||
                    selectedPrompts.length < maxPrompts;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: isEnabled && !isSelected
                        ? () => _updatePromptAnswer(prompt, '')
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? PulseColors.primary
                              : (isEnabled
                                  ? context.outlineColor
                                  : context.outlineColor
                                      .withValues(alpha: 0.3)),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? PulseColors.primary.withValues(alpha: 0.05)
                            : (isEnabled ? Colors.transparent : Colors.transparent),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prompt header with toggle
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  prompt,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? PulseColors.primary
                                            : context.onSurfaceColor,
                                      ),
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                onChanged: isEnabled
                                    ? (value) {
                                        if (value == true) {
                                          _updatePromptAnswer(prompt, '');
                                        } else {
                                          _updatePromptAnswer(prompt, '');
                                        }
                                      }
                                    : null,
                                activeColor: PulseColors.primary,
                                side: BorderSide(
                                  color: isSelected
                                      ? PulseColors.primary
                                      : context.outlineColor,
                                ),
                              ),
                            ],
                          ),

                          // Answer text field (visible only if selected)
                          if (isSelected) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              onChanged: (value) =>
                                  _updatePromptAnswer(prompt, value),
                              maxLines: 3,
                              minLines: 2,
                              maxLength: 150,
                              decoration: InputDecoration(
                                hintText: 'Write your answer here...',
                                hintStyle: TextStyle(
                                  color: context.onSurfaceVariantColor
                                      .withValues(alpha: 0.5),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.outlineColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: PulseColors.primary,
                                    width: 2,
                                  ),
                                ),
                                counterText: '',
                                contentPadding:
                                    const EdgeInsets.all(12),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: context.onSurfaceColor,
                                  ),
                            ),
                            Text(
                              '${controller.text.length}/150',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        context.onSurfaceVariantColor,
                                  ),
                              textAlign: TextAlign.end,
                            ),
                          ],

                          // Disabled state message
                          if (!isEnabled && !isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Maximum $maxPrompts prompts reached',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.onSurfaceVariantColor
                                          .withValues(alpha: 0.5),
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
