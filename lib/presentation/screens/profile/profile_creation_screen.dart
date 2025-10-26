import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../services/profile_draft_service.dart';
import '../../../data/models/interest.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/profile/interests_selector.dart';
import '../../widgets/profile/photo_picker_grid.dart';
import '../../widgets/profile/profile_exit_dialog.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Profile creation screen for new users
/// IMPORTANT: Core fields (name, age, gender, 1 photo) are now required and non-skippable
class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  late final ProfileDraftService _draftService;

  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _occupationController = TextEditingController();

  int _currentStep = 0;
  final int _totalSteps = 5;

  final List<String> _selectedPhotos = [];
  List<Interest> _selectedInterests = [];
  String? _selectedGender;
  String? _selectedLookingFor;

  @override
  void initState() {
    super.initState();
    _draftService = ProfileDraftService();
    _initializeDraftService();
  }

  Future<void> _initializeDraftService() async {
    await _draftService.init();
    _checkForExistingDraft();
  }

  void _checkForExistingDraft() {
    final existingDraft = _draftService.loadDraft();
    if (existingDraft != null && !existingDraft.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDraftRestoreDialog(existingDraft);
      });
    }
  }

  void _showDraftRestoreDialog(ProfileDraft draft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileDraftRestoreDialog(
        draft: draft,
        onRestore: () {
          Navigator.of(context).pop();
          _restoreDraft(draft);
        },
        onStartFresh: () {
          Navigator.of(context).pop();
          _draftService.clearDraft();
        },
      ),
    );
  }

  void _restoreDraft(ProfileDraft draft) {
    setState(() {
      _nameController.text = draft.name ?? '';
      _ageController.text = draft.age?.toString() ?? '';
      _bioController.text = draft.bio ?? '';
      _selectedPhotos.clear();
      _selectedPhotos.addAll(draft.photos);
      // Convert interest IDs back to Interest objects (stored as empty interests for now)
      _selectedInterests = [];
      _selectedGender = draft.gender;
      _selectedLookingFor = draft.lookingFor;
      _currentStep = draft.currentStep;
    });

    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _occupationController.dispose();
    _draftService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _handleBackButton();
          if (shouldPop && context.mounted) {
            if (context.mounted) Navigator.of(context).pop();
          }
        }
      },
      child: KeyboardDismissibleScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Create Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: PulseColors.primary,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => _handleBackButton(),
          ),
          actions: [
            TextButton(
              onPressed: _currentStep > 0 ? _goToPreviousStep : null,
              child: Text(
                'Back',
                style: TextStyle(
                  color: _currentStep > 0
                      ? PulseColors.primary
                      : context.outlineColor,
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.status == ProfileStatus.error) {
              PulseToast.error(
                context,
                message: state.error ?? 'An error occurred',
              );
            } else if (state.status == ProfileStatus.success) {
              // Profile created successfully, navigate to main app
              Navigator.of(context).pushReplacementNamed('/main');
            }
          },
          builder: (context, state) {
            if (state.status == ProfileStatus.loading) {
              return Center(child: PulseLoadingWidget());
            }

            return Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBasicInfoStep(),
                      _buildPhotosStep(),
                      _buildBioStep(),
                      _buildInterestsStep(),
                      _buildPreferencesStep(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(
              _totalSteps,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? PulseColors.primary
                        : context.outlineColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us a bit about yourself',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(
                color: context.onSurfaceVariantColor,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 18 || age > 100) {
                        return 'Please enter a valid age (18-100)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _occupationController,
              decoration: InputDecoration(
                labelText: 'Occupation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: ['Male', 'Female', 'Non-binary', 'Other']
                  .map(
                    (gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosStep() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Photos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: PulseColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload at least one photo to continue *',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: PhotoPickerGrid(
              initialPhotos: _selectedPhotos,
              onPhotosChanged: (photos) {
                setState(() {
                  _selectedPhotos.clear();
                  _selectedPhotos.addAll(photos);
                });
              },
              maxPhotos: 6,
              isRequired: true,
            ),
          ),
          if (_selectedPhotos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: PulseColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'At least one photo is required to create your profile',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PulseColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'About You',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PulseColors.primary,
                ),
              ),
              TextButton(
                onPressed: () => _goToNextStep(),
                child: Text(
                  'Skip for now',
                  style: TextStyle(color: context.onSurfaceVariantColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Write a short bio to tell people about yourself (optional)',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _bioController,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText:
                  'Tell us about yourself, your hobbies, what you\'re looking for...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            maxLength: 500,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: PulseColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Mention your interests, what makes you unique, and what you\'re looking for in a relationship.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PulseColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Interests',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PulseColors.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showSkipDialog(
                    'Skip Interests?',
                    'Adding interests helps us find better matches for you. You can always add them later in your profile settings.',
                    () => _goToNextStep(),
                  );
                },
                child: Text(
                  'Skip for now',
                  style: TextStyle(color: context.onSurfaceVariantColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select interests that represent you (optional)',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: InterestsSelector(
              selectedInterests: _selectedInterests,
              onInterestsChanged: (interests) {
                setState(() {
                  _selectedInterests = interests;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dating Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: PulseColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us what you\'re looking for',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: context.onSurfaceVariantColor),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: _selectedLookingFor,
            decoration: InputDecoration(
              labelText: 'Looking for *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.favorite),
            ),
            items:
                [
                      'Long-term relationship',
                      'Something casual',
                      'New friends',
                      'Not sure yet',
                    ]
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLookingFor = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select what you\'re looking for';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PulseColors.primary.withValues(alpha: 0.1),
                  PulseColors.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.celebration, size: 48, color: PulseColors.primary),
                const SizedBox(height: 16),
                Text(
                  'You\'re almost done!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile to start meeting amazing people.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: PulseColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: PulseColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed() ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _getNextButtonText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        // Step 1: Basic Info - REQUIRED: name, age, gender
        return _nameController.text.trim().isNotEmpty &&
            _ageController.text.trim().isNotEmpty &&
            _selectedGender != null;
      case 1:
        // Step 2: Photos - REQUIRED: at least 1 photo
        return _selectedPhotos.isNotEmpty;
      case 2:
        // Step 3: Bio - OPTIONAL
        return true;
      case 3:
        // Step 4: Interests - OPTIONAL
        return true;
      case 4:
        // Step 5: Preferences - REQUIRED: lookingFor
        return _selectedLookingFor != null;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_currentStep == 0 && !_formKey.currentState!.validate()) {
        return;
      }

      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _autoSaveDraft(); // Auto-save when proceeding
    } else {
      _createProfile();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createProfile() {
    if (!_formKey.currentState!.validate()) {
      PulseToast.error(context, message: 'Please fill in all required fields');
      return;
    }

    // Validate required fields before submission
    if (_selectedPhotos.isEmpty) {
      PulseToast.error(context, message: 'Please add at least one photo');
      return;
    }

    // Get current user ID (this would typically come from auth state)
    const userId =
        'current-user-id'; // This should be retrieved from auth state

    final profileData = {
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 18,
      'height': _heightController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'gender': _selectedGender,
      'lookingFor': _selectedLookingFor,
      'interestIds': _selectedInterests.map((i) => i.id).toList(),
      'photos': _selectedPhotos,
      'profileCompleted': true,
    };

    try {
      context.read<UserBloc>().add(
        UserProfileUpdateRequested(userId: userId, updates: profileData),
      );

      PulseToast.success(context, message: 'Profile created successfully!');

      // Navigate to main app
      context.go('/main');
    } catch (e) {
      PulseToast.error(context, message: 'Failed to create profile: $e');
    }
  }

  Future<bool> _handleBackButton() async {
    // Check if user has an existing profile via ProfileBloc
    final profileState = context.read<ProfileBloc>().state;
    final hasExistingProfile = profileState.profile != null;

    // If editing existing profile, just navigate back without confirmation
    if (hasExistingProfile) {
      context.go('/profile');
      return false; // Don't use Navigator.pop
    }

    // For new profile creation, show exit dialog
    final currentDraft = _getCurrentDraft();

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileExitDialog(
        currentDraft: currentDraft,
        onSaveAndExit: () {
          Navigator.of(context).pop(false); // Don't pop the screen yet
          _saveDraftAndExit();
        },
        onExitWithoutSaving: () {
          Navigator.of(context).pop(false); // Don't pop the screen yet
          _draftService.clearDraft();
          // Navigate to home screen
          context.go('/home');
        },
        onContinueEditing: () {
          Navigator.of(context).pop(false);
        },
      ),
    );

    return shouldExit ?? false;
  }

  ProfileDraft _getCurrentDraft() {
    return ProfileDraft(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      age: int.tryParse(_ageController.text),
      bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      photos: List<String>.from(_selectedPhotos),
      interests: _selectedInterests.map((i) => i.id).toList(),
      gender: _selectedGender,
      lookingFor: _selectedLookingFor,
      currentStep: _currentStep,
      savedAt: DateTime.now(),
    );
  }

  Future<void> _saveDraftAndExit() async {
    final draft = _getCurrentDraft();
    await _draftService.saveDraft(draft);
    if (mounted) {
      // Check if user has existing profile
      final profileState = context.read<ProfileBloc>().state;
      final hasExistingProfile = profileState.profile != null;

      // Navigate back to profile overview if editing, otherwise go home
      if (hasExistingProfile) {
        context.go('/profile');
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _autoSaveDraft() async {
    final draft = _getCurrentDraft();
    if (!draft.isEmpty) {
      await _draftService.saveDraft(draft);
    }
  }

  void _showSkipDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.onSurfaceVariantColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: context.onSurfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Skip'),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return _selectedPhotos.isNotEmpty
            ? 'Continue with Photos'
            : 'Add at least 1 photo';
      case 2:
        return _bioController.text.trim().isNotEmpty
            ? 'Continue with Bio'
            : 'Continue';
      case 3:
        return _selectedInterests.isNotEmpty
            ? 'Continue with Interests'
            : 'Continue';
      case 4:
        return 'Complete Profile';
      default:
        return 'Next';
    }
  }
}
