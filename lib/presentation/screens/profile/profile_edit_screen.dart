import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/profile/photo_grid.dart';
import '../../widgets/profile/profile_form.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();

  List<String> _selectedInterests = [];
  String _selectedGender = 'Woman';
  String _selectedPreference = 'Men';
  List<String> _photos = [];
  bool _hasPopulatedFields = false;
  
  // Delta tracking and temp upload state
  UserProfile?
  _originalProfile; // Store original for comparison (future delta tracking)
  final List<String> _tempPhotoUrls =
      []; // Track temp uploads for visual indicator
  final Set<String> _photosMarkedForDeletion = {}; // Track deletions

  /// Gets the current user ID from the AuthBloc state
  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    _originalProfile = profile; // Store for delta tracking
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _ageController.text = profile.age.toString();
    _jobController.text = profile.job ?? '';
    _companyController.text = profile.company ?? '';
    _schoolController.text = profile.school ?? '';
    _selectedInterests = List.from(profile.interests);
    _selectedGender = profile.gender ?? '';
    _selectedPreference = profile.lookingFor ?? 'Men';
    _photos = profile.photos.map((photo) => photo.url).toList();
  }

  /// Handle adding new photo via BLoC event
  void _handleAddPhoto(String photoPath) {
    // Dispatch UploadPhoto event - PhotoManagerService will upload to temp storage
    context.read<ProfileBloc>().add(UploadPhoto(photoPath: photoPath));
  }

  /// Handle deleting photo via BLoC event
  void _handleDeletePhoto(String photoUrl) {
    // Check if this is a temp photo (not yet saved)
    if (_tempPhotoUrls.contains(photoUrl)) {
      // Remove from temp list and local photos
      setState(() {
        _tempPhotoUrls.remove(photoUrl);
        _photos.remove(photoUrl);
      });
      // Temp photos don't need deletion event, they'll auto-cleanup
    } else {
      // Mark existing photo for deletion
      setState(() {
        _photosMarkedForDeletion.add(photoUrl);
        _photos.remove(photoUrl);
      });
      // Dispatch DeletePhoto event for backend tracking
      context.read<ProfileBloc>().add(DeletePhoto(photoUrl: photoUrl));
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProfile = UserProfile(
        id: _currentUserId ?? 'fallback-user-id',
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 18,
        photos: _photos.map((url) => ProfilePhoto(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: url,
          order: _photos.indexOf(url),
        )).toList(),
        interests: _selectedInterests,
        location: UserLocation(
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
        verified: false,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: updatedProfile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            // Check if there are pending changes
            final hasPendingChanges =
                _tempPhotoUrls.isNotEmpty ||
                _photosMarkedForDeletion.isNotEmpty;
            if (hasPendingChanges) {
              _showCancelConfirmation();
            } else {
              Navigator.of(context).pop();
            }
          },
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
          BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state.updateStatus == ProfileStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: PulseColors.success,
                  ),
                );
                Navigator.of(context).pop();
              } else if (state.updateStatus == ProfileStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error ?? 'Failed to update profile'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return TextButton(
                onPressed: state.updateStatus == ProfileStatus.loading
                    ? null
                    : _saveProfile,
                child: state.updateStatus == ProfileStatus.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            PulseColors.primary,
                          ),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: PulseColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // Listen for photo upload events to track temp photos
          if (state.uploadStatus == ProfileStatus.success) {
            // Photo uploaded to temp - add to preview list
            if (state.profile != null && state.profile!.photos.isNotEmpty) {
              final latestPhotoUrl = state.profile!.photos.last.url;
              // Only add if not already in the list (avoid duplicates)
              if (!_photos.contains(latestPhotoUrl)) {
                setState(() {
                  _tempPhotoUrls.add(latestPhotoUrl);
                  _photos.add(latestPhotoUrl);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo uploaded (preview)'),
                    backgroundColor: PulseColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else if (state.uploadStatus == ProfileStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to upload photo: ${state.error ?? "Unknown error"}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              ),
            );
          }

          if (state.status == ProfileStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? 'Failed to load profile',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PulseButton(
                    text: 'Retry',
                    onPressed: () {
                      context.read<ProfileBloc>().add(LoadProfile());
                    },
                  ),
                ],
              ),
            );
          }

          if (state.profile != null && !_hasPopulatedFields) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields(state.profile!);
              setState(() {
                _hasPopulatedFields = true;
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotosSection(),
                  const SizedBox(height: 24),
                  ProfileForm(
                    nameController: _nameController,
                    bioController: _bioController,
                    ageController: _ageController,
                    jobController: _jobController,
                    companyController: _companyController,
                    schoolController: _schoolController,
                    selectedGender: _selectedGender,
                    selectedPreference: _selectedPreference,
                    selectedInterests: _selectedInterests,
                    onGenderChanged: (value) => setState(() => _selectedGender = value),
                    onPreferenceChanged: (value) => setState(() => _selectedPreference = value),
                    onInterestsChanged: (interests) => setState(() => _selectedInterests = interests),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add up to 6 photos. The first photo will be your main profile picture.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        _buildPhotoGridWithTempTracking(),
      ],
    );
  }

  /// Build photo grid with temp upload tracking
  /// Note: Temp photos are tracked internally and will be confirmed on save
  Widget _buildPhotoGridWithTempTracking() {
    final hasPendingChanges =
        _tempPhotoUrls.isNotEmpty || _photosMarkedForDeletion.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPendingChanges)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
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
                      '• ${_tempPhotoUrls.length} new photo(s) to upload',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_photosMarkedForDeletion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '• ${_photosMarkedForDeletion.length} photo(s) to delete',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Click Save to confirm changes',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        _PhotoGridWithTempIndicators(
          photos: _photos,
          tempPhotoUrls: _tempPhotoUrls,
          onAddPhoto: _handleAddPhoto,
          onDeletePhoto: _handleDeletePhoto,
          maxPhotos: 6,
        ),
      ],
    );
  }

  /// Show confirmation dialog before cancelling
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              // Cancel profile changes (clears temp photos)
              context.read<ProfileBloc>().add(const CancelProfileChanges());
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Custom PhotoGrid wrapper that integrates with BLoC events
class _PhotoGridWithTempIndicators extends StatelessWidget {
  final List<String> photos;
  final List<String> tempPhotoUrls;
  final Function(String) onAddPhoto;
  final Function(String) onDeletePhoto;
  final int maxPhotos;

  const _PhotoGridWithTempIndicators({
    required this.photos,
    required this.tempPhotoUrls,
    required this.onAddPhoto,
    required this.onDeletePhoto,
    this.maxPhotos = 6,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoGrid(
      photos: photos,
      onPhotosChanged: (updatedPhotos) {
        // Handle photo changes - determine if it's an add or delete
        if (updatedPhotos.length > photos.length) {
          // Photo added - get the new photo path
          final newPhoto = updatedPhotos.last;
          onAddPhoto(newPhoto);
        } else if (updatedPhotos.length < photos.length) {
          // Photo deleted - find which one was removed
          final deletedPhoto = photos.firstWhere(
            (photo) => !updatedPhotos.contains(photo),
            orElse: () => '',
          );
          if (deletedPhoto.isNotEmpty) {
            onDeletePhoto(deletedPhoto);
          }
        }
        // Note: Reordering is handled internally by PhotoGrid
      },
      maxPhotos: maxPhotos,
    );
  }
}

