import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';

/// Widget that displays profile completion progress and missing fields
class ProfileCompletionCard extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onTapIncomplete;

  const ProfileCompletionCard({
    super.key,
    this.profile,
    this.onTapIncomplete,
  });

  @override
  Widget build(BuildContext context) {
    final completionData = _calculateCompletion(profile);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withValues(alpha: 0.1),
            PulseColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  completionData.isComplete 
                    ? Icons.verified_user
                    : Icons.trending_up,
                  color: PulseColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completionData.isComplete 
                        ? 'Profile Complete!' 
                        : 'Complete Your Profile',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${completionData.percentage}% complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!completionData.isComplete)
                Text(
                  '${completionData.missingFields.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completionData.percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [PulseColors.primary, PulseColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          if (!completionData.isComplete) ...[
            const SizedBox(height: 16),
            Text(
              'Missing items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: completionData.missingFields.map((field) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFieldIcon(field),
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        field,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTapIncomplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: PulseColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PulseColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: PulseColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your profile is looking great!',
                    style: TextStyle(
                      color: PulseColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  ProfileCompletionData _calculateCompletion(UserProfile? profile) {
    if (profile == null) {
      return ProfileCompletionData(
        percentage: 0,
        isComplete: false,
        missingFields: _getAllRequiredFields(),
      );
    }

    final missingFields = <String>[];
    
    // Check required fields
    if (profile.name.isEmpty) missingFields.add('Name');
    if (profile.bio.isEmpty) missingFields.add('Bio');
    if (profile.photos.isEmpty) missingFields.add('Photos');
    if (profile.interests.isEmpty) missingFields.add('Interests');
    if (profile.job?.isEmpty ?? true) missingFields.add('Job');
    if (profile.school?.isEmpty ?? true) missingFields.add('Education');
    if (profile.gender?.isEmpty ?? true) missingFields.add('Gender');
    if (profile.relationshipGoals.isEmpty) {
      missingFields.add('Relationship Goals');
    }
    
    // Check photo requirements (minimum 2 photos recommended)
    if (profile.photos.length < 2) {
      missingFields.add('More Photos (${2 - profile.photos.length} needed)');
    }
    
    // Check interests (minimum 3 recommended)
    if (profile.interests.length < 3) {
      missingFields.add('More Interests (${3 - profile.interests.length} needed)');
    }

    final totalFields = _getAllRequiredFields().length;
    final completedFields = totalFields - missingFields.length;
    final percentage = ((completedFields / totalFields) * 100).round();
    
    return ProfileCompletionData(
      percentage: percentage.clamp(0, 100),
      isComplete: missingFields.isEmpty,
      missingFields: missingFields,
    );
  }

  List<String> _getAllRequiredFields() {
    return [
      'Name',
      'Bio', 
      'Photos',
      'More Photos',
      'Interests',
      'More Interests',
      'Job',
      'Education',
      'Gender',
      'Looking For',
    ];
  }

  IconData _getFieldIcon(String field) {
    switch (field.toLowerCase()) {
      case 'name':
        return Icons.person;
      case 'bio':
        return Icons.description;
      case 'photos':
      case 'more photos':
        return Icons.photo_camera;
      case 'interests':
      case 'more interests':
        return Icons.favorite;
      case 'job':
        return Icons.work;
      case 'education':
        return Icons.school;
      case 'gender':
        return Icons.wc;
      case 'looking for':
        return Icons.search;
      default:
        return Icons.info;
    }
  }
}

/// Data class for profile completion information
class ProfileCompletionData {
  final int percentage;
  final bool isComplete;
  final List<String> missingFields;

  const ProfileCompletionData({
    required this.percentage,
    required this.isComplete,
    required this.missingFields,
  });
}
