part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final bool forceRefresh;

  const LoadProfile({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class UpdateProfile extends ProfileEvent {
  final UserProfile profile;

  const UpdateProfile({required this.profile});

  @override
  List<Object> get props => [profile];
}

class UploadPhoto extends ProfileEvent {
  final String photoPath;

  const UploadPhoto({required this.photoPath});

  @override
  List<Object> get props => [photoPath];
}

class DeletePhoto extends ProfileEvent {
  final String photoId;

  const DeletePhoto({required this.photoId});

  @override
  List<Object> get props => [photoId];
}

class RetryPhotoUpload extends ProfileEvent {
  final String tempId; // Temporary ID of failed upload

  const RetryPhotoUpload({required this.tempId});

  @override
  List<Object> get props => [tempId];
}

class ClearUploadProgress extends ProfileEvent {
  final String tempId; // Clear specific upload progress (success/failed)

  const ClearUploadProgress({required this.tempId});

  @override
  List<Object> get props => [tempId];
}

class CancelProfileChanges extends ProfileEvent {
  const CancelProfileChanges();
}

class UpdatePrivacySettings extends ProfileEvent {
  final Map<String, dynamic> settings;

  const UpdatePrivacySettings({required this.settings});

  @override
  List<Object> get props => [settings];
}

/// Multiple Photo Upload event (direct to permanent storage)
class UploadMultiplePhotos extends ProfileEvent {
  final List<String> photoPaths;

  const UploadMultiplePhotos({required this.photoPaths});

  @override
  List<Object> get props => [photoPaths];
}

/// Load user profile statistics
class LoadProfileStats extends ProfileEvent {
  final bool forceRefresh;

  const LoadProfileStats({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Load list of users who viewed the current user's profile
class LoadProfileViewers extends ProfileEvent {
  final int limit;
  final bool forceRefresh;

  const LoadProfileViewers({this.limit = 50, this.forceRefresh = false});

  @override
  List<Object> get props => [limit, forceRefresh];
}
