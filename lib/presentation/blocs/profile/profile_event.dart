part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
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
  final String photoUrl;

  const DeletePhoto({required this.photoUrl});

  @override
  List<Object> get props => [photoUrl];
}
