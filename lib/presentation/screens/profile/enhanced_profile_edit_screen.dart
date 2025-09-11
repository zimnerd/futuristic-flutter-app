import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/profile/enhanced_photo_grid.dart';
import '../../widgets/profile/profile_completion_card.dart';
import '../../widgets/profile/profile_privacy_settings.dart';
import '../../widgets/profile/profile_preview.dart';
import '../../widgets/profile/interests_selector.dart';
import '../../../domain/entities/user_profile.dart';

/// Enhanced profile editing screen with all new features
class EnhancedProfileEditScreen extends StatefulWidget {
  const EnhancedProfileEditScreen({super.key});

  @override
  State<EnhancedProfileEditScreen> createState() => _EnhancedProfileEditScreenState();
}

class _EnhancedProfileEditScreenState extends State<EnhancedProfileEditScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();

  // Profile data
  List<String> _selectedInterests = [];
  String _selectedGender = 'Woman';
  String _selectedPreference = 'Men';
  List<ProfilePhoto> _photos = [];
  Map<String, bool> _privacySettings = Map.from({
    'showDistance': true,
    'showAge': true,
    'showLastActive': true,
    'showOnlineStatus': true,
    'discoverable': true,
    'readReceipts': true,
    'showVerification': true,
  });

  UserProfile? _currentProfile;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _ageController.text = profile.age.toString();
    _jobController.text = profile.job ?? '';
    _companyController.text = profile.company ?? '';
    _schoolController.text = profile.school ?? '';
    _selectedInterests = List.from(profile.interests);
    _selectedGender = profile.gender ?? 'Woman';
    _photos = List.from(profile.photos);
    _currentProfile = profile;
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProfile = UserProfile(
        id: _currentProfile?.id ?? 'current_user_id',
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 18,
        photos: _photos,
        interests: _selectedInterests,
        location: _currentProfile?.location ?? UserLocation(
          latitude: 0.0,
          longitude: 0.0,
          city: 'Current City',
        ),
        gender: _selectedGender,
        job: _jobController.text.trim(),
        company: _companyController.text.trim(),
        school: _schoolController.text.trim(),
        lookingFor: _selectedPreference,
        isOnline: true,
        lastSeen: DateTime.now(),
        verified: _currentProfile?.verified ?? false,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: updatedProfile));
    }
  }

  void _showPreview() {
    if (_currentProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfilePreview(
            profile: _buildPreviewProfile(),
            onClose: () => Navigator.of(context).pop(),
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  UserProfile _buildPreviewProfile() {
    return UserProfile(
      id: _currentProfile?.id ?? 'preview',
      name: _nameController.text.trim().isEmpty ? 'Your Name' : _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? 'Your bio will appear here...' : _bioController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 25,
      photos: _photos.isEmpty ? [
        ProfilePhoto(
          id: 'placeholder',
          url: 'https://via.placeholder.com/400x600/6E3BFF/FFFFFF?text=Add+Photo',
          order: 0,
        )
      ] : _photos,
      interests: _selectedInterests,
      location: _currentProfile?.location ?? UserLocation(
        latitude: 0.0,
        longitude: 0.0,
        city: 'Current City',
      ),
      gender: _selectedGender,
      job: _jobController.text.trim(),
      company: _companyController.text.trim(),
      school: _schoolController.text.trim(),
      lookingFor: _selectedPreference,
      isOnline: true,
      lastSeen: DateTime.now(),
      verified: _currentProfile?.verified ?? false,
    );
  }

  void _nextPage() {
    if (_currentPageIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _showPreview,
            child: Text(
              'Preview',
              style: TextStyle(
                color: PulseColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 70),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              indicator: BoxDecoration(
                color: PulseColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.info, size: 18),
                  text: 'Basic Info',
                ),
                Tab(
                  icon: Icon(Icons.photo_camera, size: 18),
                  text: 'Photos',
                ),
                Tab(
                  icon: Icon(Icons.favorite, size: 18),
                  text: 'Interests',
                ),
                Tab(
                  icon: Icon(Icons.privacy_tip, size: 18),
                  text: 'Privacy',
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.loaded && state.profile != null) {
            _populateFields(state.profile!);
          }
          if (state.updateStatus == ProfileStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: PulseColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state.updateStatus == ProfileStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Failed to update profile'),
                backgroundColor: PulseColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Profile completion card
              if (_currentProfile != null)
                ProfileCompletionCard(
                  profile: _buildPreviewProfile(),
                  onTapIncomplete: () => _tabController.animateTo(0),
                ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildBasicInfoPage(),
                    _buildPhotosPage(),
                    _buildInterestsPage(),
                    _buildPrivacyPage(),
                  ],
                ),
              ),

              // Bottom navigation
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentPageIndex > 0)
                      Expanded(
                        child: PulseButton(
                          text: 'Previous',
                          onPressed: _previousPage,
                          variant: PulseButtonVariant.secondary,
                        ),
                      ),
                    if (_currentPageIndex > 0 && _currentPageIndex < 3)
                      const SizedBox(width: 12),
                    Expanded(
                      child: PulseButton(
                        text: _currentPageIndex == 3 ? 'Save Profile' : 'Next',
                        onPressed: _currentPageIndex == 3 ? _saveProfile : _nextPage,
                        isLoading: state.updateStatus == ProfileStatus.loading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormField(
              'Name',
              _nameController,
              'Enter your name',
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              'Age',
              _ageController,
              'Enter your age',
              keyboardType: TextInputType.number,
              validator: (value) {
                final age = int.tryParse(value ?? '');
                if (age == null || age < 18 || age > 100) {
                  return 'Please enter a valid age (18-100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildFormField(
              'Bio',
              _bioController,
              'Tell people about yourself...',
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              'Job Title',
              _jobController,
              'What do you do?',
            ),
            const SizedBox(height: 20),
            _buildFormField(
              'Company',
              _companyController,
              'Where do you work?',
            ),
            const SizedBox(height: 20),
            _buildFormField(
              'Education',
              _schoolController,
              'Where did you study?',
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              'Gender',
              _selectedGender,
              ['Woman', 'Man', 'Non-binary', 'Other'],
              (value) => setState(() => _selectedGender = value!),
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              'Looking For',
              _selectedPreference,
              ['Men', 'Women', 'Everyone'],
              (value) => setState(() => _selectedPreference = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EnhancedPhotoGrid(
        photos: _photos,
        onPhotosChanged: (photos) {
          setState(() {
            _photos = photos;
          });
        },
        maxPhotos: 6,
        isEditing: true,
      ),
    );
  }

  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: InterestsSelector(
        selectedInterests: _selectedInterests,
        onInterestsChanged: (interests) {
          setState(() {
            _selectedInterests = interests;
          });
        },
        maxInterests: 10,
        minInterests: 3,
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProfilePrivacySettings(
        privacySettings: _privacySettings,
        onSettingsChanged: (settings) {
          setState(() {
            _privacySettings = settings;
          });
        },
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hintText, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: PulseColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: PulseColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: PulseColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}
