part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileStatus updateStatus;
  final ProfileStatus uploadStatus;
  final UserProfile? profile;
  final String? error;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.updateStatus = ProfileStatus.initial,
    this.uploadStatus = ProfileStatus.initial,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileStatus? updateStatus,
    ProfileStatus? uploadStatus,
    UserProfile? profile,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      updateStatus: updateStatus ?? this.updateStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        updateStatus,
        uploadStatus,
        profile,
        error,
      ];
}
