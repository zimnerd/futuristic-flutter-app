import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/profile/enhanced_photo_grid.dart';
import '../../widgets/profile/profile_completion_card.dart';
import '../../widgets/profile/profile_privacy_settings.dart';
import '../../widgets/profile/profile_preview.dart';
import '../../widgets/profile/interests_selector.dart';
import '../../widgets/profile/profile_lifestyle_section.dart';
import '../../widgets/profile/profile_relationship_goals_section.dart';
import '../../widgets/profile/profile_physical_attributes_section.dart';
import '../../widgets/profile/profile_lifestyle_choices_section.dart';
import '../../widgets/profile/profile_languages_section.dart';
import '../../../domain/entities/user_profile.dart';

// Logger instance for debugging
final logger = Logger();

/// Main profile editing screen with tabbed interface
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();

  // Profile data
  DateTime? _dateOfBirth;
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
  bool _isProfileCompletionExpanded = false; // Collapsed by default

  // Track dirty fields for delta updates
  final Set<String> _dirtyFields = {};
  
  // Temp upload tracking for PhotoManagerService integration
  final List<String> _tempPhotoUrls = [];
  final Set<String> _photosMarkedForDeletion = {};

  // New profile fields state
  String? _selectedLifestyle;
  List<String> _selectedRelationshipGoals = [];
  int? _selectedHeight; // No default - use real data or leave empty
  String? _selectedReligion;
  String? _selectedPolitics;
  String? _selectedDrinking;
  String? _selectedSmoking;
  String? _selectedDrugs;
  String? _selectedChildren;
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _dateOfBirth = profile.dateOfBirth;
    _jobController.text = profile.job ?? '';
    _companyController.text = profile.company ?? '';
    _schoolController.text = profile.school ?? '';
    _selectedInterests = List.from(profile.interests);
    
    // Normalize gender from backend format (MALE/FEMALE) to UI format (Man/Woman)
    _selectedGender = _normalizeGender(profile.gender) ?? 'Woman';
    _photos = List.from(profile.photos);
    
    // Populate new profile fields
    _selectedLifestyle = profile.lifestyleChoice;
    _selectedRelationshipGoals = List.from(profile.relationshipGoals);
    _selectedHeight = profile.height; // Use real data only
    _selectedReligion = profile.religion;
    _selectedPolitics = profile.politics;
    _selectedDrinking = profile.drinking;
    _selectedSmoking = profile.smoking;
    _selectedDrugs = profile.drugs;
    _selectedChildren = profile.children;
    _selectedLanguages = List.from(profile.languages);
    
    _currentProfile = profile;
  }
  
  /// Normalize gender from backend format to UI format
  String? _normalizeGender(String? backendGender) {
    if (backendGender == null) return null;

    switch (backendGender.toUpperCase()) {
      case 'MALE':
      case 'MAN':
        return 'Man';
      case 'FEMALE':
      case 'WOMAN':
        return 'Woman';
      case 'NON-BINARY':
      case 'NON_BINARY':
      case 'NONBINARY':
        return 'Non-binary';
      case 'OTHER':
        return 'Other';
      default:
        return backendGender; // Return as-is if already in correct format
    }
  }

  /// Handle adding new photo via BLoC event
  Future<void> _handleAddPhoto(File photoFile) async {
    logger.i('📸 User selected photo: ${photoFile.path}');
    logger.i('📤 Dispatching UploadPhoto event to BLoC');
    // Dispatch UploadPhoto event - PhotoManagerService will upload to temp storage
    context.read<ProfileBloc>().add(UploadPhoto(photoPath: photoFile.path));
    logger.i('✅ UploadPhoto event dispatched, waiting for BLoC response');
  }

  /// Handle deleting photo via BLoC event
  void _handleDeletePhoto(ProfilePhoto photo) {
    final photoUrl = photo.url;
    
    // Check if this is a temp photo (not yet saved)
    if (_tempPhotoUrls.contains(photoUrl)) {
      // Remove from temp list and local photos
      setState(() {
        _tempPhotoUrls.remove(photoUrl);
        _photos.removeWhere((p) => p.url == photoUrl);
      });
      // Temp photos don't need deletion event, they'll auto-cleanup
    } else {
      // Mark existing photo for deletion
      setState(() {
        _photosMarkedForDeletion.add(photoUrl);
        _photos.removeWhere((p) => p.url == photoUrl);
      });
      // Dispatch DeletePhoto event for backend tracking
      context.read<ProfileBloc>().add(DeletePhoto(photoUrl: photoUrl));
    }
  }

  void _saveProfile() {
    // Only validate form if we're on page 0 (Basic Info) which has the form
    // For other pages, skip validation since they don't use the form
    bool isValid = true;
    if (_currentPageIndex == 0) {
      isValid = _formKey.currentState?.validate() ?? false;
    }
    
    if (isValid) {
      final updatedProfile = UserProfile(
        id: _currentProfile?.id ?? 'current_user_id',
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: _calculateAge(
          _dateOfBirth ??
              DateTime.now().subtract(const Duration(days: 365 * 25)),
        ),
        dateOfBirth: _dateOfBirth,
        photos: _photos,
        interests: _selectedInterests,
        location: _currentProfile?.location ?? UserLocation(
          latitude: 0.0,
          longitude: 0.0,
          city: 'Current City',
        ),
        gender: _convertGenderToBackendFormat(_selectedGender),
        job: _jobController.text.trim(),
        company: _companyController.text.trim(),
        school: _schoolController.text.trim(),
        lookingFor: _selectedPreference,
        isOnline: true,
        lastSeen: DateTime.now(),
        verified: _currentProfile?.verified ?? false,
        // New lifestyle fields
        lifestyleChoice: _selectedLifestyle,
        relationshipGoals: _selectedRelationshipGoals,
        height: _selectedHeight,
        religion: _selectedReligion,
        politics: _selectedPolitics,
        drinking: _selectedDrinking,
        smoking: _selectedSmoking,
        drugs: _selectedDrugs,
        children: _selectedChildren,
        languages: _selectedLanguages,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: updatedProfile));
    }
  }
  
  /// Convert UI gender format back to backend format
  String? _convertGenderToBackendFormat(String? uiGender) {
    if (uiGender == null) return null;

    switch (uiGender) {
      case 'Man':
        return 'MALE';
      case 'Woman':
        return 'FEMALE';
      case 'Non-binary':
        return 'NON_BINARY';
      case 'Other':
        return 'OTHER';
      default:
        return uiGender; // Return as-is if unknown format
    }
  }

  /// Calculate age from date of birth
  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
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
      age: _calculateAge(
        _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      ),
      dateOfBirth: _dateOfBirth,
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
      // New lifestyle fields
      lifestyleChoice: _selectedLifestyle,
      relationshipGoals: _selectedRelationshipGoals,
      height: _selectedHeight,
      religion: _selectedReligion,
      politics: _selectedPolitics,
      drinking: _selectedDrinking,
      smoking: _selectedSmoking,
      drugs: _selectedDrugs,
      children: _selectedChildren,
      languages: _selectedLanguages,
    );
  }

  void _nextPage() {
    if (_currentPageIndex < 4) {
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
          IconButton(
            icon: Icon(
              Icons.visibility_outlined,
              color: PulseColors.primary,
              size: 28,
            ),
            onPressed: _showPreview,
            tooltip: 'Preview Profile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 65),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive sizing
                final screenWidth = constraints.maxWidth;
                final tabWidth = screenWidth / 5;
                final fontSize = tabWidth < 65
                    ? 9.0
                    : (tabWidth < 75 ? 10.0 : 11.0);
                final iconSize = tabWidth < 65 ? 18.0 : 20.0;

                return TabBar(
                  controller: _tabController,
                  isScrollable: false, // Fill width
                  onTap: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PulseColors.primary,
                        PulseColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: PulseColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.info_outline, size: iconSize),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                      text: 'Basic',
                    ),
                    Tab(
                      icon: Icon(Icons.photo_camera_outlined, size: iconSize),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                      text: 'Photos',
                    ),
                    Tab(
                      icon: Icon(Icons.favorite_outline, size: iconSize),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                      text: 'Interests',
                    ),
                    Tab(
                      icon: Icon(Icons.spa_outlined, size: iconSize),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                      text: 'Lifestyle',
                    ),
                    Tab(
                      icon: Icon(Icons.lock_outline, size: iconSize),
                      iconMargin: const EdgeInsets.only(bottom: 2),
                      text: 'Privacy',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.loaded && state.profile != null) {
            _populateFields(state.profile!);
          }
          
          // Handle photo upload success/error
          if (state.uploadStatus == ProfileStatus.success) {
            if (state.profile != null && state.profile!.photos.isNotEmpty) {
              // Get the last uploaded photo from BLoC (has proper mediaId and temp URL)
              final uploadedPhoto = state.profile!.photos.last;
              if (!_photos.any((p) => p.id == uploadedPhoto.id)) {
                setState(() {
                  _tempPhotoUrls.add(uploadedPhoto.url);
                  _photos.add(
                    uploadedPhoto,
                  ); // Use BLoC photo directly (has mediaId)
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo uploaded successfully!'),
                    backgroundColor: PulseColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else if (state.uploadStatus == ProfileStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload photo: ${state.error ?? "Unknown error"}'),
                backgroundColor: PulseColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
          if (state.updateStatus == ProfileStatus.success) {
            logger.i('🎯 Profile update successful, navigating to /profile');
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: PulseColors.success,
              ),
            );
            // Navigate explicitly to profile screen (not discover page)
            logger.i('🚀 Executing context.go("/profile")');
            context.go('/profile');
            logger.i('✅ Navigation command sent');
            // Reload profile to refresh display with new data
            Future.delayed(const Duration(milliseconds: 100), () {
              logger.i('🔄 Reloading profile after navigation');
              context.read<ProfileBloc>().add(LoadProfile());
            });
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
              // Profile completion card (collapsible)
              if (_currentProfile != null)
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isProfileCompletionExpanded =
                                !_isProfileCompletionExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: PulseColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Complete Your Profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: PulseColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _isProfileCompletionExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: PulseColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isProfileCompletionExpanded)
                        ProfileCompletionCard(
                          profile: _buildPreviewProfile(),
                          onTapIncomplete: () => _tabController.animateTo(0),
                        ),
                    ],
                  ),
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
                    _buildLifestylePage(),
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
                    if (_currentPageIndex > 0 && _currentPageIndex < 4)
                      const SizedBox(width: 12),
                    Expanded(
                      child: PulseButton(
                        text: _currentPageIndex == 4 ? 'Save Profile' : 'Next',
                        onPressed: _currentPageIndex == 4
                            ? _saveProfile
                            : _nextPage,
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
            // Date of Birth Picker
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _dateOfBirth ??
                      DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now().subtract(
                    const Duration(days: 365 * 18),
                  ), // Must be 18+
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: PulseColors.primary,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _dateOfBirth = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year} (Age: ${_calculateAge(_dateOfBirth!)})'
                              : 'Select your date of birth',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dateOfBirth != null
                                ? Colors.black87
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.calendar_today, color: PulseColors.primary),
                  ],
                ),
              ),
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
    final hasPendingChanges = _tempPhotoUrls.isNotEmpty || _photosMarkedForDeletion.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending changes indicator
          if (hasPendingChanges)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending Changes',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_tempPhotoUrls.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\u2022 ${_tempPhotoUrls.length} new photo(s) to upload',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_photosMarkedForDeletion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\u2022 ${_photosMarkedForDeletion.length} photo(s) to delete',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Click Save to confirm all changes',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          
          // Photo grid
          EnhancedPhotoGrid(
            photos: _photos,
            onPhotosChanged: (photos) {
              setState(() {
                _photos = photos;
              });
            },
            onPhotoUpload: _handleAddPhoto,
            onPhotoDelete: _handleDeletePhoto,
            maxPhotos: 6,
            isEditing: true,
          ),
        ],
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

  Widget _buildLifestylePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us more about yourself',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us match you with compatible people',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Lifestyle Section
          ProfileLifestyleSection(
            selectedLifestyle: _selectedLifestyle,
            onChanged: (value) {
              setState(() {
                _selectedLifestyle = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // Relationship Goals Section
          ProfileRelationshipGoalsSection(
            selectedGoals: _selectedRelationshipGoals,
            onChanged: (goals) {
              setState(() {
                _selectedRelationshipGoals = goals;
              });
            },
            maxSelections: 3,
          ),
          const SizedBox(height: 20),

          // Physical Attributes Section
          ProfilePhysicalAttributesSection(
            height: _selectedHeight,
            religion: _selectedReligion,
            politics: _selectedPolitics,
            onHeightChanged: (height) {
              setState(() {
                _selectedHeight = height; // Use selected value only
              });
            },
            onReligionChanged: (religion) {
              setState(() {
                _selectedReligion = religion;
              });
            },
            onPoliticsChanged: (politics) {
              setState(() {
                _selectedPolitics = politics;
              });
            },
          ),
          const SizedBox(height: 20),

          // Lifestyle Choices Section
          ProfileLifestyleChoicesSection(
            drinking: _selectedDrinking,
            smoking: _selectedSmoking,
            drugs: _selectedDrugs,
            children: _selectedChildren,
            onDrinkingChanged: (value) {
              setState(() {
                _selectedDrinking = value;
              });
            },
            onSmokingChanged: (value) {
              setState(() {
                _selectedSmoking = value;
              });
            },
            onDrugsChanged: (value) {
              setState(() {
                _selectedDrugs = value;
              });
            },
            onChildrenChanged: (value) {
              setState(() {
                _selectedChildren = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // Languages Section
          ProfileLanguagesSection(
            selectedLanguages: _selectedLanguages,
            onChanged: (languages) {
              setState(() {
                _selectedLanguages = languages;
              });
            },
            maxSelections: 5,
          ),
          const SizedBox(height: 20),
        ],
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
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
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
          initialValue: value,
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
