import 'package:equatable/equatable.dart';

/// Base class for all user management events
sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile by ID
final class UserProfileLoadRequested extends UserEvent {
  const UserProfileLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to update user profile information
final class UserProfileUpdateRequested extends UserEvent {
  const UserProfileUpdateRequested({
    required this.userId,
    required this.updates,
  });

  final String userId;
  final Map<String, dynamic> updates;

  @override
  List<Object?> get props => [userId, updates];
}

/// Event to upload a new profile photo
final class UserProfilePhotoUploadRequested extends UserEvent {
  const UserProfilePhotoUploadRequested({
    required this.userId,
    required this.photoPath,
  });

  final String userId;
  final String photoPath;

  @override
  List<Object?> get props => [userId, photoPath];
}

/// Event to delete a profile photo
final class UserProfilePhotoDeleteRequested extends UserEvent {
  const UserProfilePhotoDeleteRequested({
    required this.userId,
    required this.photoUrl,
  });

  final String userId;
  final String photoUrl;

  @override
  List<Object?> get props => [userId, photoUrl];
}

/// Event to update user preferences
final class UserPreferencesUpdateRequested extends UserEvent {
  const UserPreferencesUpdateRequested({
    required this.userId,
    required this.preferences,
  });

  final String userId;
  final Map<String, dynamic> preferences;

  @override
  List<Object?> get props => [userId, preferences];
}

/// Event to update user location
final class UserLocationUpdateRequested extends UserEvent {
  const UserLocationUpdateRequested({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  final String userId;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [userId, latitude, longitude];
}

/// Event to search for users based on filters
final class UserSearchRequested extends UserEvent {
  const UserSearchRequested({required this.filters, this.limit = 20});

  final Map<String, dynamic> filters;
  final int limit;

  @override
  List<Object?> get props => [filters, limit];
}

/// Event to clear user-related errors
final class UserErrorCleared extends UserEvent {
  const UserErrorCleared();
}
