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
  final ProfileStatus statsStatus; // NEW: Stats loading status
  final UserProfile? profile;
  final ProfileStats? stats; // NEW: User statistics
  final String? error;
  final DateTime? lastFetchTime; // Track when profile was last fetched
  final DateTime? statsLastFetchTime; // NEW: Track when stats were last fetched
  final Map<String, PhotoUploadProgress>
  uploadingPhotos; // Track individual uploads

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.updateStatus = ProfileStatus.initial,
    this.uploadStatus = ProfileStatus.initial,
    this.statsStatus = ProfileStatus.initial, // NEW
    this.profile,
    this.stats, // NEW
    this.error,
    this.lastFetchTime,
    this.statsLastFetchTime, // NEW
    this.uploadingPhotos = const {},
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileStatus? updateStatus,
    ProfileStatus? uploadStatus,
    ProfileStatus? statsStatus, // NEW
    UserProfile? profile,
    ProfileStats? stats, // NEW
    String? error,
    DateTime? lastFetchTime,
    DateTime? statsLastFetchTime, // NEW
    Map<String, PhotoUploadProgress>? uploadingPhotos,
  }) {
    return ProfileState(
      status: status ?? this.status,
      updateStatus: updateStatus ?? this.updateStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      statsStatus: statsStatus ?? this.statsStatus, // NEW
      profile: profile ?? this.profile,
      stats: stats ?? this.stats, // NEW
      error: error ?? this.error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      statsLastFetchTime: statsLastFetchTime ?? this.statsLastFetchTime, // NEW
      uploadingPhotos: uploadingPhotos ?? this.uploadingPhotos,
    );
  }
  
  /// Check if we have valid profile data
  bool get hasValidProfile => profile != null && profile!.id.isNotEmpty;
  
  /// Check if cached profile is stale (older than 5 minutes)
  /// Returns true if no lastFetchTime (never fetched) or cache is expired
  bool get isCacheStale {
    if (lastFetchTime == null) return true;
    return DateTime.now().difference(lastFetchTime!).inMinutes >= 5;
  }

  /// Check if cached stats are stale (older than 2 minutes)
  bool get isStatsCacheStale {
    if (statsLastFetchTime == null) return true;
    return DateTime.now().difference(statsLastFetchTime!).inMinutes >= 2;
  }

  @override
  List<Object?> get props => [
        status,
        updateStatus,
        uploadStatus,
    statsStatus, // NEW
        profile,
    stats, // NEW
        error,
    uploadingPhotos,
    lastFetchTime,
    statsLastFetchTime, // NEW
      ];
}
