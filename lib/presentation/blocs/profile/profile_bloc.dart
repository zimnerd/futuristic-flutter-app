import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/photo_manager_service.dart';
import '../../../core/services/error_handler.dart';

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
    on<RetryPhotoUpload>(_onRetryPhotoUpload);
    on<ClearUploadProgress>(_onClearUploadProgress);
    on<CancelProfileChanges>(_onCancelProfileChanges);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Check if we have valid cached data that's not stale (unless force refresh)
      // Must have: profile data, valid lastFetchTime, and cache not stale
      final hasValidCache =
          state.profile != null &&
          state.lastFetchTime != null &&
          !state.isCacheStale;

      if (!event.forceRefresh && hasValidCache) {
        _logger.d(
          '✅ Using cached profile (age: ${DateTime.now().difference(state.lastFetchTime!).inMinutes} min)',
        );
        _logger.d('📊 Cached profile data:');
        _logger.d('   - ID: ${state.profile?.id}');
        _logger.d('   - Name: ${state.profile?.name}');
        _logger.d(
          '   - Bio: ${state.profile?.bio.substring(0, state.profile!.bio.length > 50 ? 50 : state.profile!.bio.length)}...',
        );
        _logger.d('   - Photos: ${state.profile?.photos.length ?? 0}');
        _logger.d(
          '   - Job: ${state.profile?.job ?? state.profile?.occupation}',
        );
        _logger.d('   - Status: ${state.status}');

        // Force state change by emitting loading first, then loaded
        // This ensures BlocConsumer listener fires even with cached data
        _logger.d('🔄 Forcing state change to trigger listener');
        if (state.status == ProfileStatus.loaded) {
          // Briefly emit loading to force state change
          emit(state.copyWith(status: ProfileStatus.loading));
          _logger.d('   - Emitted: ProfileStatus.loading');
        }
        // Then emit loaded state to trigger UI update
        emit(state.copyWith(status: ProfileStatus.loaded));
        _logger.d('   - Emitted: ProfileStatus.loaded');
        return;
      }

      _logger.i(
        '🔄 Fetching profile from server (force: ${event.forceRefresh}, hasCache: ${state.profile != null}, stale: ${state.isCacheStale})',
      );
      emit(state.copyWith(status: ProfileStatus.loading));
      
      final profile = await _profileService.getCurrentProfile();
      _originalProfile = profile; // Store for delta tracking
      
      _logger.i('📊 Profile fetched from server:');
      _logger.i('   - ID: ${profile.id}');
      _logger.i('   - Name: ${profile.name}');
      _logger.i('   - Photos: ${profile.photos.length}');
      
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
          lastFetchTime: DateTime.now(), // Mark cache time
        updateStatus: ProfileStatus.initial, // Reset update status on profile reload
      ));
    } catch (e) {
      _logger.e('❌ Failed to load profile: $e');
      final errorMessage = ErrorHandler.handleError(e, showDialog: false);
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: errorMessage,
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

      // Use the returned profile data and update cache timestamp
      emit(
        state.copyWith(
          updateStatus: ProfileStatus.success,
          profile: updatedProfile,
          lastFetchTime: DateTime.now(), // Update cache time with fresh data
        ),
      );
    } catch (e) {
      _logger.e('❌ Profile update failed: $e');
      final errorMessage = ErrorHandler.handleError(e, showDialog: false);
      emit(
        state.copyWith(
          updateStatus: ProfileStatus.error,
          error: errorMessage,
        ),
      );
    }
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final tempId =
        'temp_${event.photoPath.split('/').last}_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      _logger.i('📸 Uploading photo directly to permanent storage...');
      
      // Add to uploading map with uploading state
      final newUploadingPhotos = Map<String, PhotoUploadProgress>.from(
        state.uploadingPhotos,
      );
      newUploadingPhotos[tempId] = PhotoUploadProgress(
        tempId: tempId,
        localPath: event.photoPath,
        state: PhotoUploadState.uploading,
      );

      emit(
        state.copyWith(
          uploadStatus: ProfileStatus.loading,
          uploadingPhotos: newUploadingPhotos,
        ),
      );

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

        // Update uploading state to success
        final successUploadingPhotos = Map<String, PhotoUploadProgress>.from(
          state.uploadingPhotos,
        );
        successUploadingPhotos[tempId] = PhotoUploadProgress(
          tempId: tempId,
          localPath: event.photoPath,
          state: PhotoUploadState.success,
        );

        emit(
          state.copyWith(
            uploadStatus: ProfileStatus.success,
            profile: updatedProfile,
            uploadingPhotos: successUploadingPhotos,
            lastFetchTime: DateTime.now(),
          ),
        );

        // Auto-clear success state after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        final clearedUploadingPhotos = Map<String, PhotoUploadProgress>.from(
          state.uploadingPhotos,
        );
        clearedUploadingPhotos.remove(tempId);
        emit(state.copyWith(uploadingPhotos: clearedUploadingPhotos));
      }
    } catch (e) {
      _logger.e('❌ Photo upload failed: $e');
      final errorMessage = ErrorHandler.handleError(e, showDialog: false);
      
      // Update uploading state to failed
      final failedUploadingPhotos = Map<String, PhotoUploadProgress>.from(
        state.uploadingPhotos,
      );
      failedUploadingPhotos[tempId] = PhotoUploadProgress(
        tempId: tempId,
        localPath: event.photoPath,
        state: PhotoUploadState.failed,
        error: errorMessage,
      );
      
      emit(
        state.copyWith(
          uploadStatus: ProfileStatus.error,
          error: errorMessage,
          uploadingPhotos: failedUploadingPhotos,
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
      final errorMessage = ErrorHandler.handleError(e, showDialog: false);
      emit(
        state.copyWith(
          uploadStatus: ProfileStatus.error,
          error: errorMessage,
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
      final errorMessage = ErrorHandler.handleError(e, showDialog: false);
      emit(state.copyWith(
        error: errorMessage,
      ));
    }
  }

  Future<void> _onRetryPhotoUpload(
    RetryPhotoUpload event,
    Emitter<ProfileState> emit,
  ) async {
    // Get the failed upload progress
    final failedUpload = state.uploadingPhotos[event.tempId];
    if (failedUpload == null) {
      _logger.w('⚠️ No failed upload found for tempId: ${event.tempId}');
      return;
    }

    _logger.i('🔄 Retrying photo upload: ${failedUpload.localPath}');

    // Trigger new upload with the same local path
    add(UploadPhoto(photoPath: failedUpload.localPath));

    // Clear the failed upload from map
    final clearedUploadingPhotos = Map<String, PhotoUploadProgress>.from(
      state.uploadingPhotos,
    );
    clearedUploadingPhotos.remove(event.tempId);
    emit(state.copyWith(uploadingPhotos: clearedUploadingPhotos));
  }

  Future<void> _onClearUploadProgress(
    ClearUploadProgress event,
    Emitter<ProfileState> emit,
  ) async {
    _logger.d('🧹 Clearing upload progress for: ${event.tempId}');

    final clearedUploadingPhotos = Map<String, PhotoUploadProgress>.from(
      state.uploadingPhotos,
    );
    clearedUploadingPhotos.remove(event.tempId);
    emit(state.copyWith(uploadingPhotos: clearedUploadingPhotos));
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
      _logger.i('🔒 UpdatePrivacySettings event received');
      _logger.i('   - Settings: ${event.settings}');
      _logger.i('   - Settings keys: ${event.settings.keys.toList()}');
      _logger.i('   - Settings empty? ${event.settings.isEmpty}');
      
      emit(state.copyWith(updateStatus: ProfileStatus.loading));
      _logger.i('   - Emitted loading status');
      
      // Call dedicated privacy update method
      _logger.i('🌐 Calling ProfileService.updatePrivacySettings...');
      await _profileService.updatePrivacySettings(event.settings);
      _logger.i('✅ ProfileService.updatePrivacySettings completed');
      
      // Reload profile to get updated privacy settings
      _logger.i('🔄 Reloading profile from server...');
      final profile = await _profileService.getCurrentProfile();
      _logger.i('✅ Profile reloaded successfully');
      
      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: profile,
        updateStatus: ProfileStatus.success,
          lastFetchTime: DateTime.now(), // Update cache time
      ));
      _logger.i('✅ Emitted success status');
      
      _logger.i('✅ Privacy settings updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating privacy settings: $e');
      _logger.e('   - Stack trace: ${StackTrace.current}');
      final errorMessage = ErrorHandler.handleError(e, showDialog: false);
      emit(state.copyWith(
        status: ProfileStatus.error,
          error: errorMessage,
        updateStatus: ProfileStatus.error,
      ));
    }
  }
}
