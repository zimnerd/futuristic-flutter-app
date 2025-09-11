import 'package:equatable/equatable.dart';
import '../../../data/models/profile_model.dart';

/// Profile BLoC states
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading states
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class PhotoUploading extends ProfileState {
  final double progress;

  const PhotoUploading({this.progress = 0.0});

  @override
  List<Object?> get props => [progress];
}

class PreferencesUpdating extends ProfileState {
  const PreferencesUpdating();
}

class VerificationRequesting extends ProfileState {
  const VerificationRequesting();
}

/// Success states
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final int completionPercentage;

  const ProfileLoaded({
    required this.profile,
    required this.completionPercentage,
  });

  @override
  List<Object?> get props => [profile, completionPercentage];

  ProfileLoaded copyWith({
    UserProfile? profile,
    int? completionPercentage,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }
}

class ProfileCreated extends ProfileState {
  final UserProfile profile;

  const ProfileCreated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final UserProfile profile;
  final String message;

  const ProfileUpdated({
    required this.profile,
    this.message = 'Profile updated successfully',
  });

  @override
  List<Object?> get props => [profile, message];
}

class PhotoUploaded extends ProfileState {
  final ProfilePhoto photo;
  final UserProfile updatedProfile;

  const PhotoUploaded({
    required this.photo,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [photo, updatedProfile];
}

class PhotoDeleted extends ProfileState {
  final UserProfile updatedProfile;
  final String message;

  const PhotoDeleted({
    required this.updatedProfile,
    this.message = 'Photo deleted successfully',
  });

  @override
  List<Object?> get props => [updatedProfile, message];
}

class PhotosReordered extends ProfileState {
  final UserProfile updatedProfile;

  const PhotosReordered(this.updatedProfile);

  @override
  List<Object?> get props => [updatedProfile];
}

class PreferencesUpdated extends ProfileState {
  final UserPreferences preferences;
  final String message;

  const PreferencesUpdated({
    required this.preferences,
    this.message = 'Preferences updated successfully',
  });

  @override
  List<Object?> get props => [preferences, message];
}

class VerificationRequested extends ProfileState {
  final String verificationType;
  final String message;

  const VerificationRequested({
    required this.verificationType,
    this.message = 'Verification request submitted successfully',
  });

  @override
  List<Object?> get props => [verificationType, message];
}

class AvailableInterestsLoaded extends ProfileState {
  final List<String> interests;

  const AvailableInterestsLoaded(this.interests);

  @override
  List<Object?> get props => [interests];
}

class LocationUpdated extends ProfileState {
  final UserLocation location;
  final String message;

  const LocationUpdated({
    required this.location,
    this.message = 'Location updated successfully',
  });

  @override
  List<Object?> get props => [location, message];
}

class PrivacySettingsUpdated extends ProfileState {
  final String message;

  const PrivacySettingsUpdated({
    this.message = 'Privacy settings updated successfully',
  });

  @override
  List<Object?> get props => [message];
}

/// Error states
class ProfileError extends ProfileState {
  final String message;
  final String? errorCode;

  const ProfileError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class PhotoUploadError extends ProfileState {
  final String message;

  const PhotoUploadError(this.message);

  @override
  List<Object?> get props => [message];
}

class PreferencesError extends ProfileState {
  final String message;

  const PreferencesError(this.message);

  @override
  List<Object?> get props => [message];
}

class VerificationError extends ProfileState {
  final String message;

  const VerificationError(this.message);

  @override
  List<Object?> get props => [message];
}

class LocationError extends ProfileState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Empty state for cleared profile
class ProfileCleared extends ProfileState {
  const ProfileCleared();
}

/// Composite state for multiple operations
class ProfileOperationInProgress extends ProfileState {
  final String operation;
  final double? progress;

  const ProfileOperationInProgress({
    required this.operation,
    this.progress,
  });

  @override
  List<Object?> get props => [operation, progress];
}

class ProfileOperationSuccess extends ProfileState {
  final String operation;
  final String message;
  final UserProfile? updatedProfile;

  const ProfileOperationSuccess({
    required this.operation,
    required this.message,
    this.updatedProfile,
  });

  @override
  List<Object?> get props => [operation, message, updatedProfile];
}
