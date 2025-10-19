part of 'profile_bloc.dart';

/// Upload state for individual photos
enum PhotoUploadState { uploading, success, failed }

/// Track individual photo upload progress
class PhotoUploadProgress {
  final String tempId; // Temporary ID for tracking
  final String localPath; // Local file path
  final PhotoUploadState state;
  final String? error; // Error message if failed
  final ProfilePhoto? uploadedPhoto; // The uploaded photo (when success)

  const PhotoUploadProgress({
    required this.tempId,
    required this.localPath,
    required this.state,
    this.error,
    this.uploadedPhoto,
  });

  PhotoUploadProgress copyWith({
    String? tempId,
    String? localPath,
    PhotoUploadState? state,
    String? error,
    ProfilePhoto? uploadedPhoto,
  }) {
    return PhotoUploadProgress(
      tempId: tempId ?? this.tempId,
      localPath: localPath ?? this.localPath,
      state: state ?? this.state,
      error: error ?? this.error,
      uploadedPhoto: uploadedPhoto ?? this.uploadedPhoto,
    );
  }
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileStatus updateStatus;
  final ProfileStatus uploadStatus;
  final ProfileStatus statsStatus; // NEW: Stats loading status
  final ProfileStatus viewersStatus; // NEW: Profile viewers loading status
  final UserProfile? profile;
  final ProfileStats? stats; // NEW: User statistics
  final List<UserProfile> viewers; // NEW: Users who viewed profile
  final int viewersTotalCount; // NEW: Total count of profile viewers
  final String? error;
  final DateTime? lastFetchTime; // Track when profile was last fetched
  final DateTime? statsLastFetchTime; // NEW: Track when stats were last fetched
  final DateTime?
  viewersLastFetchTime; // NEW: Track when viewers were last fetched
  final Map<String, PhotoUploadProgress>
  uploadingPhotos; // Track individual uploads

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.updateStatus = ProfileStatus.initial,
    this.uploadStatus = ProfileStatus.initial,
    this.statsStatus = ProfileStatus.initial, // NEW
    this.viewersStatus = ProfileStatus.initial, // NEW
    this.profile,
    this.stats, // NEW
    this.viewers = const [], // NEW
    this.viewersTotalCount = 0, // NEW
    this.error,
    this.lastFetchTime,
    this.statsLastFetchTime, // NEW
    this.viewersLastFetchTime, // NEW
    this.uploadingPhotos = const {},
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileStatus? updateStatus,
    ProfileStatus? uploadStatus,
    ProfileStatus? statsStatus, // NEW
    ProfileStatus? viewersStatus, // NEW
    UserProfile? profile,
    ProfileStats? stats, // NEW
    List<UserProfile>? viewers, // NEW
    int? viewersTotalCount, // NEW
    String? error,
    DateTime? lastFetchTime,
    DateTime? statsLastFetchTime, // NEW
    DateTime? viewersLastFetchTime, // NEW
    Map<String, PhotoUploadProgress>? uploadingPhotos,
  }) {
    return ProfileState(
      status: status ?? this.status,
      updateStatus: updateStatus ?? this.updateStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      statsStatus: statsStatus ?? this.statsStatus, // NEW
      viewersStatus: viewersStatus ?? this.viewersStatus, // NEW
      profile: profile ?? this.profile,
      stats: stats ?? this.stats, // NEW
      viewers: viewers ?? this.viewers, // NEW
      viewersTotalCount: viewersTotalCount ?? this.viewersTotalCount, // NEW
      error: error ?? this.error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      statsLastFetchTime: statsLastFetchTime ?? this.statsLastFetchTime, // NEW
      viewersLastFetchTime:
          viewersLastFetchTime ?? this.viewersLastFetchTime, // NEW
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

  /// Check if cached viewers are stale (older than 2 minutes)
  bool get isViewersCacheStale {
    if (viewersLastFetchTime == null) return true;
    return DateTime.now().difference(viewersLastFetchTime!).inMinutes >= 2;
  }

  @override
  List<Object?> get props => [
    status,
    updateStatus,
    uploadStatus,
    statsStatus, // NEW
    viewersStatus, // NEW
    profile,
    stats, // NEW
    viewers, // NEW
    viewersTotalCount, // NEW
    error,
    uploadingPhotos,
    lastFetchTime,
    statsLastFetchTime, // NEW
    viewersLastFetchTime, // NEW
  ];
}
