import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Profile strength meter widget that shows completion percentage
/// and suggests what to complete for better profile visibility
class ProfileStrengthIndicator extends StatelessWidget {
  final int completionPercentage;
  final List<String> completedSections;
  final List<String> missingSections;

  const ProfileStrengthIndicator({
    super.key,
    required this.completionPercentage,
    required this.completedSections,
    required this.missingSections,
  });

  /// Get color based on completion percentage
  Color _getStrengthColor() {
    if (completionPercentage >= 90) return const Color(0xFF00D95F); // Green
    if (completionPercentage >= 70) return const Color(0xFF00C2FF); // Cyan
    if (completionPercentage >= 50) return const Color(0xFFFFA500); // Orange
    return PulseColors.error; // Red
  }

  /// Get strength label
  String _getStrengthLabel() {
    if (completionPercentage >= 90) return 'Exceptional';
    if (completionPercentage >= 70) return 'Great';
    if (completionPercentage >= 50) return 'Good';
    return 'Needs work';
  }

  /// Get strength message
  String _getStrengthMessage() {
    if (completionPercentage >= 90) {
      return 'Your profile is highly attractive! Keep it up!';
    }
    if (completionPercentage >= 70) {
      return 'Great profile! Add a few more details to stand out.';
    }
    if (completionPercentage >= 50) {
      return 'Good start! Complete more sections for better matches.';
    }
    return 'Fill out your profile to get started!';
  }

  @override
  Widget build(BuildContext context) {
    final strengthColor = _getStrengthColor();
    final strengthLabel = _getStrengthLabel();
    final strengthMessage = _getStrengthMessage();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Profile Strength',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.onSurfaceColor,
                ),
          ),
          const SizedBox(height: 20),

          // Main strength card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: strengthColor.withValues(alpha: 0.2),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  strengthColor.withValues(alpha: 0.08),
                  strengthColor.withValues(alpha: 0.03),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Percentage and label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: context.onSurfaceVariantColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completionPercentage%',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: strengthColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: strengthColor.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            strengthLabel,
                            style: TextStyle(
                              color: strengthColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress bar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: context.outlineColor.withValues(alpha: 0.2),
                  ),
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        strengthColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  strengthMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceVariantColor,
                        height: 1.5,
                      ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Completed sections
          if (completedSections.isNotEmpty) ...[
            Text(
              'Completed Sections',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onSurfaceColor,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: completedSections
                  .map((section) => _buildSectionChip(
                        context,
                        section,
                        isCompleted: true,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Missing sections
          if (missingSections.isNotEmpty) ...[
            Text(
              'Add More Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onSurfaceColor,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingSections
                  .map((section) => _buildSectionChip(
                        context,
                        section,
                        isCompleted: false,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionChip(
    BuildContext context,
    String label, {
    required bool isCompleted,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00D95F)
              : context.outlineColor,
        ),
        color: isCompleted
            ? const Color(0xFF00D95F).withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.add_circle_outline,
            size: 14,
            color: isCompleted
                ? const Color(0xFF00D95F)
                : context.onSurfaceVariantColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isCompleted
                      ? const Color(0xFF00D95F)
                      : context.onSurfaceVariantColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
