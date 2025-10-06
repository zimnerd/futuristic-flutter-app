import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_button.dart';

/// Profile section edit screen for editing individual profile sections
class ProfileSectionEditScreen extends StatefulWidget {
  final String sectionType;
  final Map<String, dynamic>? initialData;

  const ProfileSectionEditScreen({
    super.key,
    required this.sectionType,
    this.initialData,
  });

  @override
  State<ProfileSectionEditScreen> createState() => _ProfileSectionEditScreenState();
}

class _ProfileSectionEditScreenState extends State<ProfileSectionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _formData = Map.from(widget.initialData ?? {});
    _initializeControllers();
  }

  void _initializeControllers() {
    switch (widget.sectionType) {
      case 'basic_info':
        _controllers['name'] = TextEditingController(text: _formData['name'] ?? '');
        // Age controller removed - now using dateOfBirth directly
        _controllers['bio'] = TextEditingController(text: _formData['bio'] ?? '');
        break;
      case 'work_education':
        _controllers['job'] = TextEditingController(text: _formData['job'] ?? '');
        _controllers['company'] = TextEditingController(text: _formData['company'] ?? '');
        _controllers['school'] = TextEditingController(text: _formData['school'] ?? '');
        break;
      case 'photos':
        // Photos are handled separately with PhotoPickerWidget
        break;
      case 'interests':
        // Interests are handled separately as a list
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

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
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
            padding: const EdgeInsets.all(PulseSpacing.lg),
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
    );
  }

  Widget _buildSectionDescription() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            child: Icon(
              _getSectionIcon(),
              color: Colors.white,
              size: 24,
            ),
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
    final List<File> newPhotos = _formData['newPhotos'] as List<File>? ?? [];

    // Total photo count
    final int totalPhotos = existingPhotos.length + newPhotos.length;
    
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
                child: Text(
                  'Add up to 6 photos ($totalPhotos/6). Your first photo will be your main profile picture.',
                  style: PulseTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PulseSpacing.lg),

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
    final String photoUrl = photo is Map
        ? (photo['url'] ?? photo['photo_url'] ?? '')
        : photo.toString();
    final String? description = photo is Map ? photo['description'] : null;
    final bool isMain = photo is Map
        ? (photo['isMain'] ?? photo['isPrimary'] ?? displayIndex == 0)
        : displayIndex == 0;

    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                onTap: () => _showPhotoDescription(description),
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
                    _formData['newPhotos'] as List<File>? ?? [];
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
              _formData['newPhotos'] as List<File>? ?? [];
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
    final availableInterests = [
      'Music', 'Travel', 'Fitness', 'Photography', 'Cooking', 'Reading',
      'Movies', 'Art', 'Sports', 'Gaming', 'Dancing', 'Hiking',
      'Yoga', 'Coffee', 'Wine', 'Fashion', 'Technology', 'Animals',
    ];

    final selectedInterests = List<String>.from(_formData['interests'] ?? []);

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your interests (max 10)',
              style: PulseTextStyles.titleMedium.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: PulseSpacing.md),
            Text(
              'Choose what you\'re passionate about to help people understand you better.',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Wrap(
              spacing: PulseSpacing.sm,
              runSpacing: PulseSpacing.sm,
              children: availableInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected && selectedInterests.length < 10) {
                        selectedInterests.add(interest);
                      } else if (!selected) {
                        selectedInterests.remove(interest);
                      }
                      _formData['interests'] = selectedInterests;
                    });
                  },
                  selectedColor: PulseColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: PulseColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? PulseColors.primary : PulseColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: PulseSpacing.md),
            Text(
              '${selectedInterests.length}/10 selected',
              style: PulseTextStyles.bodySmall.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferencesSection() {
    // Convert API gender values to display values
    String _convertGenderToDisplay(String? gender) {
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

    String _convertGenderToAPI(String display) {
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
        final currentGender = _convertGenderToDisplay(
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
                  _formData['gender'] = _convertGenderToAPI(value!);
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You must be at least 18 years old'),
                          backgroundColor: PulseColors.error,
                        ),
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
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
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
          child: PulseButton(
            text: 'Save Changes',
            onPressed: _saveSection,
          ),
        ),
      ],
    );
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
      case 'preferences':
        return Icons.tune;
      default:
        return Icons.edit;
    }
  }

  /// Delete a photo from current photos
  void _saveSection() async {
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
          final newPhotos = _formData['newPhotos'] as List<File>;

          // Upload each new photo using ProfileBloc
          for (int i = 0; i < newPhotos.length; i++) {
            debugPrint(
              '📸 Uploading photo ${i + 1}/${newPhotos.length}: ${newPhotos[i].path}',
            );

            context.read<ProfileBloc>().add(
              UploadPhoto(photoPath: newPhotos[i].path),
            );
          }

          // Remove loading dialog
          if (mounted) Navigator.pop(context);

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Uploading ${newPhotos.length} photo(s)...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Remove loading dialog
          if (mounted) Navigator.pop(context);

          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload photos: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      // Navigate back with the updated data
      context.pop(_formData);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getSectionTitle()} updated successfully'),
          backgroundColor: PulseColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}