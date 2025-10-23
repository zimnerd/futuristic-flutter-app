import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/permission_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_toast.dart';
import '../onboarding/intent_selection_screen.dart';

/// Progressive profile setup wizard shown after first authentication
/// Each step is closable and can be completed later
/// Minimum requirements enforced before accessing main app
class ProfileSetupWizard extends StatefulWidget {
  const ProfileSetupWizard({super.key});

  @override
  State<ProfileSetupWizard> createState() => _ProfileSetupWizardState();
}

class _ProfileSetupWizardState extends State<ProfileSetupWizard> {
  int _currentStep = 0;
  bool _canSkipToApp = false;

  // Step completion tracking
  bool _intentSelected = false;
  bool _photosAdded = false;
  bool _bioAdded = false;
  bool _interestsAdded = false;
  bool _locationEnabled = false;

  final List<ProfileStep> _steps = [
    ProfileStep(
      id: 'intent',
      title: 'What brings you here?',
      subtitle: 'Select your main interest',
      icon: Icons.favorite_outline,
      isRequired: true,
    ),
    ProfileStep(
      id: 'photos',
      title: 'Add your photos',
      subtitle: 'Minimum 2 photos required',
      icon: Icons.photo_camera_outlined,
      isRequired: true,
    ),
    ProfileStep(
      id: 'bio',
      title: 'Write your bio',
      subtitle: 'Tell people about yourself',
      icon: Icons.edit_outlined,
      isRequired: false,
    ),
    ProfileStep(
      id: 'interests',
      title: 'Select interests',
      subtitle: 'Pick at least 3 interests',
      icon: Icons.interests_outlined,
      isRequired: true,
    ),
    ProfileStep(
      id: 'location',
      title: 'Enable location',
      subtitle: 'Find people nearby',
      icon: Icons.location_on_outlined,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingProgress();
  }

  Future<void> _checkExistingProgress() async {
    // Check if user has already completed some steps
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _intentSelected = prefs.getBool('setup_intent_completed') ?? false;
      _photosAdded = prefs.getBool('setup_photos_completed') ?? false;
      _bioAdded = prefs.getBool('setup_bio_completed') ?? false;
      _interestsAdded = prefs.getBool('setup_interests_completed') ?? false;
      _locationEnabled = prefs.getBool('setup_location_completed') ?? false;

      _updateCanSkipStatus();
    });
  }

  void _updateCanSkipStatus() {
    // User can skip to app if all required steps are complete
    _canSkipToApp = _intentSelected && _photosAdded && _interestsAdded;
  }

  Future<void> _markStepComplete(String stepId, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_${stepId}_completed', completed);

    setState(() {
      switch (stepId) {
        case 'intent':
          _intentSelected = completed;
          break;
        case 'photos':
          _photosAdded = completed;
          break;
        case 'bio':
          _bioAdded = completed;
          break;
        case 'interests':
          _interestsAdded = completed;
          break;
        case 'location':
          _locationEnabled = completed;
          break;
      }
      _updateCanSkipStatus();
    });
  }

  void _handleStepComplete() {
    _markStepComplete(_steps[_currentStep].id, true);

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeSetup();
    }
  }

  void _handleSkipStep() {
    if (_steps[_currentStep].isRequired && !_isStepComplete(_currentStep)) {
      PulseToast.warning(
        context,
        message: 'This step is required to continue',
      );
      return;
    }

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeSetup();
    }
  }

  Future<void> _completeSetup() async {
    if (!_canSkipToApp) {
      PulseToast.error(
        context,
        message: 'Please complete all required steps',
      );
      return;
    }

    // Mark setup as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_setup_complete', true);

    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleCloseLater() async {
    if (!_canSkipToApp) {
      // Show warning dialog
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete Your Profile'),
          content: const Text(
            'You need to complete the required steps (intent, photos, and interests) before you can access the app.\n\nWould you like to continue setup?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Setup'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: PulseColors.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldClose == true && mounted) {
        // Logout user
        context.read<AuthBloc>().add(const AuthSignOutRequested());
        context.go(AppRoutes.welcome);
      }
    } else {
      // Can continue setup later
      await _completeSetup();
    }
  }

  bool _isStepComplete(int stepIndex) {
    switch (_steps[stepIndex].id) {
      case 'intent':
        return _intentSelected;
      case 'photos':
        return _photosAdded;
      case 'bio':
        return _bioAdded;
      case 'interests':
        return _interestsAdded;
      case 'location':
        return _locationEnabled;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];

    return Scaffold(
      backgroundColor: PulseColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and close button
            _buildHeader(),

            // Progress indicator
            _buildProgressIndicator(),

            // Step content
            Expanded(
              child: _buildStepContent(currentStepData),
            ),

            // Navigation buttons
            _buildNavigationButtons(currentStepData),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile Setup',
            style: PulseTextStyles.titleLarge.copyWith(
              color: PulseColors.onSurface,
            ),
          ),
          IconButton(
            onPressed: _handleCloseLater,
            icon: Icon(
              _canSkipToApp ? Icons.close : Icons.logout,
              color: _canSkipToApp ? PulseColors.onSurface : PulseColors.error,
            ),
            tooltip: _canSkipToApp ? 'Finish later' : 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              final isComplete = _isStepComplete(index);
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _steps.length - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete || isCurrent
                        ? PulseColors.primary
                        : PulseColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Step ${_currentStep + 1} of ${_steps.length}',
            style: PulseTextStyles.labelSmall.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ProfileStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: PulseColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 40,
              color: PulseColors.primary,
            ),
          ),

          const SizedBox(height: PulseSpacing.xl),

          // Step title
          Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: PulseTextStyles.displaySmall.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
              if (step.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PulseSpacing.sm,
                    vertical: PulseSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PulseColors.errorContainer,
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  child: Text(
                    'Required',
                    style: PulseTextStyles.labelSmall.copyWith(
                      color: PulseColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: PulseSpacing.sm),

          // Step subtitle
          Text(
            step.subtitle,
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: PulseSpacing.xxl),

          // Step-specific content
          _buildStepSpecificContent(step.id),
        ],
      ),
    );
  }

  Widget _buildStepSpecificContent(String stepId) {
    switch (stepId) {
      case 'intent':
        return _buildIntentStep();
      case 'photos':
        return _buildPhotosStep();
      case 'bio':
        return _buildBioStep();
      case 'interests':
        return _buildInterestsStep();
      case 'location':
        return _buildLocationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntentStep() {
    // Use the existing IntentSelectionScreen content
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: PulseColors.primaryContainer,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: PulseColors.primary,
            size: 48,
          ),
          const SizedBox(height: PulseSpacing.md),
          Text(
            'This helps us personalize your experience and show you relevant connections.',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          ElevatedButton(
            onPressed: () {
              // Navigate to full intent selection
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IntentSelectionScreen(),
                ),
              ).then((result) {
                if (result == true) {
                  _handleStepComplete();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Your Intent'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(color: PulseColors.outline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: PulseColors.primary,
          ),
          const SizedBox(height: PulseSpacing.md),
          Text(
            'Add at least 2 photos',
            style: PulseTextStyles.titleMedium.copyWith(
              color: PulseColors.onSurface,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Profiles with photos get 10x more matches!',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          ElevatedButton.icon(
            onPressed: () async {
              // Navigate to photo upload screen
              final result = await context.push('/profile-section-edit', extra: {
                'sectionType': 'photos',
              });

              if (result == true) {
                _handleStepComplete();
              }
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: PulseColors.secondary,
          ),
          const SizedBox(height: PulseSpacing.md),
          Text(
            'Make your profile stand out',
            style: PulseTextStyles.titleMedium.copyWith(
              color: PulseColors.onSurface,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Share something interesting about yourself',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push('/profile-section-edit', extra: {
                'sectionType': 'bio',
              });

              if (result == true) {
                _handleStepComplete();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Write Bio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.successContainer,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: PulseColors.success,
          ),
          const SizedBox(height: PulseSpacing.md),
          Text(
            'What do you love?',
            style: PulseTextStyles.titleMedium.copyWith(
              color: PulseColors.onSurface,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Pick at least 3 interests to find people with similar passions',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push('/profile-section-edit', extra: {
                'sectionType': 'interests',
              });

              if (result == true) {
                _handleStepComplete();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Select Interests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.secondaryContainer,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_on,
            size: 64,
            color: PulseColors.secondary,
          ),
          const SizedBox(height: PulseSpacing.md),
          Text(
            'Find people nearby',
            style: PulseTextStyles.titleMedium.copyWith(
              color: PulseColors.onSurface,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Enable location to see and be seen by people in your area',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.md),
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: PulseColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PulseRadii.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: PulseColors.secondary,
                ),
                const SizedBox(width: PulseSpacing.xs),
                Expanded(
                  child: Text(
                    'Your location is only used to show distance to other users',
                    style: PulseTextStyles.labelSmall.copyWith(
                      color: PulseColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PulseSpacing.lg),
          ElevatedButton.icon(
            onPressed: () async {
              // Request location permission using PermissionService
              final permissionService = PermissionService();
              final granted = await permissionService.requestLocationWhenInUsePermission(context);

              if (granted) {
                PulseToast.success(
                  context,
                  message: 'Location enabled successfully!',
                );
                _handleStepComplete();
              } else {
                PulseToast.info(
                  context,
                  message: 'You can enable location later in settings',
                );
                // Still allow skipping since it's optional
                _handleSkipStep();
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Enable Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ProfileStep step) {
    final isLastStep = _currentStep == _steps.length - 1;
    final isStepComplete = _isStepComplete(_currentStep);

    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!step.isRequired || isStepComplete) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLastStep && _canSkipToApp
                    ? _completeSetup
                    : _handleSkipStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isLastStep ? 'Complete Setup' : 'Continue',
                  style: PulseTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (!step.isRequired)
              TextButton(
                onPressed: _handleSkipStep,
                child: Text(
                  'Skip for now',
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
              ),
          ] else ...[
            Text(
              'Complete this required step to continue',
              style: PulseTextStyles.bodySmall.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileStep {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRequired;

  const ProfileStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isRequired,
  });
}
