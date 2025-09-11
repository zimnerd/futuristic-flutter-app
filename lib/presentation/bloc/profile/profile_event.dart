import 'package:equatable/equatable.dart';
import '../../../data/models/profile_model.dart';

/// Profile-related events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load user profile
class LoadProfile extends ProfileEvent {
  final String userId;

  const LoadProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Create new profile
class CreateProfile extends ProfileEvent {
  final String userId;
  final String? bio;
  final List<String> interests;
  final UserPreferences? preferences;
  final UserLocation? location;

  const CreateProfile({
    required this.userId,
    this.bio,
    this.interests = const [],
    this.preferences,
    this.location,
  });

  @override
  List<Object?> get props => [userId, bio, interests, preferences, location];
}

/// Update profile information
class UpdateProfile extends ProfileEvent {
  final String userId;
  final String? bio;
  final List<String>? interests;
  final List<String>? dealBreakers;
  final UserPreferences? preferences;
  final UserLocation? location;

  const UpdateProfile({
    required this.userId,
    this.bio,
    this.interests,
    this.dealBreakers,
    this.preferences,
    this.location,
  });

  @override
  List<Object?> get props => [userId, bio, interests, dealBreakers, preferences, location];
}

/// Upload photo event
class UploadPhoto extends ProfileEvent {
  final String userId;
  final String imagePath;
  final bool isPrimary;
  final int order;

  const UploadPhoto({
    required this.userId,
    required this.imagePath,
    this.isPrimary = false,
    this.order = 0,
  });

  @override
  List<Object?> get props => [userId, imagePath, isPrimary, order];
}

/// Delete photo event
class DeletePhoto extends ProfileEvent {
  final String userId;
  final String photoId;

  const DeletePhoto({
    required this.userId,
    required this.photoId,
  });

  @override
  List<Object?> get props => [userId, photoId];
}

/// Reorder photos event
class ReorderPhotos extends ProfileEvent {
  final String userId;
  final List<String> photoIds; // In new order

  const ReorderPhotos({
    required this.userId,
    required this.photoIds,
  });

  @override
  List<Object?> get props => [userId, photoIds];
}

/// Update user preferences
class UpdatePreferences extends ProfileEvent {
  final String userId;
  final AgeRange? ageRange;
  final double? maxDistance;
  final List<String>? genderPreference;
  final List<String>? lookingFor;
  final List<String>? dealBreakers;
  final List<String>? interests;
  final LifestylePreferences? lifestyle;

  const UpdatePreferences({
    required this.userId,
    this.ageRange,
    this.maxDistance,
    this.genderPreference,
    this.lookingFor,
    this.dealBreakers,
    this.interests,
    this.lifestyle,
  });

  @override
  List<Object?> get props => [
    userId,
    ageRange,
    maxDistance,
    genderPreference,
    lookingFor,
    dealBreakers,
    interests,
    lifestyle,
  ];
}

/// Request profile verification
class RequestVerification extends ProfileEvent {
  final String userId;
  final String verificationType; // 'photo' or 'identity'

  const RequestVerification({
    required this.userId,
    required this.verificationType,
  });

  @override
  List<Object?> get props => [userId, verificationType];
}

/// Load available interests
class LoadAvailableInterests extends ProfileEvent {
  const LoadAvailableInterests();
}

/// Refresh profile data
class RefreshProfile extends ProfileEvent {
  final String userId;

  const RefreshProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Calculate profile completion
class CalculateCompletion extends ProfileEvent {
  final UserProfile profile;

  const CalculateCompletion(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Clear profile data
class ClearProfile extends ProfileEvent {
  const ClearProfile();
}

/// Update location
class UpdateLocation extends ProfileEvent {
  final String userId;
  final UserLocation location;

  const UpdateLocation({
    required this.userId,
    required this.location,
  });

  @override
  List<Object?> get props => [userId, location];
}

/// Privacy settings events
class UpdatePrivacySettings extends ProfileEvent {
  final String userId;
  final bool showAge;
  final bool showDistance;
  final bool showOnlineStatus;

  const UpdatePrivacySettings({
    required this.userId,
    required this.showAge,
    required this.showDistance,
    required this.showOnlineStatus,
  });

  @override
  List<Object?> get props => [userId, showAge, showDistance, showOnlineStatus];
}
