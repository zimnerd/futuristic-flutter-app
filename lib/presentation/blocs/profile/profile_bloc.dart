import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../data/services/profile_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

enum ProfileStatus { initial, loading, loaded, error, success }

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;

  ProfileBloc({required ProfileService profileService})
      : _profileService = profileService,
        super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
    on<DeletePhoto>(_onDeletePhoto);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProfileStatus.loading));
      
      final profile = await _profileService.getCurrentProfile();
      
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
      
      final updatedProfile = await _profileService.updateProfile(event.profile);
      
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
      
      final photoUrl = await _profileService.uploadPhoto(event.photoPath);
      
      if (state.profile != null) {
        final updatedPhotos = List<ProfilePhoto>.from(state.profile!.photos)
          ..add(ProfilePhoto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            url: photoUrl,
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
      await _profileService.deletePhoto(event.photoUrl);
      
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
}
