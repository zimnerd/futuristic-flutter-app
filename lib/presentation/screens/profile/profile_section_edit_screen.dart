import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/photo/photo_bloc.dart';
import '../../blocs/photo/photo_state.dart';
import '../../blocs/photo/photo_event.dart' as photo_events;
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../dialogs/photo_details_dialog.dart';
import '../../sheets/photo_reorder_sheet.dart';
import '../../../domain/entities/user_profile.dart';
import '../../navigation/app_router.dart';
import '../../widgets/profile/interests_selector.dart';
import '../../../core/constants/intent_options.dart';
import '../../../core/services/service_locator.dart';

/// Profile section edit screen for editing individual profile sections
/// 
/// Can operate in two modes:
/// - isEditMode=true: Used when editing existing profile (pops after save)
/// - isEditMode=false: Used during onboarding setup (progresses to next section)
class ProfileSectionEditScreen extends StatefulWidget {
  final String sectionType;
  final Map<String, dynamic>? initialData;
  final bool isEditMode;

  const ProfileSectionEditScreen({
    super.key,
    required this.sectionType,
    this.initialData,
    this.isEditMode = false,
  });

  @override
  State<ProfileSectionEditScreen> createState() =>
      _ProfileSectionEditScreenState();
}

class _ProfileSectionEditScreenState extends State<ProfileSectionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, dynamic> _formData;
  UserProfile? _currentProfile; // NEW: Store loaded profile
  final logger = Logger(); // NEW: For debug logging

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _formData = Map.from(widget.initialData ?? {});
    _initializeControllers();
    
    // NEW: Load existing profile data for prepopulation
    logger.i(
      '📱 Initializing ProfileSectionEditScreen for section: ${widget.sectionType}',
    );
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  void didUpdateWidget(ProfileSectionEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If section type changed, reinitialize and repopulate
    if (oldWidget.sectionType != widget.sectionType) {
      logger.i(
        '🔄 Section type changed from ${oldWidget.sectionType} to ${widget.sectionType}',
      );

      // Clear section-specific form data for new section
      _controllers.clear();
      _formData.clear();
      _formData.addAll(widget.initialData ?? {});
      _initializeControllers();

      // Repopulate fields if we have a cached profile
      if (_currentProfile != null) {
        logger.i(
          '📝 Repopulating fields for new section: ${widget.sectionType}',
        );
        _populateFields(_currentProfile!);
      } else {
        // Load profile if not cached yet
        logger.i('📥 Loading profile for new section');
        context.read<ProfileBloc>().add(const LoadProfile());
      }
    }
  }

  void _initializeControllers() {
    switch (widget.sectionType) {
      case 'basic_info':
        _controllers['name'] = TextEditingController(
          text: _formData['name'] ?? '',
        );
        // Age controller removed - now using dateOfBirth directly
        _controllers['bio'] = TextEditingController(
          text: _formData['bio'] ?? '',
        );
        break;
      case 'work_education':
        _controllers['job'] = TextEditingController(
          text: _formData['job'] ?? '',
        );
        _controllers['company'] = TextEditingController(
          text: _formData['company'] ?? '',
        );
        _controllers['school'] = TextEditingController(
          text: _formData['school'] ?? '',
        );
        break;
      case 'photos':
        // Photos are handled separately with PhotoPickerWidget
        break;
      case 'interests':
        // Interests are handled separately as a list
        break;
      case 'intent':
        // Intent is handled separately as a selection
        break;
      case 'preferences':
        // Preferences are handled as dropdown selections
        break;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    logger.i('🔄 _populateFields() called for section: ${widget.sectionType}');

    try {
      switch (widget.sectionType) {
        case 'basic_info':
          _controllers['name']!.text = profile.name;
          _controllers['bio']!.text = profile.bio;
          _formData['dateOfBirth'] = profile.dateOfBirth;
          _formData['gender'] = _normalizeGender(profile.gender);
          _formData['showMe'] = _normalizeShowMe(profile.showMe);
          logger.i('✅ Populated basic_info fields');
          break;

        case 'work_education':
          _controllers['job']!.text = profile.occupation ?? profile.job ?? '';
          _controllers['company']!.text = profile.company ?? '';
          _controllers['school']!.text =
              profile.education ?? profile.school ?? '';
          logger.i('✅ Populated work_education fields');
          break;

        case 'photos':
          // Convert ProfilePhoto objects to Maps for UI compatibility
          _formData['photos'] = profile.photos
              .map(
                (photo) => {
                  'id': photo.id,
                  'url': photo.url,
                  'order': photo.order,
                  'description': photo.description,
                  'blurhash': photo.blurhash,
                  'isMain': photo.isMain,
                  'isVerified': photo.isVerified,
                  'uploadedAt': photo.uploadedAt?.toIso8601String(),
                },
              )
              .toList();
          // newPhotos stays empty - only for new selections
          _formData['newPhotos'] = [];
          logger.i(
            '✅ Populated photos: ${profile.photos.length} existing photos, converted to Maps',
          );
          break;

        case 'interests':
          _formData['interests'] = List.from(profile.interests);
          _formData['selectedInterests'] = List.from(profile.interests);
          logger.i(
            '✅ Populated interests: ${profile.interests.length} interests selected',
          );
          break;

        case 'intent':
          // Intent comes from relationshipGoals array - take first if exists
          final intent = profile.relationshipGoals.isNotEmpty
              ? profile.relationshipGoals.first
              : null;
          _formData['intent'] = intent;
          logger.i('✅ Populated intent: $intent');
          break;

        case 'preferences':
          _formData['gender'] = _normalizeGender(profile.gender);
          _formData['showMe'] = _normalizeShowMe(profile.showMe);
          logger.i('✅ Populated preferences');
          break;
      }

      _currentProfile = profile;
      logger.i('✅ _populateFields() completed successfully');
    } catch (e) {
      logger.e('❌ Error in _populateFields(): $e');
      // Don't throw - form can still work with empty fields
    }
  }

  String? _normalizeGender(String? gender) {
    if (gender == null) return null;

    final lower = gender.toLowerCase();
    if (lower.contains('man') || lower.contains('male')) return 'Man';
    if (lower.contains('woman') || lower.contains('female')) return 'Woman';
    if (lower.contains('non') || lower.contains('other')) return 'Non-binary';

    return gender; // Return original if no match
  }

  List<String> _normalizeShowMe(dynamic showMe) {
    if (showMe == null) return [];
    if (showMe is List) return List<String>.from(showMe);
    if (showMe is String) return [showMe];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        logger.d('📡 ProfileBloc state changed: ${state.status}');

        if (state.status == ProfileStatus.loaded && state.profile != null) {
          logger.i('📝 Profile loaded, calling _populateFields()');

          setState(() {
            _currentProfile = state.profile;
            _populateFields(state.profile!);
          });
        } else if (state.status == ProfileStatus.error) {
          // Handle error gracefully - form can still work with empty fields
          logger.w('⚠️ Failed to load profile: ${state.error}');
          // Don't show error toast - user can still use empty form
        }
      },
      child: BlocListener<PhotoBloc, PhotoState>(
        listener: (context, state) {
          if (state is PhotoError) {
            PulseToast.error(
              context,
              message: state.message,
              duration: const Duration(seconds: 3),
            );
          } else if (state is PhotoOperationSuccess) {
            PulseToast.success(
              context,
              message: state.message,
              duration: const Duration(seconds: 2),
            );
            // Refresh profile data
            context.read<ProfileBloc>().add(LoadProfile());
          }
        },
        child: KeyboardDismissibleScaffold(
          appBar: AppBar(
            title: Text(
              _getSectionTitle(),
              style: PulseTextStyles.titleLarge.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: PulseColors.onSurface),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: _saveSection,
                child: Text(
                  'Save',
                  style: PulseTextStyles.titleMedium.copyWith(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: PulseSpacing.lg,
                  right: PulseSpacing.lg,
                  top: PulseSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      PulseSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionDescription(),
                    const SizedBox(height: PulseSpacing.xl),
                    _buildSectionContent(),
                    const SizedBox(height: PulseSpacing.xxl),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ), // KeyboardDismissibleScaffold
      ), // PhotoBloc BlocListener
    ); // ProfileBloc BlocListener
  }

  Widget _buildSectionDescription() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            child: Icon(_getSectionIcon(), color: Colors.white, size: 24),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSectionTitle(),
                  style: PulseTextStyles.titleLarge.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: PulseSpacing.xs),
                Text(
                  _getSectionDescription(),
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (widget.sectionType) {
      case 'basic_info':
        return _buildBasicInfoSection();
      case 'photos':
        return _buildPhotosSection();
      case 'work_education':
        return _buildWorkEducationSection();
      case 'interests':
        return _buildInterestsSection();
      case 'intent':
        return _buildIntentSection();
      case 'preferences':
        return _buildPreferencesSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show pre-populated indicator if profile was loaded
        if (_currentProfile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: PulseSpacing.md),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: PulseColors.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Loaded from your profile',
                  style: PulseTextStyles.labelSmall.copyWith(
                    color: PulseColors.success,
                  ),
                ),
              ],
            ),
          ),
        
        _buildTextField(
          controller: _controllers['name']!,
          label: 'Name',
          hint: 'Enter your first name',
          icon: Icons.person,
          isRequired: true,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Name is required';
            }
            if (value!.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildDateOfBirthPicker(),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['bio']!,
          label: 'Bio',
          hint: 'Tell people about yourself...',
          icon: Icons.description,
          maxLines: 4,
          maxLength: 500,
          validator: (value) {
            if (value != null && value.length > 500) {
              return 'Bio must be less than 500 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    // Get existing photos from API (ProfilePhoto objects with URLs)
    final List<dynamic> existingPhotos =
        _formData['photos'] as List<dynamic>? ?? [];

    // Get new photos selected by user (File objects)
    final List<File> newPhotos =
        ((_formData['newPhotos'] as List<dynamic>?)?.cast<File>()) ?? [];

    // Total photo count
    final int totalPhotos = existingPhotos.length + newPhotos.length;
    
    logger.i(
      '🖼️ _buildPhotosSection: existingPhotos=${existingPhotos.length}, newPhotos=${newPhotos.length}, total=$totalPhotos',
    );

    if (existingPhotos.isNotEmpty) {
      logger.i('📸 First existing photo: ${existingPhotos.first}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(PulseSpacing.md),
          decoration: BoxDecoration(
            color: PulseColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(PulseRadii.md),
            border: Border.all(
              color: PulseColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.photo_library, color: PulseColors.primary),
              const SizedBox(width: PulseSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Add photos',
                          style: PulseTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' *',
                          style: PulseTextStyles.bodyMedium.copyWith(
                            color: PulseColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add up to 6 photos ($totalPhotos/6). Your first photo will be your main profile picture.',
                      style: PulseTextStyles.bodySmall.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PulseSpacing.lg),

        // Reorder photos button (show only if there are 2+ photos)
        if (totalPhotos >= 2)
          Padding(
            padding: const EdgeInsets.only(bottom: PulseSpacing.md),
            child: OutlinedButton.icon(
              onPressed: _showPhotoReorderSheet,
              icon: const Icon(Icons.reorder),
              label: const Text('Reorder Photos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PulseColors.primary,
                side: BorderSide(color: PulseColors.primary),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),

        // Combined photo grid (existing + new photos)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: PulseSpacing.sm,
            mainAxisSpacing: PulseSpacing.sm,
            childAspectRatio: 1,
          ),
          itemCount: 6, // Always show 6 slots
          itemBuilder: (context, index) {
            // Check if this slot has an existing photo
            if (index < existingPhotos.length) {
              return _buildExistingPhotoCard(existingPhotos[index], index);
            }
            // Check if this slot has a new photo
            else if (index < existingPhotos.length + newPhotos.length) {
              final newPhotoIndex = index - existingPhotos.length;
              return _buildNewPhotoCard(
                newPhotos[newPhotoIndex],
                index,
                newPhotoIndex,
              );
            }
            // Empty slot - show add button
            else {
              return _buildAddPhotoButton();
            }
          },
        ),
      ],
    );
  }

  Widget _buildExistingPhotoCard(dynamic photo, int displayIndex) {
    // Handle both Map and ProfilePhoto objects
    final String photoUrl;
    final String? description;
    final bool isMain;

    if (photo is ProfilePhoto) {
      // Handle ProfilePhoto entity objects
      photoUrl = photo.url;
      description = photo.description;
      isMain = photo.isMain || displayIndex == 0;
    } else if (photo is Map) {
      // Handle Map/JSON objects
      photoUrl = photo['url'] ?? photo['photo_url'] ?? '';
      description = photo['description'] as String?;
      isMain =
          (photo['isMain'] ?? photo['isPrimary'] ?? displayIndex == 0) as bool;
    } else {
      // Fallback for string URLs
      photoUrl = photo.toString();
      description = null;
      isMain = displayIndex == 0;
    }

    return GestureDetector(
      onTap: () => _showPhotoDetails(photo, displayIndex),
      onLongPress: () => _navigateToPhotoGallery(displayIndex),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PulseRadii.md),
          border: Border.all(
            color: isMain
                ? PulseColors.primary
                : PulseColors.outline.withValues(alpha: 0.3),
            width: isMain ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Photo image
            ClipRRect(
              borderRadius: BorderRadius.circular(PulseRadii.md - 1),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: PulseColors.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Failed to load image: $photoUrl');
                  debugPrint('Error: $error');
                  return Container(
                    color: PulseColors.surfaceVariant,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 32),
                        SizedBox(height: 4),
                        Text('Failed', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Main badge
            if (isMain)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PulseColors.primary,
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  child: Text(
                    'Main',
                    style: PulseTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Info icon for description
            if (description != null && description.isNotEmpty)
              Positioned(
                top: 4,
                right: isMain ? 36 : 4,
                child: GestureDetector(
                  onTap: () => _showPhotoDescription(description ?? ''),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () =>
                    _showDeletePhotoDialog(displayIndex, isExisting: true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: PulseColors.error.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPhotoCard(File photo, int displayIndex, int newPhotoIndex) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PulseRadii.md),
        border: Border.all(
          color: PulseColors.secondary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Photo image
          ClipRRect(
            borderRadius: BorderRadius.circular(PulseRadii.md - 1),
            child: Image.file(
              photo,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // New badge
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PulseColors.secondary,
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
              child: Text(
                'New',
                style: PulseTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                final List<File> newPhotos =
                    ((_formData['newPhotos'] as List<dynamic>?)
                        ?.cast<File>()) ??
                    [];
                setState(() {
                  newPhotos.removeAt(newPhotoIndex);
                  _formData['newPhotos'] = newPhotos;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PulseColors.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _showPhotoSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: PulseColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(PulseRadii.md),
          border: Border.all(
            color: PulseColors.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: PulseColors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: PulseTextStyles.labelSmall.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDescription(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Description'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeletePhotoDialog(int index, {required bool isExisting}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (isExisting) {
                  final List<dynamic> existingPhotos =
                      _formData['photos'] as List<dynamic>? ?? [];
                  existingPhotos.removeAt(index);
                  _formData['photos'] = existingPhotos;
                  // Mark for deletion on backend
                  _formData['deletedPhotoIds'] = [
                    ...(_formData['deletedPhotoIds'] as List? ?? []),
                    // Store the photo ID if available
                  ];
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: PulseColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPhotoSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied) {
          _showPermissionDialog('Camera');
          return;
        }
      } else {
        final photosStatus = await Permission.photos.request();
        if (photosStatus.isDenied) {
          _showPermissionDialog('Photos');
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        final File file = File(image.path);
        setState(() {
          final List<File> newPhotos =
              ((_formData['newPhotos'] as List<dynamic>?)?.cast<File>()) ?? [];
          newPhotos.add(file);
          _formData['newPhotos'] = newPhotos;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'Please grant $permission permission in Settings to add photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show photo details dialog with options to view full screen, set as main, delete, etc.
  void _showPhotoDetails(dynamic photo, int index) {
    final String photoUrl = photo is Map
        ? (photo['url'] ?? photo['photo_url'] ?? '')
        : photo.toString();
    final String? photoId = photo is Map ? photo['id'] : null;
    final bool isMain = photo is Map
        ? (photo['isMain'] ?? photo['isPrimary'] ?? index == 0)
        : index == 0;

    final List<dynamic> existingPhotos =
        _formData['photos'] as List<dynamic>? ?? [];

    // Convert to ProfilePhoto for the dialog
    final profilePhoto = ProfilePhoto(
      id: photoId ?? '',
      url: photoUrl,
      order: index,
      isMain: isMain,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => PhotoDetailsDialog(
        photo: profilePhoto,
        isPrimary: isMain,
        canSetPrimary: !isMain,
        onSetPrimary: isMain
            ? null
            : () {
                Navigator.pop(dialogContext);

                // Dispatch PhotoBloc event to set main photo
                if (photoId != null) {
                  context.read<PhotoBloc>().add(
                    photo_events.SetMainPhoto(photoId),
                  );
                }

                // Also update local state for immediate UI feedback
                setState(() {
                  // Set all photos as not main
                  for (var p in existingPhotos) {
                    if (p is Map) {
                      p['isMain'] = false;
                      p['isPrimary'] = false;
                    }
                  }
                  // Set this photo as main
                  if (photo is Map) {
                    photo['isMain'] = true;
                    photo['isPrimary'] = true;
                  }
                });

                PulseToast.success(context, message: 'Main photo updated');
              },
        onDelete: () {
          Navigator.pop(dialogContext);

          // Dispatch PhotoBloc event to delete photo
          if (photoId != null) {
            context.read<PhotoBloc>().add(photo_events.DeletePhoto(photoId));
          }

          // Show local deletion dialog for immediate feedback
          _showDeletePhotoDialog(index, isExisting: true);
        },
      ),
    );
  }

  /// Navigate to full-screen photo gallery
  void _navigateToPhotoGallery(int initialIndex) {
    final List<dynamic> existingPhotos =
        _formData['photos'] as List<dynamic>? ?? [];
    final List<ProfilePhoto> photoList = existingPhotos.map((photo) {
      if (photo is Map) {
        return ProfilePhoto(
          id: photo['id'] ?? '',
          url: photo['url'] ?? photo['photo_url'] ?? '',
          order: existingPhotos.indexOf(photo),
          isMain: photo['isMain'] ?? photo['isPrimary'] ?? false,
        );
      }
      return ProfilePhoto(
        id: '',
        url: photo.toString(),
        order: existingPhotos.indexOf(photo),
        isMain: false,
      );
    }).toList();

    context.push(
      AppRoutes.photoGallery,
      extra: {'photos': photoList, 'initialIndex': initialIndex},
    );
  }

  /// Show photo reorder bottom sheet
  void _showPhotoReorderSheet() async {
    final List<dynamic> existingPhotos =
        _formData['photos'] as List<dynamic>? ?? [];
    final List<ProfilePhoto> photoList = existingPhotos.map((photo) {
      if (photo is Map) {
        return ProfilePhoto(
          id: photo['id'] ?? '',
          url: photo['url'] ?? photo['photo_url'] ?? '',
          order: existingPhotos.indexOf(photo),
          isMain: photo['isMain'] ?? photo['isPrimary'] ?? false,
        );
      }
      return ProfilePhoto(
        id: '',
        url: photo.toString(),
        order: existingPhotos.indexOf(photo),
        isMain: false,
      );
    }).toList();

    final reorderedPhotos = await showModalBottomSheet<List<ProfilePhoto>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoReorderSheet(
        photos: photoList,
        onReorder: (reordered) {
          Navigator.pop(context, reordered);
        },
      ),
    );

    if (reorderedPhotos != null) {
      setState(() {
        // Update the photos order in _formData
        final updatedPhotos = reorderedPhotos.map((photo) {
          return {
            'id': photo.id,
            'url': photo.url,
            'photo_url': photo.url,
            'isMain': photo.isMain,
            'isPrimary': photo.isMain,
          };
        }).toList();
        _formData['photos'] = updatedPhotos;
      });

      PulseToast.success(context, message: 'Photos reordered successfully');
    }
  }

  Widget _buildWorkEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _controllers['job']!,
          label: 'Job Title',
          hint: 'e.g., Software Engineer',
          icon: Icons.work,
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['company']!,
          label: 'Company',
          hint: 'e.g., Google',
          icon: Icons.business,
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['school']!,
          label: 'School',
          hint: 'e.g., Harvard University',
          icon: Icons.school,
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    final selectedInterests = List<String>.from(_formData['interests'] ?? []);
    
    // Show pre-populated indicator if profile was loaded
    final showPrepopulatedIndicator = _currentProfile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPrepopulatedIndicator)
          Padding(
            padding: const EdgeInsets.only(bottom: PulseSpacing.md),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: PulseColors.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Loaded from your profile',
                  style: PulseTextStyles.labelSmall.copyWith(
                    color: PulseColors.success,
                  ),
                ),
              ],
            ),
          ),
        
        // Use the reusable InterestsSelector widget
        InterestsSelector(
          selectedInterests: selectedInterests,
          onInterestsChanged: (selected) {
            setState(() {
              _formData['interests'] = selected;
              _formData['selectedInterests'] = selected;
            });
          },
          maxInterests: 10,
          minInterests: 1,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    // Convert API gender values to display values
    String convertGenderToDisplay(String? gender) {
      switch (gender?.toUpperCase()) {
        case 'MALE':
          return 'Man';
        case 'FEMALE':
          return 'Woman';
        case 'NON_BINARY':
        case 'NON-BINARY':
          return 'Non-binary';
        default:
          return 'Woman';
      }
    }

    String convertGenderToAPI(String display) {
      switch (display) {
        case 'Man':
          return 'MALE';
        case 'Woman':
          return 'FEMALE';
        case 'Non-binary':
          return 'NON_BINARY';
        default:
          return 'OTHER';
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final currentGender = convertGenderToDisplay(
          _formData['gender']?.toString(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreferenceDropdown(
              title: 'I am',
              value: currentGender,
              options: ['Woman', 'Man', 'Non-binary', 'Other'],
              onChanged: (value) {
                setState(() {
                  _formData['gender'] = convertGenderToAPI(value!);
                });
              },
            ),
            const SizedBox(height: PulseSpacing.lg),
            _buildPreferenceDropdown(
              title: 'Looking for',
              value: _formData['lookingFor']?.toString() ?? 'Men',
              options: ['Men', 'Women', 'Non-binary', 'Everyone'],
              onChanged: (value) {
                setState(() {
                  _formData['lookingFor'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateOfBirthPicker() {
    final DateTime? currentDob = _formData['dateOfBirth'] as DateTime?;
    final int ageChangeCount = _formData['ageChangeCount'] as int? ?? 0;
    final bool canChangeAge = ageChangeCount < 2;
    final int remainingChanges = 2 - ageChangeCount;

    // Calculate current age
    int? currentAge;
    if (currentDob != null) {
      final now = DateTime.now();
      currentAge = now.year - currentDob.year;
      if (now.month < currentDob.month ||
          (now.month == currentDob.month && now.day < currentDob.day)) {
        currentAge--;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Date of Birth *',
              style: PulseTextStyles.titleMedium.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (currentAge != null && canChangeAge) ...[
              const SizedBox(width: PulseSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PulseSpacing.sm,
                  vertical: PulseSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                ),
                child: Text(
                  'Age: $currentAge',
                  style: PulseTextStyles.labelSmall.copyWith(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: PulseSpacing.sm),

        // DOB Picker Button
        InkWell(
          onTap: canChangeAge
              ? () async {
                  final DateTime now = DateTime.now();
                  final DateTime eighteenYearsAgo = DateTime(
                    now.year - 18,
                    now.month,
                    now.day,
                  );
                  final DateTime hundredYearsAgo = DateTime(now.year - 100);

                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: currentDob ?? eighteenYearsAgo,
                    firstDate: hundredYearsAgo,
                    lastDate: eighteenYearsAgo,
                    helpText: 'Select Your Date of Birth',
                    fieldLabelText: 'Date of Birth',
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: PulseColors.primary,
                            onPrimary: Colors.white,
                            surface: PulseColors.surface,
                            onSurface: PulseColors.onSurface,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    // Calculate age from picked date
                    final age = now.year - picked.year;
                    final adjustedAge =
                        (now.month < picked.month ||
                            (now.month == picked.month && now.day < picked.day))
                        ? age - 1
                        : age;

                    if (adjustedAge < 18) {
                      if (!mounted) return;
                      PulseToast.error(
                        context,
                        message: 'You must be at least 18 years old',
                      );
                      return;
                    }

                    setState(() {
                      _formData['dateOfBirth'] = picked;
                      // Backend will calculate age and increment ageChangeCount
                    });
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(PulseRadii.md),
          child: Container(
            padding: const EdgeInsets.all(PulseSpacing.md),
            decoration: BoxDecoration(
              color: canChangeAge
                  ? PulseColors.surfaceVariant.withValues(alpha: 0.5)
                  : PulseColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(PulseRadii.md),
              border: Border.all(
                color: canChangeAge
                    ? PulseColors.outline
                    : PulseColors.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  color: canChangeAge
                      ? PulseColors.primary
                      : PulseColors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: PulseSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDob != null
                            ? '${currentDob.day}/${currentDob.month}/${currentDob.year}'
                            : 'Select your date of birth',
                        style: PulseTextStyles.bodyLarge.copyWith(
                          color: currentDob != null
                              ? PulseColors.onSurface
                              : PulseColors.onSurfaceVariant,
                          fontWeight: currentDob != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (currentAge != null) ...[
                        const SizedBox(height: PulseSpacing.xs),
                        Text(
                          '$currentAge years old',
                          style: PulseTextStyles.bodySmall.copyWith(
                            color: PulseColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: canChangeAge
                      ? PulseColors.primary
                      : PulseColors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Age change limit warning
        if (ageChangeCount > 0) ...[
          const SizedBox(height: PulseSpacing.sm),
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: canChangeAge
                  ? Colors.amber.withValues(alpha: 0.1)
                  : PulseColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PulseRadii.sm),
              border: Border.all(
                color: canChangeAge ? Colors.amber : PulseColors.error,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canChangeAge ? Icons.info_outline : Icons.lock_outline,
                  size: 16,
                  color: canChangeAge ? Colors.amber[700] : PulseColors.error,
                ),
                const SizedBox(width: PulseSpacing.sm),
                Expanded(
                  child: Text(
                    canChangeAge
                        ? 'You can change your age $remainingChanges more time${remainingChanges > 1 ? 's' : ''}'
                        : 'Age change limit reached. You cannot change your date of birth anymore.',
                    style: PulseTextStyles.bodySmall.copyWith(
                      color: canChangeAge
                          ? Colors.amber[900]
                          : PulseColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // First time DOB info
        if (currentDob == null) ...[
          const SizedBox(height: PulseSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: PulseColors.onSurfaceVariant,
              ),
              const SizedBox(width: PulseSpacing.xs),
              Expanded(
                child: Text(
                  'You can change your age up to 2 times after setting it',
                  style: PulseTextStyles.bodySmall.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: PulseTextStyles.titleMedium.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: PulseColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.error),
            ),
            filled: true,
            fillColor: PulseColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceDropdown({
    required String title,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PulseTextStyles.titleMedium.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.primary, width: 2),
            ),
            filled: true,
            fillColor: PulseColors.surfaceVariant.withValues(alpha: 0.5),
          ),
          items: options.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(PulseSpacing.md),
              side: BorderSide(color: PulseColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.md),
              ),
            ),
            child: Text(
              'Cancel',
              style: PulseTextStyles.titleMedium.copyWith(
                color: PulseColors.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: PulseSpacing.md),
        Expanded(
          flex: 2,
          child: PulseButton(text: 'Save Changes', onPressed: _saveSection),
        ),
      ],
    );
  }

  Widget _buildIntentSection() {
    final selectedIntent = _formData['intent'] as String?;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: IntentOptions.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading relationship goals',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.error,
              ),
            ),
          );
        }

        final goals = snapshot.data ?? [];

        if (goals.isEmpty) {
          return Center(
            child: Text(
              'No relationship goals available',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '*What brings you here?*',
                  style: PulseTextStyles.titleMedium.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' *',
                  style: PulseTextStyles.titleMedium.copyWith(
                    color: PulseColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PulseSpacing.md),
            Text(
              'Choose your primary intent. You can explore other features anytime.',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            ...goals.map((option) {
              final isSelected =
                  selectedIntent == option['slug'] ||
                  selectedIntent == option['id'];
              final colorHex = option['color'] as String? ?? '#7E57C2';
              final color = _parseColorFromHex(colorHex);

              return Padding(
                padding: const EdgeInsets.only(bottom: PulseSpacing.md),
                child: GestureDetector(
                  onTap: () {
                    logger.i(
                      '🎯 GestureDetector tap - intent: ${option['slug']}',
                    );
                    setState(() {
                      _formData['intent'] = option['slug'] as String;
                      logger.i('  ✅ Intent updated to: ${option['slug']}');
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(PulseSpacing.lg),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : PulseColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(PulseRadii.lg),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Radio button
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? color : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: PulseSpacing.md),
                        // Icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(PulseRadii.md),
                          ),
                          child: Icon(
                            option['iconData'] as IconData? ?? Icons.explore,
                            color: isSelected
                                ? Colors.white
                                : color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: PulseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['title'] as String? ?? 'Unknown',
                                style: PulseTextStyles.titleMedium.copyWith(
                                  color: PulseColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: PulseSpacing.xs),
                              Text(
                                option['description'] as String? ??
                                    'No description',
                                style: PulseTextStyles.bodyMedium.copyWith(
                                  color: PulseColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  /// Parse color from hex string
  Color _parseColorFromHex(String hexString) {
    try {
      final hex = hexString.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF7E57C2); // Fallback color
    }
  }

  String _getSectionTitle() {
    switch (widget.sectionType) {
      case 'basic_info':
        return 'Basic Information';
      case 'photos':
        return 'Profile Photos';
      case 'work_education':
        return 'Work & Education';
      case 'interests':
        return 'Interests';
      case 'intent':
        return 'Your Primary Intent';
      case 'preferences':
        return 'Dating Preferences';
      default:
        return 'Edit Profile';
    }
  }

  String _getSectionDescription() {
    switch (widget.sectionType) {
      case 'basic_info':
        return 'Update your name, age, and bio to help people get to know you better.';
      case 'photos':
        return 'Add up to 6 photos. Your first photo will be your main profile picture.';
      case 'work_education':
        return 'Share your professional and educational background.';
      case 'interests':
        return 'Select your hobbies and interests to find better matches.';
      case 'intent':
        return 'Help us personalize your experience and show you relevant connections.';
      case 'preferences':
        return 'Set your dating preferences and who you\'re looking for.';
      default:
        return 'Edit your profile information.';
    }
  }

  IconData _getSectionIcon() {
    switch (widget.sectionType) {
      case 'basic_info':
        return Icons.person;
      case 'photos':
        return Icons.photo_library;
      case 'work_education':
        return Icons.work;
      case 'interests':
        return Icons.favorite;
      case 'intent':
        return Icons.psychology;
      case 'preferences':
        return Icons.tune;
      default:
        return Icons.edit;
    }
  }

  /// Validate that required fields are populated
  String? _validateSection() {
    switch (widget.sectionType) {
      case 'intent':
        final intent = _formData['intent'] as String?;
        if (intent == null || intent.isEmpty) {
          return 'Please select your primary intent';
        }
        break;

      case 'photos':
        final existingPhotos =
            (_formData['photos'] as List<dynamic>?)?.isNotEmpty ?? false;
        final newPhotos =
            ((_formData['newPhotos'] as List<dynamic>?)?.cast<File>())
                ?.isNotEmpty ??
            false;
        if (!existingPhotos && !newPhotos) {
          return 'Please add at least 1 photo';
        }
        break;

      case 'interests':
        final interests = _formData['interests'] as List<String>?;
        if (interests == null || interests.isEmpty) {
          return 'Please select at least 1 interest';
        }
        break;

      case 'basic_info':
        final name = _controllers['name']?.text.trim();
        final bio = _controllers['bio']?.text.trim();
        if (name == null || name.isEmpty) {
          return 'Please enter your name';
        }
        if (bio == null || bio.isEmpty) {
          return 'Please enter your bio';
        }
        break;

      case 'work_education':
        // These are optional, so no validation needed
        break;

      case 'preferences':
        // These are optional, so no validation needed
        break;
    }

    return null; // No validation errors
  }

  /// Delete a photo from current photos
  void _saveSection() async {
    // ✅ FIRST: Validate that all required fields are populated
    final validationError = _validateSection();
    if (validationError != null) {
      PulseToast.error(context, message: validationError);
      debugPrint('❌ Validation failed: $validationError');
      return; // Stop here, don't proceed
    }

    if (_formKey.currentState?.validate() ?? false) {
      // Show loading indicator for photo uploads
      if (widget.sectionType == 'photos' &&
          _formData.containsKey('newPhotos')) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Update form data from controllers
      for (final entry in _controllers.entries) {
        _formData[entry.key] = entry.value.text.trim();
      }

      // Note: dateOfBirth is already stored in _formData from the picker
      // Backend will calculate age from dateOfBirth

      // Handle photo uploads if this is the photos section
      if (widget.sectionType == 'photos' &&
          _formData.containsKey('newPhotos')) {
        try {
          final newPhotos =
              (_formData['newPhotos'] as List<dynamic>?)?.cast<File>() ??
              <File>[];

          if (newPhotos.isNotEmpty) {
            // Show uploading message
            if (mounted) {
              PulseToast.success(
                context,
                message: 'Uploading ${newPhotos.length} photo(s)...',
                duration: const Duration(seconds: 2),
              );
            }

            // Upload each new photo and wait for completion
            for (int i = 0; i < newPhotos.length; i++) {
              debugPrint(
                '📸 Uploading photo ${i + 1}/${newPhotos.length}: ${newPhotos[i].path}',
              );

              try {
                // Wait for ProfileBloc upload to complete
                final completer = Completer<void>();

                // Listen to upload completion
                final subscription = context.read<ProfileBloc>().stream.listen((
                  state,
                ) {
                  // Check if this specific photo upload completed
                  if (state.uploadingPhotos.isEmpty &&
                      state.uploadStatus != ProfileStatus.loading) {
                    if (!completer.isCompleted) {
                      completer.complete();
                    }
                  }
                });

                // Dispatch upload event
                context.read<ProfileBloc>().add(
                  UploadPhoto(photoPath: newPhotos[i].path),
                );

                // Wait for upload to complete (with timeout)
                await completer.future
                    .timeout(const Duration(seconds: 30))
                    .catchError((_) {
                      debugPrint(
                        '⚠️ Photo upload timeout or error for photo $i',
                      );
                    });

                subscription.cancel();
              } catch (e) {
                debugPrint('❌ Error uploading photo $i: $e');
              }
            }
          }

          // Remove loading dialog
          if (mounted) Navigator.pop(context);
        } catch (e) {
          // Remove loading dialog
          if (mounted) Navigator.pop(context);

          // Show error
          PulseToast.error(context, message: 'Failed to upload photos: $e');
          return;
        }
      }

      // Save section data to backend based on section type
      try {
        if (widget.sectionType == 'intent' && _formData.containsKey('intent')) {
          // Save intent (relationship goals) to backend
          final intent = _formData['intent'] as String?;
          if (intent != null && intent.isNotEmpty) {
            debugPrint('💾 Saving intent to backend: $intent');
            final apiClient = ServiceLocator.instance.apiClient;
            await apiClient.post(
              '/users/me/profile/goals',
              data: {
                'relationshipGoals': [intent],
              },
            );
            debugPrint('✅ Intent saved to backend');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Warning: Failed to save section data to backend: $e');
        // Don't fail the whole operation, but log it
      }

      // Mark this section as complete in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_${widget.sectionType}_completed', true);
      debugPrint('✅ Marked setup_${widget.sectionType}_completed = true');

      // Show success message
      if (mounted) {
        PulseToast.success(
          context,
          message: '${_getSectionTitle()} updated successfully',
        );
      }

      // Handle navigation based on mode
      if (mounted) {
        if (widget.isEditMode) {
          // Edit mode: pop back to profile edit page
          debugPrint('🔙 Edit mode - popping back');
          context.pop(_formData);
        } else {
          // Setup mode: navigate to next required section or home
          const requiredSections = ['intent', 'photos', 'interests'];
          final currentIndex = requiredSections.indexOf(widget.sectionType);

          if (currentIndex < requiredSections.length - 1) {
            // There's a next required section - navigate to it
            final nextSection = requiredSections[currentIndex + 1];
            debugPrint(
              '➡️ Setup mode - navigating to next section: $nextSection',
            );
            context.replace(
              AppRoutes.profileSetup,
              extra: {'sectionType': nextSection},
            );
          } else {
            // All required sections are done - navigate to home
            debugPrint(
              '✅ Setup mode - all sections complete! Navigating to home',
            );
            context.go(AppRoutes.home);
          }
        }
      }
    }
  }
}
