import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/profile/photo_grid.dart';
import '../../widgets/profile/profile_completion_card.dart';
import '../../widgets/profile/profile_privacy_settings.dart';
import '../../widgets/profile/interests_selector.dart';
import '../../widgets/profile/profile_lifestyle_section.dart';
import '../../widgets/profile/profile_relationship_goals_section.dart';
import '../../widgets/profile/profile_physical_attributes_section.dart';
import '../../widgets/profile/profile_lifestyle_choices_section.dart';
import '../../widgets/profile/profile_languages_section.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/models/interest.dart';
import '../../../core/services/error_handler.dart';
import './profile_details_screen.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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
  static const int _basicInfoTab = 0;
  static const int _photosTab = 1;
  static const int _interestsTab = 2;
  static const int _lifestyleTab = 3;
  static const int _privacyTab = 4;
  static const int _totalTabs = 5;

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
  List<Interest> _selectedInterests = [];
  String _selectedGender = 'Woman';
  String? _selectedPreference;
  List<ProfilePhoto> _photos = [];
  Map<String, dynamic> _privacySettings = Map.from({
    'showDistance': true,
    'showAge': true,
    'showLastActive': true,
    'showOnlineStatus': true,
    'incognitoMode': false,
    'readReceipts': true,
    'whoCanMessageMe': 'everyone', // 'everyone', 'matches', 'none'
    'whoCanSeeMyProfile': 'everyone', // 'everyone', 'matches', 'none'
  });

  UserProfile? _currentProfile;
  int _currentPageIndex = 0;
  bool _isProfileCompletionExpanded = false; // Collapsed by default
  bool _isFinalSave =
      false; // Track if this is the final save (not a section save)

  // Temp upload tracking for PhotoManagerService integration
  final List<String> _tempPhotoUrls = [];
  final Set<String> _photosMarkedForDeletion = {};

  // Flag to track if we've shown initial toast (prevent toasts on page load)
  bool _hasShownInitialToast = false;
  bool _isReloading = false;

  Timer? _cacheCleanupTimer;

  // New profile fields state
  String? _selectedLifestyle;
  List<String> _selectedRelationshipGoals = [];
  int? _selectedHeight; // No default - use real data or leave empty
  String? _selectedReligion;
  String? _selectedPolitics;
  String? _selectedDrinking;
  String? _selectedSmoking;
  String? _selectedExercise;
  String? _selectedDrugs;
  String? _selectedChildren;
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _totalTabs, vsync: this);
    // Use cached profile if available (no force refresh)
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  void dispose() {
    final profileBloc = context.read<ProfileBloc>();
    final state = profileBloc.state;

    state.uploadingPhotos.forEach((tempId, progress) {
      if (progress.state == PhotoUploadState.failed) {
        profileBloc.add(ClearUploadProgress(tempId: tempId));
      }
    });

    _cacheCleanupTimer?.cancel();
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
    logger.i('🔄 _populateFields() called');
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _dateOfBirth = profile.dateOfBirth;
    // Load from backend fields (occupation/education) with fallback to old fields
    _jobController.text = profile.occupation ?? profile.job ?? '';
    _companyController.text =
        profile.company ?? ''; // Company not in backend schema
    _schoolController.text = profile.education ?? profile.school ?? '';
    // Note: profile.interests is currently List<String> from UserProfile entity
    // This is a mismatch - should be Interest objects from API
    // For now, initialize as empty and let the API call populate actual interests
    _selectedInterests = [];

    // Normalize gender from backend format (MALE/FEMALE) to UI format (Man/Woman)
    _selectedGender = _normalizeGender(profile.gender) ?? 'Woman';
    // Load gender preference from showMe array (e.g., ['MEN'] -> 'Men')
    _selectedPreference = _normalizeShowMe(profile.showMe);
    _photos = List.from(profile.photos);

    // Populate new profile fields with enum mapping
    _selectedLifestyle = profile.lifestyleChoice;
    _selectedRelationshipGoals = List.from(profile.relationshipGoals);
    _selectedHeight = profile.height; // Use real data only
    
    // Map backend religion value to UI format
    _selectedReligion = ProfilePhysicalAttributesSection.mapReligionFromBackend(
      profile.religion,
    );

    // Map backend enum values to UI labels
    _selectedPolitics = ProfilePhysicalAttributesSection.mapPoliticsFromBackend(
      profile.politics,
    );
    _selectedDrinking = ProfileLifestyleChoicesSection.mapDrinkingFromBackend(
      profile.drinking,
    );
    _selectedSmoking = ProfileLifestyleChoicesSection.mapSmokingFromBackend(
      profile.smoking,
    );
    _selectedExercise = ProfileLifestyleChoicesSection.mapExerciseFromBackend(
      profile.exercise,
    );
    _selectedDrugs =
        ProfileLifestyleChoicesSection.mapDrugsFromBackend(profile.drugs) ??
        'Prefer not to say';
    _selectedChildren = ProfileLifestyleChoicesSection.mapChildrenFromBackend(
      profile.children,
    );

    _selectedLanguages = List.from(profile.languages);

    _privacySettings = {
      'showAge': profile.showAge ?? true,
      'showDistance': profile.showDistance ?? true,
      'showLastActive': profile.showLastActive ?? false,
      'showOnlineStatus': profile.showOnlineStatus ?? false,
      'incognitoMode': profile.incognitoMode ?? false,
      'readReceipts': profile.readReceipts ?? true,
      'whoCanMessageMe': profile.whoCanMessageMe ?? 'everyone',
      'whoCanSeeMyProfile': profile.whoCanSeeMyProfile ?? 'everyone',
    };

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

  /// Normalize showMe from backend array to UI format
  /// Backend sends ['MEN'], ['WOMEN'], or ['MEN', 'WOMEN']
  /// UI uses: 'Men', 'Women', or 'Everyone'
  String? _normalizeShowMe(List<String>? showMeArray) {
    if (showMeArray == null || showMeArray.isEmpty) return null;

    // Convert array to uppercase for comparison
    final upperArray = showMeArray.map((s) => s.toUpperCase()).toList();

    // Check if both MEN and WOMEN are selected
    if (upperArray.contains('MEN') && upperArray.contains('WOMEN')) {
      return 'Everyone';
    }

    // Check for single gender preference
    if (upperArray.contains('MEN')) {
      return 'Men';
    }
    if (upperArray.contains('WOMEN')) {
      return 'Women';
    }

    // Default to null if unrecognized
    return null;
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
    final photoId = photo.id;

    // Check if this is a temp photo (not yet saved)
    if (_tempPhotoUrls.contains(photoUrl)) {
      // Remove from temp list and local photos
      setState(() {
        _tempPhotoUrls.remove(photoUrl);
        _photos.removeWhere((p) => p.url == photoUrl);
      });
      // Temp photos don't need deletion event, they'll auto-cleanup
      logger.i('🗑️ Temp photo removed from UI');
    } else {
      // Mark existing photo for deletion
      setState(() {
        _photosMarkedForDeletion.add(photoUrl);
        _photos.removeWhere((p) => p.url == photoUrl);
      });

      // Clear cache for this specific photo immediately
      logger.i('🧹 Clearing cache for deleted photo: $photoUrl');
      CachedNetworkImage.evictFromCache(photoUrl);

      // Dispatch DeletePhoto event with media ID for backend deletion
      context.read<ProfileBloc>().add(DeletePhoto(photoId: photoId));
      logger.i(
        '🗑️ Photo deletion dispatched to BLoC - ID: $photoId, URL: $photoUrl',
      );

      // NO RELOAD HERE - The BLoC will handle updating the state
      // The BlocBuilder will automatically rebuild with the updated photo list
      logger.i('✅ Photo deleted - BLoC will update state automatically');
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

  /// Force reload profile from server, skipping cache
  Future<void> _forceReloadProfile() async {
    // Prevent multiple simultaneous reloads
    if (_isReloading) {
      logger.i('⏭️ Reload already in progress, skipping duplicate request');
      return;
    }

    _isReloading = true;
    logger.i('🔄 Force reload triggered - fetching fresh profile from server');

    try {
      // Clear cached network images to force re-download of photos
      _debouncedCacheClear();

      // Dispatch LoadProfile event with forceRefresh=true to bypass cache
      if (mounted) {
        context.read<ProfileBloc>().add(const LoadProfile(forceRefresh: true));
      }

      // Show a subtle loading indicator
      if (mounted) {
        PulseToast.info(
          context,
          message: 'Refreshing profile...',
          duration: const Duration(seconds: 1),
        );
      }

      // Wait a bit before allowing another reload
      await Future.delayed(const Duration(milliseconds: 1000));
    } finally {
      _isReloading = false;
    }
  }

  /// Clear cached network images for all profile photos
  void _debouncedCacheClear() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer(const Duration(milliseconds: 500), () {
      _clearPhotoCache();
    });
  }

  Future<void> _clearPhotoCache() async {
    try {
      for (final photo in _photos) {
        await CachedNetworkImage.evictFromCache(photo.url);
      }
      for (final photoUrl in _photosMarkedForDeletion) {
        await CachedNetworkImage.evictFromCache(photoUrl);
      }
    } catch (e) {
      logger.w('Failed to clear photo cache: $e');
    }
  }

  /// Wrap a page with pull-to-refresh functionality
  Widget _buildRefreshablePage(Widget child) {
    return RefreshIndicator(
      onRefresh: _forceReloadProfile,
      color: PulseColors.primary,
      child: child,
    );
  }

  UserProfile _buildProfileFromFormData({bool isPreview = false}) {
    return UserProfile(
      id: isPreview ? 'preview' : (_currentProfile?.id ?? 'current_user_id'),
      name: _nameController.text.trim().isEmpty
          ? (isPreview ? 'Your Name' : _currentProfile?.name ?? '')
          : _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? (isPreview ? 'Your bio will appear here...' : _currentProfile?.bio ?? '')
          : _bioController.text.trim(),
      age: _calculateAge(
        _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      ),
      dateOfBirth: _dateOfBirth,
      photos: isPreview
          ? (_photos.isEmpty
              ? [
                  ProfilePhoto(
                    id: 'placeholder',
                    url: 'https://via.placeholder.com/400x600/6E3BFF/FFFFFF?text=Add+Photo',
                    order: 0,
                  ),
                ]
              : _photos)
          : _photos,
      interests: _selectedInterests.map((i) => i.name).toList(),
      location: _currentProfile?.location ??
          UserLocation(latitude: 0.0, longitude: 0.0, city: 'Current City'),
      gender: isPreview ? _selectedGender : _convertGenderToBackendFormat(_selectedGender),
      showMe: _selectedPreference != null
          ? (_selectedPreference == 'Everyone' ? ['MEN', 'WOMEN'] : [_selectedPreference!.toUpperCase()])
          : null,
      occupation: _jobController.text.trim(),
      education: _schoolController.text.trim(),
      job: _jobController.text.trim(),
      company: _companyController.text.trim(),
      school: _schoolController.text.trim(),
      isOnline: true,
      lastSeen: DateTime.now(),
      verified: _currentProfile?.verified ?? false,
      lifestyleChoice: _selectedLifestyle,
      relationshipGoals: _selectedRelationshipGoals,
      height: _selectedHeight,
      religion: ProfilePhysicalAttributesSection.mapReligionToBackend(_selectedReligion),
      politics: ProfilePhysicalAttributesSection.mapPoliticsToBackend(_selectedPolitics),
      drinking: _selectedDrinking,
      smoking: _selectedSmoking,
      drugs: _selectedDrugs,
      children: _selectedChildren,
      languages: _selectedLanguages,
    );
  }

  void _showPreview() {
    if (_currentProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileDetailsScreen(
            profile: _buildProfileFromFormData(isPreview: true),
            isOwnProfile: true,
            context: ProfileContext.general,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPageIndex < _privacyTab) {
      _saveCurrentSection();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > _basicInfoTab) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveCurrentSection() {
    switch (_currentPageIndex) {
      case _basicInfoTab:
        _saveBasicInfoSection();
        break;
      case _photosTab:
        _savePhotosSection();
        break;
      case _interestsTab:
        _saveInterestsSection();
        break;
      case _lifestyleTab:
        _saveLifestyleSection();
        break;
      case _privacyTab:
        _savePrivacySection();
        break;
    }
  }

  void _saveBasicInfoSection() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      PulseToast.error(
        context,
        message: 'Please fill in all required fields',
      );
      return;
    }

    context.read<ProfileBloc>().add(
      UpdateProfile(profile: _buildProfileFromFormData()),
    );
  }

  void _savePhotosSection() {
    context.read<ProfileBloc>().add(
      UpdateProfile(profile: _buildProfileFromFormData()),
    );
  }

  void _saveInterestsSection() {
    context.read<ProfileBloc>().add(
      UpdateProfile(profile: _buildProfileFromFormData()),
    );
  }

  void _saveLifestyleSection() {
    context.read<ProfileBloc>().add(
      UpdateProfile(profile: _buildProfileFromFormData()),
    );
  }

  void _savePrivacySection() {
    context.read<ProfileBloc>().add(
      UpdatePrivacySettings(settings: _privacySettings),
    );
    _isFinalSave = true;
  }

  bool _hasUnsavedChanges() {
    if (_currentProfile == null) return false;

    return _nameController.text != _currentProfile!.name ||
        _bioController.text != (_currentProfile!.bio) ||
        _jobController.text != (_currentProfile!.occupation ?? _currentProfile!.job ?? '') ||
        _schoolController.text != (_currentProfile!.education ?? _currentProfile!.school ?? '');
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges()) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Unsaved Changes'),
              content: Text(
                'You have unsaved changes. Do you want to discard them?',
              ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Discard',
                    style: TextStyle(color: context.errorColor),
                  ),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: KeyboardDismissibleScaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
          title: Text(
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
              Icons.privacy_tip_rounded,
              color: PulseColors.primary,
              size: 26,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/privacy-settings');
            },
            tooltip: 'Privacy Settings',
          ),
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
                color: context.onSurfaceColor,
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
                    unselectedLabelColor: context.onSurfaceVariantColor,
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
          logger.d('🔔 BLoC Listener triggered:');
          logger.d('   - Status: ${state.status}');
          logger.d('   - Has profile: ${state.profile != null}');
          logger.d('   - Profile ID: ${state.profile?.id}');
          logger.d('   - Profile name: ${state.profile?.name}');
          logger.d('   - _currentProfile: ${_currentProfile?.name ?? "null"}');

          if (state.status == ProfileStatus.loaded && state.profile != null) {
            logger.i(
              '📝 Calling _populateFields with profile: ${state.profile!.name}',
            );

            // Save current tab/page index BEFORE any rebuild
            final currentTabIndex = _tabController.index;
            final currentPageIndex = _currentPageIndex;

            logger.i(
              '🔖 Saved current tab index: $currentTabIndex, page index: $currentPageIndex',
            );

            // Update model AND restore tab position in SAME setState
            // This ensures UI rebuild uses the correct tab index
            setState(() {
              _currentProfile = state.profile;
              _populateFields(state.profile!);
              // Restore tab position BEFORE UI rebuild completes
              _tabController.index = currentTabIndex;
              _currentPageIndex = currentPageIndex;
            });

            // Defer PageView navigation to AFTER frame renders
            // This ensures PageView is attached before calling jumpToPage
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(currentTabIndex);
                logger.i('✅ Page controller synced to page: $currentTabIndex');
              }
            });

            logger.i(
              '✅ _populateFields completed, tab restored to: ${_tabController.index}, _currentProfile: ${_currentProfile?.name}',
            );
          }

          // Handle photo upload success/error
          if (state.uploadStatus == ProfileStatus.success) {
            logger.i('📸 Upload status SUCCESS detected');
            logger.i('📊 Current _photos count: ${_photos.length}');
            logger.i(
              '📊 BLoC profile photos count: ${state.profile?.photos.length ?? 0}',
            );

            if (state.profile != null) {
              logger.i('🔄 Syncing _photos with BLoC state photos');

              final previousPhotoCount = _photos.length;
              final wasPhotoDeleted =
                  _photos.length > state.profile!.photos.length;
              final wasPhotoAdded =
                  _photos.length < state.profile!.photos.length;

              // Sync _photos with BLoC state (includes uploads/deletions)
              setState(() {
                _photos = List.from(state.profile!.photos);

                // Add temp URL to tracking list for new uploads
                if (wasPhotoAdded && state.profile!.photos.isNotEmpty) {
                  final latestPhoto = state.profile!.photos.last;
                  if (!_tempPhotoUrls.contains(latestPhoto.url)) {
                    _tempPhotoUrls.add(latestPhoto.url);
                  }
                  logger.i(
                    '🆕 Latest photo: id=${latestPhoto.id}, url=${latestPhoto.url}',
                  );
                }

                logger.i('✅ Photos synced: ${_photos.length} photos total');
              });

              // Clear cache to force fresh images on next render
              logger.i('🧹 Clearing photo cache after photo change');
              _debouncedCacheClear();

              // Show appropriate toast based on action
              if (_hasShownInitialToast) {
                if (wasPhotoAdded && _photos.length > previousPhotoCount) {
                  PulseToast.success(
                    context,
                    message: 'Photo uploaded successfully!',
                    duration: const Duration(seconds: 2),
                  );
                } else if (wasPhotoDeleted) {
                  logger.i(
                    '🗑️ Photo deleted, UI synced with ${_photos.length} remaining photos',
                  );
                  PulseToast.success(
                    context,
                    message: 'Photo deleted successfully',
                    duration: const Duration(seconds: 2),
                  );
                }
              }
            } else {
              logger.e('❌ No profile in BLoC state');
            }
          } else if (state.uploadStatus == ProfileStatus.error) {
            // Show error dialog with detailed error message
            ErrorHandler.handleError(
              Exception(state.error ?? 'Unknown error'),
              context: context,
              showDialog: true,
            );
          }

          if (state.updateStatus == ProfileStatus.success) {
            // Clear photo cache on ANY successful update to prevent stale images
            _debouncedCacheClear();

            // Only navigate away on final save, not section saves
            if (_isFinalSave) {
              logger.i('🎯 Final profile save successful');

              // Privacy tab (index 4) - show success, refresh, but DON'T navigate
              if (_currentPageIndex == _privacyTab) {
                logger.i('🔒 Privacy settings saved - staying on tab');
                PulseToast.success(
                  context,
                  message: 'Privacy settings saved successfully!',
                  duration: const Duration(seconds: 2),
                );
                // Force reload profile from server to get updated privacy settings
                logger.i(
                  '🔄 Triggering fresh API call to reload profile after privacy save',
                );

                _forceReloadProfile();
                // Refresh profile but stay on this tab
                _isFinalSave = false;
              } else {
                // Other tabs - show success and navigate to profile
                PulseToast.success(
                  context,
                  message: 'Profile saved successfully!',
                );
                // Navigate explicitly to profile screen (not discover page)
                logger.i('🚀 Executing context.go("/profile")');
                context.go('/profile');
                logger.i('✅ Navigation command sent');
                // Force reload profile to ensure fresh data after navigation
                _forceReloadProfile();
                _isFinalSave = false; // Reset flag
              }
            } else {
              // Section save successful - just clear cache, no reload needed
              logger.i('✅ Section $_currentPageIndex saved successfully');

              // Clear photo cache to ensure fresh images on next render
              // NO RELOAD - BLoC already updated the state after the save
              logger.i('🧹 Clearing photo cache after section save');
              _debouncedCacheClear();

              // Only show toast if not initial load
              if (_hasShownInitialToast) {
                PulseToast.success(
                  context,
                  message: 'Section saved!',
                  duration: const Duration(seconds: 1),
                );
              }
            }
            // Mark that we've now shown the initial toast (or that we're past initial load)
            _hasShownInitialToast = true;
          }
          if (state.updateStatus == ProfileStatus.error) {
            // Show error dialog with detailed error message
            ErrorHandler.handleError(
              Exception(state.error ?? 'Failed to update profile'),
              context: context,
              showDialog: true,
            );
          }
        },
        builder: (context, state) {
          logger.d('🏗️ Builder called:');
          logger.d('   - Status: ${state.status}');
          logger.d('   - Has profile: ${state.profile != null}');
          logger.d(
            '   - _currentProfile: ${_currentProfile != null ? _currentProfile!.name : "null"}',
          );

          if (state.status == ProfileStatus.loading && _currentProfile == null) {
            return _buildSkeletonLoader();
          }

          logger.d(
            '🎨 Building profile UI, _currentProfile is: ${_currentProfile != null ? "NOT NULL" : "NULL"}',
          );

          return Column(
            children: [
              // Profile completion card (collapsible)
              if (_currentProfile != null)
                Container(
                    color: context.onSurfaceColor,
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
                                Icon(
                                Icons.trending_up,
                                color: PulseColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                                Text(
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
                          profile: _buildProfileFromFormData(isPreview: true),
                          onTapIncomplete: () => _tabController.animateTo(_basicInfoTab),
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
                    _buildRefreshablePage(_buildBasicInfoPage()),
                    _buildRefreshablePage(_buildPhotosPage()),
                    _buildRefreshablePage(_buildInterestsPage()),
                    _buildRefreshablePage(_buildLifestylePage()),
                    _buildRefreshablePage(_buildPrivacyPage()),
                  ],
                ),
              ),

              // Bottom navigation
              Container(
                color: context.onSurfaceColor,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentPageIndex > _basicInfoTab)
                      Expanded(
                        child: PulseButton(
                          text: 'Previous',
                          onPressed: _previousPage,
                          variant: PulseButtonVariant.secondary,
                        ),
                      ),
                    if (_currentPageIndex > _basicInfoTab && _currentPageIndex < _privacyTab)
                      const SizedBox(width: 12),
                    Expanded(
                      child: PulseButton(
                        text: 'Continue',
                        onPressed: _currentPageIndex == _privacyTab
                            ? _saveCurrentSection // ✅ FIX: Call _saveCurrentSection for Privacy tab
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
    ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: 100,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 20,
            width: 80,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormField(
              'Name',
              _nameController,
              'Enter your name',
              validator: (value) =>
                  value?.isEmpty == true ? 'Name is required' : null,
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
                  color: context.onSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.outlineColor.withValues(alpha: 0.3),
                  ),
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
                            color: context.onSurfaceVariantColor,
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
                                : context.outlineColor.withValues(alpha: 0.2),
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
            _buildFormField('Job Title', _jobController, 'What do you do?'),
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
              'Show me',
              _selectedPreference,
              ['Men', 'Women', 'Everyone'],
              (value) => setState(() => _selectedPreference = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos auto-upload immediately - no pending changes banner needed

          // Photo grid with BLoC state for upload progress
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return PhotoGrid(
                photos: _photos,
                onPhotosChanged: (photos) {
                  setState(() {
                    _photos = photos;
                  });
                },
                onPhotoUpload: _handleAddPhoto,
                onPhotoDelete: _handleDeletePhoto,
                onRetryUpload: (tempId) {
                  context.read<ProfileBloc>().add(
                    RetryPhotoUpload(tempId: tempId),
                  );
                },
                uploadingPhotos: state.uploadingPhotos,
                maxPhotos: 6,
                isEditing: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
            style: TextStyle(
              fontSize: 14,
              color: context.onSurfaceVariantColor,
            ),
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
            exercise: _selectedExercise,
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
            onExerciseChanged: (value) {
              setState(() {
                _selectedExercise = value;
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
            hintStyle: TextStyle(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.outlineColor.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.outlineColor.withValues(alpha: 0.3),
              ),
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
    String? value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
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
            fillColor: context.surfaceColor,
            hintText: value == null ? 'Select an option' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.outlineColor.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.outlineColor.withValues(alpha: 0.3),
              ),
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
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
        ),
      ],
    );
  }
}
