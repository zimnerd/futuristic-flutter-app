import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/photo_manager_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

enum ProfileStatus { initial, loading, loaded, error, success }

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;
  final PhotoManagerService _photoManager;
  final Logger _logger = Logger();
  UserProfile? _originalProfile;

  ProfileBloc({
    required ProfileService profileService,
    required PhotoManagerService photoManager,
  }) : _profileService = profileService,
       _photoManager = photoManager,
        super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
    on<UploadMultiplePhotos>(_onUploadMultiplePhotos);
    on<DeletePhoto>(_onDeletePhoto);
    on<CancelProfileChanges>(_onCancelProfileChanges);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProfileStatus.loading));
      
      final profile = await _profileService.getCurrentProfile();
      _originalProfile = profile; // Store for delta tracking
      
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        updateStatus: ProfileStatus.initial, // Reset update status on profile reload
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Failed to load profile: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      _logger.i('� Updating profile...');
      emit(state.copyWith(updateStatus: ProfileStatus.loading));

      // Photos are already uploaded directly to permanent storage
      // Just update profile data without photo sync
      _logger.i('📝 Updating profile data...');
      final updatedProfile = await _profileService.updateProfile(
        event.profile,
        originalProfile: _originalProfile,
      );
      _originalProfile = updatedProfile;

      _logger.i('✅ Profile updated successfully');

      emit(
        state.copyWith(
          updateStatus: ProfileStatus.success,
          profile: updatedProfile,
        ),
      );
    } catch (e) {
      _logger.e('❌ Profile update failed: $e');
      emit(
        state.copyWith(
          updateStatus: ProfileStatus.error,
          error: 'Failed to update profile: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      _logger.i('📸 Uploading photo directly to permanent storage...');
      emit(state.copyWith(uploadStatus: ProfileStatus.loading));

      // Upload directly to permanent storage (returns URL)
      final photoUrl = await _profileService.uploadPhoto(event.photoPath);

      _logger.i('✅ Photo uploaded permanently: $photoUrl');

      // Add to profile
      if (state.profile != null) {
        final updatedPhotos = List<ProfilePhoto>.from(state.profile!.photos)
          ..add(
            ProfilePhoto(
              id: photoUrl.split('/').last, // Use filename as temp ID
              url: photoUrl,
              order: state.profile!.photos.length,
            ),
          );

        final updatedProfile = state.profile!.copyWith(photos: updatedPhotos);

        emit(
          state.copyWith(
            uploadStatus: ProfileStatus.success,
            profile: updatedProfile,
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Photo upload failed: $e');
      emit(
        state.copyWith(
          uploadStatus: ProfileStatus.error,
          error: 'Failed to upload photo: ${e.toString()}',
        ),
      );
    }
  }

  /// Upload multiple photos directly to permanent storage
  Future<void> _onUploadMultiplePhotos(
    UploadMultiplePhotos event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      _logger.i(
        '📸 Uploading ${event.photoPaths.length} photos directly to permanent storage...',
      );
      emit(state.copyWith(uploadStatus: ProfileStatus.loading));

      final newPhotos = <ProfilePhoto>[];
      final startOrder = state.profile?.photos.length ?? 0;
      
      // Upload each photo directly to permanent storage
      for (int i = 0; i < event.photoPaths.length; i++) {
        final photoUrl = await _profileService.uploadPhoto(event.photoPaths[i]);
        
        newPhotos.add(
          ProfilePhoto(
            id: photoUrl.split('/').last, // Use filename as temp ID
            url: photoUrl,
            order: startOrder + i,
          ),
        );
        
        _logger.i(
          '✅ Photo ${i + 1}/${event.photoPaths.length} uploaded: $photoUrl',
        );
      }

      // Add all photos to profile
      if (state.profile != null) {
        final updatedPhotos = List<ProfilePhoto>.from(state.profile!.photos)
          ..addAll(newPhotos);

        final updatedProfile = state.profile!.copyWith(photos: updatedPhotos);

        _logger.i('✅ All ${newPhotos.length} photos uploaded successfully');
        emit(
          state.copyWith(
            uploadStatus: ProfileStatus.success,
            profile: updatedProfile,
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Multiple photo upload failed: $e');
      emit(
        state.copyWith(
          uploadStatus: ProfileStatus.error,
          error: 'Failed to upload photos: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Mark for deletion (deferred until save)
      _photoManager.markPhotoForDeletion(event.photoUrl);

      _logger.i('🗑️ Photo marked for deletion: ${event.photoUrl}');
      
      // Remove from UI immediately
      if (state.profile != null) {
        final updatedPhotos = state.profile!.photos
            .where((photo) => photo.url != event.photoUrl)
            .toList();
        
        final updatedProfile = state.profile!.copyWith(photos: updatedPhotos);
        
        // Reset updateStatus to prevent stale "saved successfully" message
        emit(
          state.copyWith(
            profile: updatedProfile,
            updateStatus: ProfileStatus.initial,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to delete photo: ${e.toString()}',
      ));
    }
  }

  /// Cancel all pending profile changes
  void _onCancelProfileChanges(
    CancelProfileChanges event,
    Emitter<ProfileState> emit,
  ) {
    _logger.i('🚫 Cancelling profile changes');
    _photoManager.cancelPhotoChanges();
  }

  /// Update privacy settings only (separate from full profile update)
  Future<void> _onUpdatePrivacySettings(
    UpdatePrivacySettings event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      _logger.i('🔒 Updating privacy settings via dedicated endpoint');
      emit(state.copyWith(updateStatus: ProfileStatus.loading));
      
      // Call dedicated privacy update method
      await _profileService.updatePrivacySettings(event.settings);
      
      // Reload profile to get updated privacy settings
      final profile = await _profileService.getCurrentProfile();
      
      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: profile,
        updateStatus: ProfileStatus.success,
      ));
      
      _logger.i('✅ Privacy settings updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating privacy settings: $e');
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Failed to update privacy settings: ${e.toString()}',
        updateStatus: ProfileStatus.error,
      ));
    }
  }
}
