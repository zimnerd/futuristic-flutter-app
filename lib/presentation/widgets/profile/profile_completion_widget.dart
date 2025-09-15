import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';

/// Widget that displays profile completion progress and highlights missing sections
class ProfileCompletionWidget extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onTapIncomplete;

  const ProfileCompletionWidget({
    super.key,
    this.profile,
    this.onTapIncomplete,
  });

  @override
  Widget build(BuildContext context) {
    final completion = _calculateCompletion();
    
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            completion.isComplete 
                ? PulseColors.success.withValues(alpha: 0.1)
                : PulseColors.warning.withValues(alpha: 0.1),
            completion.isComplete
                ? PulseColors.success.withValues(alpha: 0.05)
                : PulseColors.warning.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: completion.isComplete 
              ? PulseColors.success.withValues(alpha: 0.3)
              : PulseColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(completion),
          const SizedBox(height: PulseSpacing.md),
          _buildProgressBar(completion),
          if (!completion.isComplete) ...[
            const SizedBox(height: PulseSpacing.lg),
            _buildMissingSections(completion),
          ],
          if (completion.isComplete) ...[
            const SizedBox(height: PulseSpacing.md),
            _buildCompleteMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileCompletion completion) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(PulseSpacing.sm),
          decoration: BoxDecoration(
            color: completion.isComplete 
                ? PulseColors.success
                : PulseColors.warning,
            borderRadius: BorderRadius.circular(PulseRadii.md),
          ),
          child: Icon(
            completion.isComplete ? Icons.check_circle : Icons.trending_up,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: PulseSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                completion.isComplete 
                    ? 'Profile Complete!' 
                    : 'Complete Your Profile',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: PulseColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                completion.isComplete
                    ? 'Your profile is fully optimized'
                    : 'Get more matches with a complete profile',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${completion.percentage}%',
          style: PulseTextStyles.headlineSmall.copyWith(
            color: completion.isComplete 
                ? PulseColors.success
                : PulseColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ProfileCompletion completion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Strength',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _getStrengthLabel(completion.percentage),
              style: PulseTextStyles.bodyMedium.copyWith(
                color: completion.isComplete 
                    ? PulseColors.success
                    : PulseColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: PulseSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(PulseRadii.sm),
          child: LinearProgressIndicator(
            value: completion.percentage / 100,
            backgroundColor: PulseColors.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              completion.isComplete 
                  ? PulseColors.success
                  : PulseColors.warning,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingSections(ProfileCompletion completion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete these sections to boost your profile:',
          style: PulseTextStyles.titleMedium.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.sm),
        ...completion.missingSections.map((section) => _buildMissingSection(section)),
        if (onTapIncomplete != null) ...[
          const SizedBox(height: PulseSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTapIncomplete,
              icon: const Icon(Icons.edit),
              label: const Text('Complete Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PulseColors.warning,
                side: BorderSide(color: PulseColors.warning),
                padding: const EdgeInsets.all(PulseSpacing.md),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMissingSection(ProfileSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: PulseSpacing.sm),
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(PulseRadii.md),
        border: Border.all(
          color: PulseColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            section.icon,
            color: PulseColors.warning,
            size: 20,
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  section.description,
                  style: PulseTextStyles.bodySmall.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PulseSpacing.sm,
              vertical: PulseSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: PulseColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(PulseRadii.sm),
            ),
            child: Text(
              '+${section.points}%',
              style: PulseTextStyles.labelSmall.copyWith(
                color: PulseColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteMessage() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: PulseColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PulseRadii.md),
        border: Border.all(
          color: PulseColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.celebration,
            color: PulseColors.success,
            size: 24,
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Text(
              'Your profile is complete and optimized for better matches!',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStrengthLabel(int percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 70) return 'Good';
    if (percentage >= 50) return 'Fair';
    return 'Needs Work';
  }

  ProfileCompletion _calculateCompletion() {
    if (profile == null) {
      return ProfileCompletion(
        percentage: 0,
        isComplete: false,
        missingSections: _getAllSections(),
      );
    }

    final List<ProfileSection> missingSections = [];
    int totalPoints = 0;
    int earnedPoints = 0;

    // Basic info (30 points)
    final basicInfoSection = ProfileSection(
      id: 'basic_info',
      title: 'Basic Information',
      description: 'Complete your name, age, and bio',
      icon: Icons.person,
      points: 30,
    );
    totalPoints += basicInfoSection.points;
    
    if (profile!.name.isNotEmpty && 
        profile!.age > 0 && 
        profile!.bio.isNotEmpty) {
      earnedPoints += basicInfoSection.points;
    } else {
      missingSections.add(basicInfoSection);
    }

    // Photos (25 points)
    final photosSection = ProfileSection(
      id: 'photos',
      title: 'Profile Photos',
      description: 'Add at least 2 attractive photos',
      icon: Icons.photo_camera,
      points: 25,
    );
    totalPoints += photosSection.points;
    
    if (profile!.photos.length >= 2) {
      earnedPoints += photosSection.points;
    } else {
      missingSections.add(photosSection);
    }

    // Work & Education (15 points)
    final workEducationSection = ProfileSection(
      id: 'work_education',
      title: 'Work & Education',
      description: 'Add your job, company, or school',
      icon: Icons.work,
      points: 15,
    );
    totalPoints += workEducationSection.points;
    
    if ((profile!.job?.isNotEmpty ?? false) || 
        (profile!.company?.isNotEmpty ?? false) ||
        (profile!.school?.isNotEmpty ?? false)) {
      earnedPoints += workEducationSection.points;
    } else {
      missingSections.add(workEducationSection);
    }

    // Interests (20 points)
    final interestsSection = ProfileSection(
      id: 'interests',
      title: 'Interests & Hobbies',
      description: 'Add at least 3 interests',
      icon: Icons.favorite,
      points: 20,
    );
    totalPoints += interestsSection.points;
    
    if (profile!.interests.length >= 3) {
      earnedPoints += interestsSection.points;
    } else {
      missingSections.add(interestsSection);
    }

    // Preferences (10 points)
    final preferencesSection = ProfileSection(
      id: 'preferences',
      title: 'Dating Preferences',
      description: 'Set your gender and looking for preferences',
      icon: Icons.tune,
      points: 10,
    );
    totalPoints += preferencesSection.points;
    
    if ((profile!.gender?.isNotEmpty ?? false) && 
        (profile!.lookingFor?.isNotEmpty ?? false)) {
      earnedPoints += preferencesSection.points;
    } else {
      missingSections.add(preferencesSection);
    }

    final percentage = totalPoints > 0 ? (earnedPoints * 100) ~/ totalPoints : 0;
    
    return ProfileCompletion(
      percentage: percentage,
      isComplete: percentage >= 100,
      missingSections: missingSections,
    );
  }

  List<ProfileSection> _getAllSections() {
    return [
      ProfileSection(
        id: 'basic_info',
        title: 'Basic Information',
        description: 'Complete your name, age, and bio',
        icon: Icons.person,
        points: 30,
      ),
      ProfileSection(
        id: 'photos',
        title: 'Profile Photos',
        description: 'Add at least 2 attractive photos',
        icon: Icons.photo_camera,
        points: 25,
      ),
      ProfileSection(
        id: 'work_education',
        title: 'Work & Education',
        description: 'Add your job, company, or school',
        icon: Icons.work,
        points: 15,
      ),
      ProfileSection(
        id: 'interests',
        title: 'Interests & Hobbies',
        description: 'Add at least 3 interests',
        icon: Icons.favorite,
        points: 20,
      ),
      ProfileSection(
        id: 'preferences',
        title: 'Dating Preferences',
        description: 'Set your gender and looking for preferences',
        icon: Icons.tune,
        points: 10,
      ),
    ];
  }
}

/// Data class representing profile completion status
class ProfileCompletion {
  final int percentage;
  final bool isComplete;
  final List<ProfileSection> missingSections;

  const ProfileCompletion({
    required this.percentage,
    required this.isComplete,
    required this.missingSections,
  });
}

/// Data class representing a profile section
class ProfileSection {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int points;

  const ProfileSection({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
  });
}