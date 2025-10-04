import 'dart:io';

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
  final Logger _logger;
  UserProfile? _originalProfile; // For delta tracking
  List<String> _tempPhotoIds = []; // Track temp uploads

  ProfileBloc({
    required ProfileService profileService,
    required PhotoManagerService photoManager,
    Logger? logger,
  }) : _profileService = profileService,
       _photoManager = photoManager,
       _logger = logger ?? Logger(),
        super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
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
      emit(state.copyWith(updateStatus: ProfileStatus.loading));
      
      // STEP 1: Save photos (confirm temps + delete marked) before profile update
      List<String> confirmedMediaIds = [];
      if (_tempPhotoIds.isNotEmpty ||
          _photoManager.getPhotosToDelete().isNotEmpty) {
        _logger.i('💾 Saving photos before profile update...');
        final photoResult = await _photoManager.savePhotos(
          tempPhotoIds: _tempPhotoIds,
        );

        if (photoResult.hasFailures) {
          _logger.w(
            '⚠️ Some photo operations failed: ${photoResult.allFailures}',
          );
        }

        // Collect confirmed media IDs for syncing
        confirmedMediaIds = photoResult.confirmResult.confirmed;
        _tempPhotoIds.clear();
      }

      // STEP 2: Sync confirmed photos with profile (link Media to User.photos)
      if (confirmedMediaIds.isNotEmpty && event.profile.photos.isNotEmpty) {
        _logger.i('🔗 Syncing ${confirmedMediaIds.length} photos with profile...');
        try {
          // Map profile photos to sync format
          final photosToSync = event.profile.photos
              .where((photo) => confirmedMediaIds.contains(photo.id))
              .map((photo) => ProfilePhotoSync(
                    mediaId: photo.id,
                    description: photo.description,
                    order: photo.order,
                    isMain: photo.isMain,
                  ))
              .toList();

          if (photosToSync.isNotEmpty) {
            final syncedPhotos = await _profileService.syncPhotos(
              photos: photosToSync,
            );
            
            _logger.i('✅ Photos synced successfully: ${syncedPhotos.length}');
            
            // Update profile with synced photo data (may have server-side changes)
            final updatedProfile = event.profile.copyWith(
              photos: syncedPhotos,
            );
            
            // Use synced profile for update
            final finalProfile = await _profileService.updateProfile(
              updatedProfile,
              originalProfile: _originalProfile,
            );
            _originalProfile = finalProfile;
            
            emit(state.copyWith(
              updateStatus: ProfileStatus.success,
              profile: finalProfile,
            ));
            return;
          }
        } catch (syncError) {
          _logger.e('❌ Photo sync failed: $syncError');
          // Continue with profile update even if sync fails
        }
      }

      // STEP 3: Update profile with delta tracking
      final updatedProfile = await _profileService.updateProfile(
        event.profile,
        originalProfile: _originalProfile,
      );
      _originalProfile = updatedProfile; // Update for next edit
      
      emit(state.copyWith(
        updateStatus: ProfileStatus.success,
        profile: updatedProfile,
      ));
    } catch (e) {
      emit(state.copyWith(
        updateStatus: ProfileStatus.error,
        error: 'Failed to update profile: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(uploadStatus: ProfileStatus.loading));
      
      // Upload to temp storage for instant preview
      final result = await _photoManager.uploadTempPhoto(File(event.photoPath));
      _tempPhotoIds.add(result.mediaId);

      _logger.i('📸 Temp photo uploaded: ${result.mediaId}');
      
      // Build full URL from relative path
      final fullUrl = result.url.startsWith('http')
          ? result.url
          : 'http://localhost:3000${result.url}';

      _logger.i('🔗 Full photo URL: $fullUrl');
      
      // Add to profile for preview (not confirmed yet)
      if (state.profile != null) {
        final updatedPhotos = List<ProfilePhoto>.from(state.profile!.photos)
          ..add(ProfilePhoto(
              id: result.mediaId,
              url: fullUrl, // Full URL for preview
            order: state.profile!.photos.length,
          ));
        
        final updatedProfile = state.profile!.copyWith(photos: updatedPhotos);
        
        emit(state.copyWith(
          uploadStatus: ProfileStatus.success,
          profile: updatedProfile,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: ProfileStatus.error,
        error: 'Failed to upload photo: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Mark for deletion (deferred until save)
      _photoManager.markPhotoForDeletion(event.photoUrl);
      _tempPhotoIds.remove(event.photoUrl); // Remove from temp list if present

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
    _tempPhotoIds.clear();
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
