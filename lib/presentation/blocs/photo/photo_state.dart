import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_profile.dart';

/// States for photo management operations
abstract class PhotoState extends Equatable {
  const PhotoState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any photo operations
class PhotoInitial extends PhotoState {
  const PhotoInitial();
}

/// State when photos are being loaded
class PhotoLoading extends PhotoState {
  const PhotoLoading();
}

/// State when photos are successfully loaded
class PhotosLoaded extends PhotoState {
  final List<ProfilePhoto> photos;
  final String? mainPhotoId;

  const PhotosLoaded({required this.photos, this.mainPhotoId});

  @override
  List<Object?> get props => [photos, mainPhotoId];

  /// Create a copy with updated fields
  PhotosLoaded copyWith({List<ProfilePhoto>? photos, String? mainPhotoId}) {
    return PhotosLoaded(
      photos: photos ?? this.photos,
      mainPhotoId: mainPhotoId ?? this.mainPhotoId,
    );
  }
}

/// State when a photo is being uploaded
class PhotoUploading extends PhotoState {
  final double progress; // 0.0 to 1.0
  final String? message;

  const PhotoUploading({required this.progress, this.message});

  @override
  List<Object?> get props => [progress, message];
}

/// State when a photo operation succeeds
class PhotoOperationSuccess extends PhotoState {
  final String message;
  final List<ProfilePhoto> photos;

  const PhotoOperationSuccess({required this.message, required this.photos});

  @override
  List<Object?> get props => [message, photos];
}

/// State when a photo operation fails
class PhotoError extends PhotoState {
  final String message;
  final String? errorCode;

  const PhotoError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// State when photos are being reordered
class PhotoReordering extends PhotoState {
  const PhotoReordering();
}

/// State when a photo is being deleted
class PhotoDeleting extends PhotoState {
  final String photoId;

  const PhotoDeleting(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

/// State when main photo is being set
class SettingMainPhoto extends PhotoState {
  final String photoId;

  const SettingMainPhoto(this.photoId);

  @override
  List<Object?> get props => [photoId];
}
