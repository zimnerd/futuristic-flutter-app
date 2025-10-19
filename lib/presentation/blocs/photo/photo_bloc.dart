import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/user_repository.dart';
import 'photo_event.dart';
import 'photo_state.dart';

/// BLoC for managing photo operations (upload, reorder, delete, set main)
class PhotoBloc extends Bloc<PhotoEvent, PhotoState> {
  final UserRepository _userRepository;

  PhotoBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(const PhotoInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<UploadPhoto>(_onUploadPhoto);
    on<ReorderPhotos>(_onReorderPhotos);
    on<DeletePhoto>(_onDeletePhoto);
    on<SetMainPhoto>(_onSetMainPhoto);
    on<RefreshPhotos>(_onRefreshPhotos);
    on<CancelPhotoUpload>(_onCancelPhotoUpload);
  }

  /// Load user's photos
  Future<void> _onLoadPhotos(LoadPhotos event, Emitter<PhotoState> emit) async {
    emit(const PhotoLoading());

    try {
      final user = await _userRepository.getCurrentUser();

      if (user == null) {
        emit(const PhotoError(message: 'User not found'));
        return;
      }

      // Convert UserModel photos to ProfilePhoto list
      final photos = <ProfilePhoto>[];
      if (user.photos.isNotEmpty) {
        for (final photo in user.photos) {
          photos.add(
            ProfilePhoto(
              id: photo['id'] as String? ?? '',
              url: photo['url'] as String? ?? '',
              order: photo['order'] as int? ?? 0,
              isMain: photo['isMain'] as bool? ?? false,
              isVerified: photo['isVerified'] as bool? ?? false,
            ),
          );
        }
      }

      final mainPhotoId = photos.where((photo) => photo.isMain).isNotEmpty
          ? photos.firstWhere((photo) => photo.isMain).id
          : (photos.isNotEmpty ? photos.first.id : null);

      emit(PhotosLoaded(photos: photos, mainPhotoId: mainPhotoId));
    } catch (e) {
      AppLogger.error('Failed to load photos: $e');
      emit(PhotoError(message: 'Failed to load photos: ${e.toString()}'));
    }
  }

  /// Upload a new photo
  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<PhotoState> emit,
  ) async {
    emit(const PhotoUploading(progress: 0.0, message: 'Preparing upload...'));

    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        emit(const PhotoError(message: 'User not found'));
        return;
      }

      // Upload multiple photos (API expects list)
      final result = await _userRepository.uploadMultiplePhotos(user.id, [
        event.photoFile.path,
      ]);

      if (result['success'] == true) {
        emit(
          PhotoOperationSuccess(
            message: 'Photo uploaded successfully',
            photos: [], // Will be refreshed by LoadPhotos
          ),
        );
        // Automatically load photos after upload
        add(const LoadPhotos());
      } else {
        emit(PhotoError(message: result['message'] ?? 'Upload failed'));
      }
    } catch (e) {
      AppLogger.error('Failed to upload photo: $e');
      emit(PhotoError(message: 'Failed to upload photo: ${e.toString()}'));
    }
  }

  /// Reorder photos
  Future<void> _onReorderPhotos(
    ReorderPhotos event,
    Emitter<PhotoState> emit,
  ) async {
    emit(const PhotoReordering());

    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        emit(const PhotoError(message: 'User not found'));
        return;
      }

      await _userRepository.reorderPhotos(user.id, event.photoIds);

      emit(
        PhotoOperationSuccess(
          message: 'Photos reordered successfully',
          photos: [], // Will be refreshed by LoadPhotos
        ),
      );
      // Automatically load photos after reorder
      add(const LoadPhotos());
    } catch (e) {
      AppLogger.error('Failed to reorder photos: $e');
      emit(PhotoError(message: 'Failed to reorder photos: ${e.toString()}'));
    }
  }

  /// Delete a photo
  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<PhotoState> emit,
  ) async {
    emit(PhotoDeleting(event.photoId));

    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        emit(const PhotoError(message: 'User not found'));
        return;
      }

      await _userRepository.deletePhoto(user.id, event.photoId);

      emit(
        PhotoOperationSuccess(
          message: 'Photo deleted successfully',
          photos: [], // Will be refreshed by LoadPhotos
        ),
      );
      // Automatically load photos after delete
      add(const LoadPhotos());
    } catch (e) {
      AppLogger.error('Failed to delete photo: $e');
      emit(PhotoError(message: 'Failed to delete photo: ${e.toString()}'));
    }
  }

  /// Set a photo as main/primary
  Future<void> _onSetMainPhoto(
    SetMainPhoto event,
    Emitter<PhotoState> emit,
  ) async {
    emit(SettingMainPhoto(event.photoId));

    try {
      final user = await _userRepository.getCurrentUser();
      if (user == null) {
        emit(const PhotoError(message: 'User not found'));
        return;
      }

      await _userRepository.setMainPhoto(user.id, event.photoId);

      emit(
        PhotoOperationSuccess(
          message: 'Main photo updated successfully',
          photos: [], // Will be refreshed by LoadPhotos
        ),
      );
      // Automatically load photos after setting main
      add(const LoadPhotos());
    } catch (e) {
      AppLogger.error('Failed to set main photo: $e');
      emit(PhotoError(message: 'Failed to set main photo: ${e.toString()}'));
    }
  }

  /// Refresh photos
  Future<void> _onRefreshPhotos(
    RefreshPhotos event,
    Emitter<PhotoState> emit,
  ) async {
    add(const LoadPhotos());
  }

  /// Cancel photo upload
  Future<void> _onCancelPhotoUpload(
    CancelPhotoUpload event,
    Emitter<PhotoState> emit,
  ) async {
    // Implementation depends on how the repository handles upload cancellation
    // For now, just emit a cancellation state
    emit(const PhotoError(message: 'Upload cancelled'));
    add(const LoadPhotos());
  }
}
