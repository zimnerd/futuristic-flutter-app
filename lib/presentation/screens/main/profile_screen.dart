import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';
import '../../widgets/profile/profile_completion_widget.dart';
import '../../widgets/profile/verification_cta_banner.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/verification/verification_badge.dart';

/// Main profile screen - Landing page when user clicks profile from menu
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load actual user profile from ProfileBloc (use cache if available)
    context.read<ProfileBloc>().add(const LoadProfile());
    // Load real stats from API
    context.read<ProfileBloc>().add(const LoadProfileStats());
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
                        context.read<ProfileBloc>().add(const LoadProfile(forceRefresh: true)),
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
            automaticallyImplyLeading: false,
            actions: [
              // Settings icon - access to settings, filters, premium, etc.
              IconButton(
                icon: const Icon(Icons.settings, color: PulseColors.onSurface),
                onPressed: () => context.push('/settings'),
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
                  const SizedBox(height: PulseSpacing.md),
                  _buildCompactStats(userProfile),
                  const SizedBox(height: PulseSpacing.xl),

                  // QUICK WIN: Verification CTA for unverified users
                  if (userProfile != null && !userProfile.verified)
                    const VerificationCTABanner(),

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
          const SizedBox(height: PulseSpacing.sm),
          VerificationBadge(
            isVerified: userProfile.verified,
            size: VerificationBadgeSize.medium,
            showLabel: true,
          ),
          
          // Edit Profile Button
          const SizedBox(height: PulseSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/profile-edit');
              },
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: PulseSpacing.lg,
                  vertical: PulseSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(UserProfile? userProfile) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // Show loading shimmer while fetching stats
        if (state.statsStatus == ProfileStatus.loading || state.stats == null) {
          return Row(
            children: [
              Expanded(child: _buildStatsLoadingSkeleton()),
              const SizedBox(width: PulseSpacing.sm),
              Expanded(child: _buildStatsLoadingSkeleton()),
              const SizedBox(width: PulseSpacing.sm),
              Expanded(child: _buildStatsLoadingSkeleton()),
            ],
          );
        }

        // Display real stats from API
        final stats = state.stats!;
        // QUICK WIN: Make all stats tappable to view full statistics
        return GestureDetector(
          onTap: () => context.push('/statistics'),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      value: '${stats.matchesCount}',
                      label: 'Matches',
                      colors: [
                        PulseColors.error,
                        PulseColors.error.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  const SizedBox(width: PulseSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.thumb_up,
                      value: '${stats.likesReceived}',
                      label: 'Likes',
                      colors: [
                        PulseColors.secondary,
                        PulseColors.secondary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  const SizedBox(width: PulseSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to profile viewers screen (premium feature)
                        context.push('/profile-viewers');
                      },
                      child: _buildStatCard(
                        icon: Icons.visibility,
                        value: '${stats.profileViews}',
                        label: 'Visits',
                        colors: [
                          PulseColors.primary,
                          PulseColors.primary.withValues(alpha: 0.7),
                        ],
                        showTapHint: true,
                        isPremium: true,  // Show premium badge
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PulseSpacing.sm),
              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: PulseColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view full statistics',
                    style: PulseTextStyles.labelSmall.copyWith(
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> colors,
    bool showTapHint = false,
    bool isPremium = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: PulseColors.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (isPremium)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: PulseSpacing.xs),
          Text(
            value,
            style: PulseTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: PulseTextStyles.labelSmall.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
              if (showTapHint) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: PulseColors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(color: PulseColors.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
          ),
          const SizedBox(height: PulseSpacing.xs),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
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
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Photos',
          icon: Icons.photo_library,
          userProfile: userProfile,
          items: [
            _buildPhotoGrid(userProfile),
          ],
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
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Interests',
          icon: Icons.favorite,
          userProfile: userProfile,
          items: [
            _buildInterestsDisplay(userProfile),
          ],
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Dating Preferences',
          icon: Icons.tune,
          userProfile: userProfile,
          items: [
            _buildSectionItem('I am', userProfile?.gender ?? 'Not specified'),
            _buildSectionItem(
              'Show me', _formatShowMe(userProfile?.showMe),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required UserProfile? userProfile,
    required List<Widget> items,
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

  String _formatShowMe(List<String>? showMeArray) {
    if (showMeArray == null || showMeArray.isEmpty) {
      return 'Not specified';
    }

    final upperArray = showMeArray.map((s) => s.toUpperCase()).toList();

    if (upperArray.contains('MEN') && upperArray.contains('WOMEN')) {
      return 'Everyone';
    }
    if (upperArray.contains('MEN')) return 'Men';
    if (upperArray.contains('WOMEN')) return 'Women';

    return 'Not specified';
  }

  Widget _buildPhotoGrid(UserProfile? userProfile) {
    final photos = userProfile?.photos ?? [];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
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
      // Handle returned form data and update profile
      final formData = result as Map<String, dynamic>;

      // Handle photo uploads separately if present
      if (formData.containsKey('newPhotos')) {
        final newPhotos = formData['newPhotos'] as List<dynamic>?;
        if (newPhotos != null && newPhotos.isNotEmpty) {
          for (final photo in newPhotos) {
            if (photo is File) {
              context.read<ProfileBloc>().add(UploadPhoto(photoPath: photo.path));
            } else if (photo is String) {
              context.read<ProfileBloc>().add(UploadPhoto(photoPath: photo));
            }
          }
        }
      }

      if (userProfile != null) {
        // Create updated profile with merged data (excluding photos - handled separately)
        final updatedProfile = userProfile.copyWith(
          name: formData['name'] as String?,
          dateOfBirth: formData['dateOfBirth'] as DateTime?,
          bio: formData['bio'] as String?,
          job: formData['job'] as String?,
          company: formData['company'] as String?,
          school: formData['school'] as String?,
          gender: formData['gender'] as String?,
          lookingFor: formData['lookingFor'] as String?,
          interests: formData['interests'] as List<String>?,
        );

        // Dispatch UpdateProfile event to save changes
        context.read<ProfileBloc>().add(UpdateProfile(profile: updatedProfile));
      }
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
          'dateOfBirth': userProfile.dateOfBirth,
          'ageChangeCount': userProfile.ageChangeCount,
          'bio': userProfile.bio,
        };
      case 'work_education':
        return {
          'job': userProfile.job,
          'company': userProfile.company,
          'school': userProfile.school,
        };
      case 'photos':
        return {
          'photos': userProfile.photos
              .map(
                (photo) => {
                  'id': photo.id,
                  'url': photo.url,
                  'description': photo.description,
                  'order': photo.order,
                  'isMain': photo.isVerified,
                },
              )
              .toList(),
        };
      case 'interests':
        return {
          'interests': userProfile.interests,
        };
      case 'preferences':
        return {
          'gender': userProfile.gender,
          'relationshipGoals': userProfile.relationshipGoals,
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
        (userProfile.relationshipGoals.isEmpty)) {
      _navigateToSectionEdit('preferences', userProfile);
      return;
    }

    // If all complete, go to basic info as fallback
    _navigateToSectionEdit('basic_info', userProfile);
  }
}
