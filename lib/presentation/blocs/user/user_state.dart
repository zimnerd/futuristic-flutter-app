import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';

/// Base class for all user management states
sealed class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// Initial state when UserBloc is created
final class UserInitial extends UserState {
  const UserInitial();
}

/// State when user operation is in progress
final class UserLoading extends UserState {
  const UserLoading();
}

/// State when user profile is successfully loaded
final class UserProfileLoaded extends UserState {
  const UserProfileLoaded({required this.user});

  final UserModel user;

  @override
  List<Object?> get props => [user];
}

/// State when user profile is successfully updated
final class UserProfileUpdated extends UserState {
  const UserProfileUpdated({required this.user, required this.message});

  final UserModel user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}

/// State when profile photo is successfully uploaded
final class UserProfilePhotoUploaded extends UserState {
  const UserProfilePhotoUploaded({required this.user, required this.photoUrl});

  final UserModel user;
  final String photoUrl;

  @override
  List<Object?> get props => [user, photoUrl];
}

/// State when profile photo is successfully deleted
final class UserProfilePhotoDeleted extends UserState {
  const UserProfilePhotoDeleted({required this.user, required this.message});

  final UserModel user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}

/// State when user preferences are successfully updated
final class UserPreferencesUpdated extends UserState {
  const UserPreferencesUpdated({required this.user, required this.message});

  final UserModel user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}

/// State when user location is successfully updated
final class UserLocationUpdated extends UserState {
  const UserLocationUpdated({required this.user, required this.message});

  final UserModel user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}

/// State when user search results are loaded
final class UserSearchResultsLoaded extends UserState {
  const UserSearchResultsLoaded({required this.users, required this.hasMore});

  final List<UserModel> users;
  final bool hasMore;

  @override
  List<Object?> get props => [users, hasMore];
}

/// State when user operation fails
final class UserError extends UserState {
  const UserError({required this.message, this.errorCode});

  final String message;
  final String? errorCode;

  @override
  List<Object?> get props => [message, errorCode];
}
