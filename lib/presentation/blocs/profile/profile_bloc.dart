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

        _tempPhotoIds.clear();
      }

      // STEP 2: Update profile with delta tracking
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
      
      // Add to profile for preview (not confirmed yet)
      if (state.profile != null) {
        final updatedPhotos = List<ProfilePhoto>.from(state.profile!.photos)
          ..add(ProfilePhoto(
              id: result.mediaId,
              url: result.url, // Temp URL for preview
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
        
        emit(state.copyWith(profile: updatedProfile));
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
}
