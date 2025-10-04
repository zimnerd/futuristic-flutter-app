part of 'profile_bloc.dart';

/// Upload state for individual photos
enum PhotoUploadState { uploading, success, failed }

/// Track individual photo upload progress
class PhotoUploadProgress {
  final String tempId; // Temporary ID for tracking
  final String localPath; // Local file path
  final PhotoUploadState state;
  final String? error; // Error message if failed

  const PhotoUploadProgress({
    required this.tempId,
    required this.localPath,
    required this.state,
    this.error,
  });

  PhotoUploadProgress copyWith({
    String? tempId,
    String? localPath,
    PhotoUploadState? state,
    String? error,
  }) {
    return PhotoUploadProgress(
      tempId: tempId ?? this.tempId,
      localPath: localPath ?? this.localPath,
      state: state ?? this.state,
      error: error ?? this.error,
    );
  }
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileStatus updateStatus;
  final ProfileStatus uploadStatus;
  final UserProfile? profile;
  final String? error;
  final DateTime? lastFetchTime; // Track when profile was last fetched
  final Map<String, PhotoUploadProgress>
  uploadingPhotos; // Track individual uploads

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.updateStatus = ProfileStatus.initial,
    this.uploadStatus = ProfileStatus.initial,
    this.profile,
    this.error,
    this.lastFetchTime,
    this.uploadingPhotos = const {},
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileStatus? updateStatus,
    ProfileStatus? uploadStatus,
    UserProfile? profile,
    String? error,
    DateTime? lastFetchTime,
    Map<String, PhotoUploadProgress>? uploadingPhotos,
  }) {
    return ProfileState(
      status: status ?? this.status,
      updateStatus: updateStatus ?? this.updateStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      profile: profile ?? this.profile,
      error: error ?? this.error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      uploadingPhotos: uploadingPhotos ?? this.uploadingPhotos,
    );
  }
  
  /// Check if cached profile is stale (older than 5 minutes)
  bool get isCacheStale {
    if (lastFetchTime == null) return true;
    return DateTime.now().difference(lastFetchTime!).inMinutes >= 5;
  }

  @override
  List<Object?> get props => [
        status,
        updateStatus,
        uploadStatus,
        profile,
        error,
    uploadingPhotos,
    lastFetchTime,
      ];
}
