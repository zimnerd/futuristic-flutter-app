import 'dart:io';

import 'package:equatable/equatable.dart';

/// Events for photo management operations
abstract class PhotoEvent extends Equatable {
  const PhotoEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user's photos
class LoadPhotos extends PhotoEvent {
  const LoadPhotos();
}

/// Event to upload a new photo
class UploadPhoto extends PhotoEvent {
  final File photoFile;
  final bool setAsMain;

  const UploadPhoto({required this.photoFile, this.setAsMain = false});

  @override
  List<Object?> get props => [photoFile, setAsMain];
}

/// Event to reorder photos
class ReorderPhotos extends PhotoEvent {
  final List<String> photoIds;

  const ReorderPhotos(this.photoIds);

  @override
  List<Object?> get props => [photoIds];
}

/// Event to delete a photo
class DeletePhoto extends PhotoEvent {
  final String photoId;

  const DeletePhoto(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

/// Event to set a photo as main/primary
class SetMainPhoto extends PhotoEvent {
  final String photoId;

  const SetMainPhoto(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

/// Event to refresh photos after an operation
class RefreshPhotos extends PhotoEvent {
  const RefreshPhotos();
}

/// Event to cancel ongoing photo upload
class CancelPhotoUpload extends PhotoEvent {
  const CancelPhotoUpload();
}
