import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../../../services/profile_draft_service.dart';

/// Dialog for handling profile creation exit with draft saving
class ProfileExitDialog extends StatelessWidget {
  final ProfileDraft? currentDraft;
  final VoidCallback onSaveAndExit;
  final VoidCallback onExitWithoutSaving;
  final VoidCallback onContinueEditing;

  const ProfileExitDialog({
    super.key,
    this.currentDraft,
    required this.onSaveAndExit,
    required this.onExitWithoutSaving,
    required this.onContinueEditing,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = currentDraft != null && !currentDraft!.isEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.lg),
      ),
      contentPadding: const EdgeInsets.all(PulseSpacing.xl),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: hasProgress
                  ? PulseColors.warning.withValues(alpha: 0.1)
                  : PulseColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            child: Icon(
              hasProgress ? Icons.save_alt : Icons.exit_to_app,
              color: hasProgress ? PulseColors.warning : PulseColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Text(
              hasProgress ? 'Save Your Progress?' : 'Exit Profile Creation?',
              style: PulseTextStyles.titleLarge.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasProgress) ...[
            Text(
              'You\'ve made progress on your profile! We can save your work so you can continue later.',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            _buildProgressSummary(),
          ] else ...[
            Text(
              'Are you sure you want to exit? Any progress will be lost.',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (hasProgress) ...[
          TextButton(
            onPressed: onExitWithoutSaving,
            child: Text(
              'Don\'t Save',
              style: TextStyle(color: PulseColors.error),
            ),
          ),
          TextButton(
            onPressed: onContinueEditing,
            child: Text(
              'Continue',
              style: TextStyle(color: PulseColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onSaveAndExit,
            icon: const Icon(Icons.save),
            label: const Text('Save & Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.warning,
              foregroundColor: Colors.white,
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: onContinueEditing,
            child: Text(
              'Continue',
              style: TextStyle(color: PulseColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: onExitWithoutSaving,
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSummary() {
    if (currentDraft == null) return const SizedBox.shrink();

    final progress = (currentDraft!.completionPercentage * 100).round();

    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(PulseRadii.md),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Progress',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$progress%',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: PulseSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(PulseRadii.sm),
            child: LinearProgressIndicator(
              value: currentDraft!.completionPercentage,
              backgroundColor: PulseColors.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Step ${currentDraft!.currentStep + 1} of 5',
            style: PulseTextStyles.bodySmall.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for restoring a saved draft
class ProfileDraftRestoreDialog extends StatelessWidget {
  final ProfileDraft draft;
  final VoidCallback onRestore;
  final VoidCallback onStartFresh;

  const ProfileDraftRestoreDialog({
    super.key,
    required this.draft,
    required this.onRestore,
    required this.onStartFresh,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.lg),
      ),
      contentPadding: const EdgeInsets.all(PulseSpacing.xl),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            child: const Icon(
              Icons.restore,
              color: PulseColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Text(
              'Continue Where You Left Off?',
              style: PulseTextStyles.titleLarge.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We found your saved progress from ${draft.timeSinceLastSave}. Would you like to continue where you left off?',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PulseSpacing.lg),
          _buildDraftSummary(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onStartFresh,
          child: Text(
            'Start Fresh',
            style: TextStyle(color: PulseColors.onSurfaceVariant),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onRestore,
          icon: const Icon(Icons.restore),
          label: const Text('Continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PulseColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDraftSummary() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(PulseRadii.md),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Progress',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(draft.completionPercentage * 100).round()}% complete',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: PulseSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(PulseRadii.sm),
            child: LinearProgressIndicator(
              value: draft.completionPercentage,
              backgroundColor: PulseColors.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: PulseSpacing.md),
          _buildCompletedItems(),
        ],
      ),
    );
  }

  Widget _buildCompletedItems() {
    final List<String> completedItems = [];

    if (draft.name?.isNotEmpty == true) completedItems.add('Name');
    if (draft.age != null && draft.age! > 0) completedItems.add('Age');
    if (draft.bio?.isNotEmpty == true) completedItems.add('Bio');
    if (draft.photos.isNotEmpty)
     {
      completedItems.add('Photos (${draft.photos.length})');
    }
    if (draft.interests.isNotEmpty)
      {
      completedItems.add('Interests (${draft.interests.length})');
    }
    if (draft.gender?.isNotEmpty == true) {
      completedItems.add('Gender');
    }
    if (draft.lookingFor?.isNotEmpty == true) {
      completedItems.add('Looking for');
    }

    if (completedItems.isEmpty) {
      return Text(
        'Step ${draft.currentStep + 1} of 5',
        style: PulseTextStyles.bodySmall.copyWith(
          color: PulseColors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed:',
          style: PulseTextStyles.bodySmall.copyWith(
            color: PulseColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.xs),
        Wrap(
          spacing: PulseSpacing.xs,
          runSpacing: PulseSpacing.xs,
          children: completedItems
              .map(
                (item) => Chip(
                  label: Text(
                    item,
                    style: PulseTextStyles.labelSmall.copyWith(
                      color: PulseColors.primary,
                    ),
                  ),
                  backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
