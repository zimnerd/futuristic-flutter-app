import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';
import '../../widgets/profile/profile_completion_widget.dart';

/// Enhanced profile overview screen with section-based editing
class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  // Mock user data - in real app this would come from ProfileBloc
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    // Initialize with mock data - replace with actual profile loading
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // Mock profile data - in real app this would come from ProfileBloc
    _userProfile = UserProfile(
      id: 'user-123',
      name: 'John Doe',
      bio: 'Love traveling, coffee, and good conversations. Always up for an adventure!',
      age: 28,
      photos: [
        ProfilePhoto(id: '1', url: 'https://example.com/photo1.jpg', order: 0),
        ProfilePhoto(id: '2', url: 'https://example.com/photo2.jpg', order: 1),
      ],
      interests: ['Travel', 'Coffee', 'Photography', 'Hiking'],
      location: UserLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        city: 'San Francisco',
      ),
      gender: 'Man',
      job: 'Software Engineer',
      company: 'Tech Corp',
      school: 'Stanford University',
      lookingFor: 'Women',
      isOnline: true,
      lastSeen: DateTime.now(),
      verified: true,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: PulseColors.onSurface),
            onPressed: () {
              // Navigate to settings
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
              _buildProfileHeader(),
              const SizedBox(height: PulseSpacing.xl),
              ProfileCompletionWidget(
                profile: _userProfile,
                onTapIncomplete: () {
                  _navigateToFirstIncompleteSection();
                },
              ),
              const SizedBox(height: PulseSpacing.xl),
              _buildProfileSections(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/profile-creation');
        },
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Full Edit'),
        tooltip: 'Edit entire profile',
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_userProfile == null) {
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
          // Profile Image
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
            child: _userProfile!.photos.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _userProfile!.photos.first.url,
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
            '${_userProfile!.name}, ${_userProfile!.age}',
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
                _userProfile!.location.city ?? 'Unknown location',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          // Verification Badge
          if (_userProfile!.verified) ...[
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

  Widget _buildProfileSections() {
    return Column(
      children: [
        _buildSection(
          title: 'Basic Information',
          icon: Icons.person,
          items: [
            _buildSectionItem('Name', _userProfile?.name ?? 'Not set'),
            _buildSectionItem('Age', '${_userProfile?.age ?? 0} years old'),
            _buildSectionItem('Bio', _userProfile?.bio ?? 'No bio added'),
          ],
          onEdit: () => _navigateToSectionEdit('basic_info'),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Photos',
          icon: Icons.photo_library,
          items: [
            _buildPhotoGrid(),
          ],
          onEdit: () => _navigateToPhotoEdit(),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Work & Education',
          icon: Icons.work,
          items: [
            _buildSectionItem('Job', _userProfile?.job ?? 'Not specified'),
            _buildSectionItem('Company', _userProfile?.company ?? 'Not specified'),
            _buildSectionItem('School', _userProfile?.school ?? 'Not specified'),
          ],
          onEdit: () => _navigateToSectionEdit('work_education'),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Interests',
          icon: Icons.favorite,
          items: [
            _buildInterestsDisplay(),
          ],
          onEdit: () => _navigateToSectionEdit('interests'),
        ),
        const SizedBox(height: PulseSpacing.lg),
        
        _buildSection(
          title: 'Dating Preferences',
          icon: Icons.tune,
          items: [
            _buildSectionItem('I am', _userProfile?.gender ?? 'Not specified'),
            _buildSectionItem('Looking for', _userProfile?.lookingFor ?? 'Not specified'),
          ],
          onEdit: () => _navigateToSectionEdit('preferences'),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
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

  Widget _buildPhotoGrid() {
    final photos = _userProfile?.photos ?? [];
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
            return Container(
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
            );
          }
        },
      ),
    );
  }

  Widget _buildInterestsDisplay() {
    final interests = _userProfile?.interests ?? [];
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

  void _navigateToSectionEdit(String sectionType) async {
    final result = await context.push(
      '/profile-section-edit',
      extra: {
        'sectionType': sectionType,
        'initialData': _getSectionData(sectionType),
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      // Update the profile with new data
      setState(() {
        _updateProfileSection(sectionType, result);
      });
    }
  }

  void _navigateToPhotoEdit() {
    // Navigate to photo editing screen (could reuse profile creation photo step)
    context.go('/profile-creation?step=0'); // Photo step
  }

  Map<String, dynamic> _getSectionData(String sectionType) {
    if (_userProfile == null) return {};

    switch (sectionType) {
      case 'basic_info':
        return {
          'name': _userProfile!.name,
          'age': _userProfile!.age,
          'bio': _userProfile!.bio,
        };
      case 'work_education':
        return {
          'job': _userProfile!.job,
          'company': _userProfile!.company,
          'school': _userProfile!.school,
        };
      case 'interests':
        return {
          'interests': _userProfile!.interests,
        };
      case 'preferences':
        return {
          'gender': _userProfile!.gender,
          'lookingFor': _userProfile!.lookingFor,
        };
      default:
        return {};
    }
  }

  void _updateProfileSection(String sectionType, Map<String, dynamic> newData) {
    if (_userProfile == null) return;

    switch (sectionType) {
      case 'basic_info':
        _userProfile = _userProfile!.copyWith(
          name: newData['name'] ?? _userProfile!.name,
          age: newData['age'] ?? _userProfile!.age,
          bio: newData['bio'] ?? _userProfile!.bio,
        );
        break;
      case 'work_education':
        _userProfile = _userProfile!.copyWith(
          job: newData['job'],
          company: newData['company'],
          school: newData['school'],
        );
        break;
      case 'interests':
        _userProfile = _userProfile!.copyWith(
          interests: List<String>.from(newData['interests'] ?? []),
        );
        break;
      case 'preferences':
        _userProfile = _userProfile!.copyWith(
          gender: newData['gender'],
          lookingFor: newData['lookingFor'],
        );
        break;
    }

    // In a real app, you would also dispatch an event to ProfileBloc here
    // context.read<ProfileBloc>().add(UpdateProfile(profile: _userProfile!));
  }

  void _navigateToFirstIncompleteSection() {
    // Determine which section to navigate to first
    if (_userProfile == null) return;

    // Basic info check
    if (_userProfile!.name.isEmpty || _userProfile!.age <= 0 || _userProfile!.bio.isEmpty) {
      context.go('/profile-edit/basic_info');
      return;
    }

    // Photos check
    if (_userProfile!.photos.length < 2) {
      context.go('/profile-creation'); // For photo upload
      return;
    }

    // Work & Education check
    if ((_userProfile!.job?.isEmpty ?? true) && 
        (_userProfile!.company?.isEmpty ?? true) && 
        (_userProfile!.school?.isEmpty ?? true)) {
      context.go('/profile-edit/work_education');
      return;
    }

    // Interests check
    if (_userProfile!.interests.length < 3) {
      context.go('/profile-edit/interests');
      return;
    }

    // Preferences check
    if ((_userProfile!.gender?.isEmpty ?? true) || (_userProfile!.lookingFor?.isEmpty ?? true)) {
      context.go('/profile-edit/preferences');
      return;
    }

    // If all complete, go to basic info as fallback
    context.go('/profile-edit/basic_info');
  }
}