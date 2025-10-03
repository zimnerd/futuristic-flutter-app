// ignore_for_file: unused_element, unused_local_variable
/// **EXAMPLE: Profile Edit Screen with Temp Upload Pattern**
/// 
/// This file demonstrates how to integrate PhotoManagerService with ProfileBloc
/// for profile editing with temporary photo uploads.
/// 
/// **Key Concepts**:
/// 1. Track original profile for comparison
/// 2. Use temp photo uploads for immediate preview
/// 3. Mark photos for deletion without immediate action
/// 4. Confirm/delete on save, auto-cleanup on cancel
/// 
/// **File Location**: Copy patterns to your actual profile edit screens:
/// - profile_screen.dart
/// - profile_edit_screen.dart
/// - enhanced_profile_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/profile_model.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';

/// Example profile edit screen showing temp upload integration
class ProfileEditScreenExample extends StatefulWidget {
  final String userId;

  const ProfileEditScreenExample({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileEditScreenExample> createState() => _ProfileEditScreenExampleState();
}

class _ProfileEditScreenExampleState extends State<ProfileEditScreenExample> {
  // Track original profile loaded from server
  UserProfile? _originalProfile;
  
  // Track edited profile (local state)
  UserProfile? _editedProfile;
  
  // Track temp photo previews (URLs from temp uploads)
  final List<String> _tempPhotoUrls = [];
  
  // Track photos marked for deletion
  final Set<String> _photosMarkedForDeletion = {};
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load profile on init
    context.read<ProfileBloc>().add(LoadProfile(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            // Store original profile when first loaded
            if (_originalProfile == null) {
              setState(() {
                _originalProfile = state.profile;
                _editedProfile = state.profile.copyWith(); // Clone for editing
              });
            }
          } else if (state is PhotoUploaded) {
            // Add temp photo URL to preview list
            setState(() {
              _tempPhotoUrls.add(state.photo.url);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo uploaded (temp)')),
            );
          } else if (state is PhotoDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo marked for deletion')),
            );
          } else if (state is ProfileUpdated) {
            // Profile saved successfully
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated!')),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_editedProfile == null) {
            return const Center(child: Text('Loading profile...'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photos section
                _buildPhotosSection(),
                const SizedBox(height: 24),
                
                // Bio field
                TextFormField(
                  initialValue: _editedProfile!.bio,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setState(() {
                      _editedProfile = _editedProfile!.copyWith(bio: value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Interests (example)
                const Text(
                  'Interests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: _editedProfile!.interests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      onDeleted: () => _handleRemoveInterest(interest),
                    );
                  }).toList(),
                ),
                
                // Add more fields as needed...
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build photos section with temp uploads
  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _handleAddPhoto,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Display existing photos (not marked for deletion)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Existing photos from profile
            ..._editedProfile!.photos
                .where((photo) => !_photosMarkedForDeletion.contains(photo.id))
                .map((photo) => _buildPhotoTile(
                      url: photo.url,
                      onDelete: () => _handleDeleteExistingPhoto(photo.id),
                      isTemp: false,
                    )),
            
            // Temp photos (not yet confirmed)
            ..._tempPhotoUrls.map((url) => _buildPhotoTile(
                  url: url,
                  onDelete: () => _handleRemoveTempPhoto(url),
                  isTemp: true,
                )),
          ],
        ),
      ],
    );
  }

  /// Build single photo tile
  Widget _buildPhotoTile({
    required String url,
    required VoidCallback onDelete,
    required bool isTemp,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
          child: isTemp
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(
                        'TEMP',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Handle adding new photo
  Future<void> _handleAddPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      // Dispatch UploadPhoto event - will upload to temp storage
      context.read<ProfileBloc>().add(UploadPhoto(
            userId: widget.userId,
            imagePath: image.path,
            isPrimary: _editedProfile!.photos.isEmpty,
            order: _editedProfile!.photos.length,
          ));
    }
  }

  /// Handle deleting existing photo (mark for deletion)
  void _handleDeleteExistingPhoto(String photoId) {
    setState(() {
      _photosMarkedForDeletion.add(photoId);
    });
    
    // Dispatch DeletePhoto event - will mark for deletion
    context.read<ProfileBloc>().add(DeletePhoto(
          userId: widget.userId,
          photoId: photoId,
        ));
  }

  /// Handle removing temp photo (not yet confirmed)
  void _handleRemoveTempPhoto(String url) {
    setState(() {
      _tempPhotoUrls.remove(url);
    });
    
    // Could dispatch event to cancel temp upload if needed
    // For now, temp files will auto-cleanup after 24 hours
  }

  /// Handle removing interest
  void _handleRemoveInterest(String interest) {
    setState(() {
      final interests = List<String>.from(_editedProfile!.interests);
      interests.remove(interest);
      _editedProfile = _editedProfile!.copyWith(interests: interests);
    });
  }

  /// Handle save button
  void _handleSave() {
    if (_editedProfile == null) return;

    // Dispatch UpdateProfile event
    // ProfileBloc will:
    // 1. Confirm temp photos (move to permanent)
    // 2. Delete marked photos
    // 3. Update profile fields (only changed fields)
    context.read<ProfileBloc>().add(UpdateProfile(
          userId: widget.userId,
          bio: _editedProfile!.bio,
          interests: _editedProfile!.interests,
          // Add other fields as needed
        ));
  }

  /// Handle cancel button
  void _handleCancel() {
    // Dispatch CancelProfileChanges event
    // This will:
    // 1. Clear temp photo IDs
    // 2. Clear deletion markers
    // 3. Temp files will auto-cleanup after 24 hours
    context.read<ProfileBloc>().add(const CancelProfileChanges());
    
    Navigator.pop(context);
  }
}

/// **Integration Checklist**:
/// 
/// ✅ 1. Inject PhotoManagerService into ProfileBloc
/// ✅ 2. Update ProfileBloc event handlers:
///    - _onUploadPhoto: Use photoManager.uploadTempPhoto()
///    - _onDeletePhoto: Use photoManager.markPhotoForDeletion()
///    - _onUpdateProfile: Call photoManager.savePhotos() first
/// ✅ 3. Add CancelProfileChanges event and handler
/// 
/// ⏳ 4. Update UI screens:
///    - Track original profile on load
///    - Show temp photo previews with "TEMP" indicator
///    - Mark photos for deletion (visual feedback)
///    - Handle save: Confirm temps + delete marked
///    - Handle cancel: Clear all pending changes
/// 
/// ⏳ 5. Testing:
///    - Upload photo → See temp preview → Save → Photo confirmed
///    - Delete photo → Marked → Save → Photo deleted
///    - Cancel → All changes discarded → Temp cleanup
///    - Multiple photos → Parallel operations
///    - Network errors → Proper error handling

/// **Key Points**:
/// 
/// - **Immediate Upload**: Photos upload to temp storage on selection (instant preview)
/// - **Delayed Confirmation**: Photos only confirmed when user clicks "Save"
/// - **Safe Deletion**: Photos marked for deletion, actual delete on "Save"
/// - **Auto-cleanup**: Temp files automatically deleted after 24 hours
/// - **Visual Feedback**: Temp photos show "TEMP" indicator, deleted photos hidden
/// - **No Orphans**: Cancel clears all pending changes, preventing orphaned uploads
