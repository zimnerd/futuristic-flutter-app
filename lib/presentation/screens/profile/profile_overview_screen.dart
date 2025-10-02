import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';
import '../../widgets/profile/profile_completion_widget.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../widgets/common/pulse_loading_widget.dart';

/// Enhanced profile overview screen with section-based editing and real user data
class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Load actual user profile from ProfileBloc
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // Handle loading state
        if (state.status == ProfileStatus.loading) {
          return const Scaffold(body: Center(child: PulseLoadingWidget()));
        }

        // Handle error state
        if (state.status == ProfileStatus.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.error ?? 'Failed to load profile'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProfileBloc>().add(LoadProfile()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final userProfile = state.profile;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'My Profile',
              style: PulseTextStyles.titleLarge.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: PulseColors.onSurface),
              onPressed: () => context.go('/profile'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: PulseColors.onSurface),
                onPressed: () {
                  context.go('/settings');
                },
                tooltip: 'Settings',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PulseSpacing.lg),
              child: Column(
                children: [
                  _buildProfileHeader(userProfile),
                  const SizedBox(height: PulseSpacing.xl),
                  ProfileCompletionWidget(
                    profile: userProfile,
                    onTapIncomplete: () {
                      _navigateToFirstIncompleteSection(userProfile);
                    },
                  ),
                  const SizedBox(height: PulseSpacing.xl),
                  _buildProfileSections(userProfile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserProfile? userProfile) {
    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseColors.primary.withValues(alpha: 0.1),
            PulseColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Profile Image - Show actual user photo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PulseColors.primary, PulseColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: userProfile.photos.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      userProfile.photos.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 50, color: Colors.white);
                      },
                    ),
                  )
                : const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: PulseSpacing.md),
          
          // Name and Age
          Text(
            '${userProfile.name}, ${userProfile.age}',
            style: PulseTextStyles.headlineMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: PulseColors.onSurfaceVariant,
              ),
              const SizedBox(width: PulseSpacing.xs),
              Text(
                userProfile.location.city ?? 'Unknown location',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          // Verification Badge
          if (userProfile.verified) ...[
            const SizedBox(height: PulseSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PulseSpacing.sm,
                vertical: PulseSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: PulseColors.success,
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: PulseSpacing.xs),
                  Text(
                    'Verified',
                    style: PulseTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildProfileSections(UserProfile? userProfile) {
    return Column(
      children: [
        _buildSection(
          title: 'Basic Information',
          icon: Icons.person,
          userProfile: userProfile,
          items: [
            _buildSectionItem('Name', userProfile?.name ?? 'Not set'),
            _buildSectionItem('Age', '${userProfile?.age ?? 0} years old'),
            _buildSectionItem('Bio', userProfile?.bio ?? 'No bio added'),
          ],
          onEdit: () => _navigateToSectionEdit('basic_info', userProfile),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Photos',
          icon: Icons.photo_library,
          userProfile: userProfile,
          items: [
            _buildPhotoGrid(userProfile),
          ],
          onEdit: () => _navigateToSectionEdit('photos', userProfile),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Work & Education',
          icon: Icons.work,
          userProfile: userProfile,
          items: [
            _buildSectionItem('Job', userProfile?.job ?? 'Not specified'),
            _buildSectionItem(
              'Company',
              userProfile?.company ?? 'Not specified',
            ),
            _buildSectionItem('School', userProfile?.school ?? 'Not specified'),
          ],
          onEdit: () => _navigateToSectionEdit('work_education', userProfile),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Interests',
          icon: Icons.favorite,
          userProfile: userProfile,
          items: [
            _buildInterestsDisplay(userProfile),
          ],
          onEdit: () => _navigateToSectionEdit('interests', userProfile),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Dating Preferences',
          icon: Icons.tune,
          userProfile: userProfile,
          items: [
            _buildSectionItem('I am', userProfile?.gender ?? 'Not specified'),
            _buildSectionItem(
              'Looking for',
              userProfile?.lookingFor ?? 'Not specified',
            ),
          ],
          onEdit: () => _navigateToSectionEdit('preferences', userProfile),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required UserProfile? userProfile,
    required List<Widget> items,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: PulseColors.outline.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(PulseSpacing.sm),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                ),
                child: Icon(
                  icon,
                  color: PulseColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: PulseSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: PulseTextStyles.titleLarge.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
                  foregroundColor: PulseColors.primary,
                  padding: const EdgeInsets.all(PulseSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                ),
                tooltip: 'Edit $title',
              ),
            ],
          ),
          const SizedBox(height: PulseSpacing.md),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSectionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PulseSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Text(
              value,
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(UserProfile? userProfile) {
    final photos = userProfile?.photos ?? [];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + 1, // +1 for add photo button
        itemBuilder: (context, index) {
          if (index < photos.length) {
            return Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: PulseSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PulseRadii.md),
                border: Border.all(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PulseRadii.md - 2),
                child: Image.network(
                  photos[index].url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: PulseColors.surfaceVariant,
                      child: const Icon(Icons.image, color: PulseColors.onSurfaceVariant),
                    );
                  },
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () => _navigateToSectionEdit('photos', userProfile),
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: PulseSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                  border: Border.all(
                    color: PulseColors.outline,
                    style: BorderStyle.solid,
                  ),
                  color: PulseColors.surfaceVariant,
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: PulseColors.onSurfaceVariant,
                  size: 32,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInterestsDisplay(UserProfile? userProfile) {
    final interests = userProfile?.interests ?? [];
    if (interests.isEmpty) {
      return Text(
        'No interests added',
        style: PulseTextStyles.bodyMedium.copyWith(
          color: PulseColors.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: PulseSpacing.sm,
      runSpacing: PulseSpacing.xs,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PulseSpacing.sm,
            vertical: PulseSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(PulseRadii.sm),
            border: Border.all(
              color: PulseColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            interest,
            style: PulseTextStyles.bodySmall.copyWith(
              color: PulseColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToSectionEdit(
    String sectionType,
    UserProfile? userProfile,
  ) async {
    final result = await context.push(
      '/profile-section-edit',
      extra: {
        'sectionType': sectionType,
        'initialData': _getSectionData(sectionType, userProfile),
      },
    );

    if (result != null && mounted) {
      // Reload profile after edit
      context.read<ProfileBloc>().add(LoadProfile());
    }
  }

  Map<String, dynamic> _getSectionData(
    String sectionType,
    UserProfile? userProfile,
  ) {
    if (userProfile == null) return {};

    switch (sectionType) {
      case 'basic_info':
        return {
          'name': userProfile.name,
          'age': userProfile.age,
          'bio': userProfile.bio,
        };
      case 'work_education':
        return {
          'job': userProfile.job,
          'company': userProfile.company,
          'school': userProfile.school,
        };
      case 'interests':
        return {
          'interests': userProfile.interests,
        };
      case 'preferences':
        return {
          'gender': userProfile.gender,
          'lookingFor': userProfile.lookingFor,
        };
      default:
        return {};
    }
  }

  void _navigateToFirstIncompleteSection(UserProfile? userProfile) {
    if (userProfile == null) return;

    // Basic info check
    if (userProfile.name.isEmpty ||
        userProfile.age <= 0 ||
        userProfile.bio.isEmpty) {
      _navigateToSectionEdit('basic_info', userProfile);
      return;
    }

    // Photos check
    if (userProfile.photos.length < 2) {
      _navigateToSectionEdit('photos', userProfile);
      return;
    }

    // Work & Education check
    if ((userProfile.job?.isEmpty ?? true) &&
        (userProfile.company?.isEmpty ?? true) &&
        (userProfile.school?.isEmpty ?? true)) {
      _navigateToSectionEdit('work_education', userProfile);
      return;
    }

    // Interests check
    if (userProfile.interests.length < 3) {
      _navigateToSectionEdit('interests', userProfile);
      return;
    }

    // Preferences check
    if ((userProfile.gender?.isEmpty ?? true) ||
        (userProfile.lookingFor?.isEmpty ?? true)) {
      _navigateToSectionEdit('preferences', userProfile);
      return;
    }

    // If all complete, go to basic info as fallback
    _navigateToSectionEdit('basic_info', userProfile);
  }
}
