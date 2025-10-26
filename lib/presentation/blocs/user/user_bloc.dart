import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/exceptions/app_exceptions.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

/// BLoC responsible for managing user profile operations
///
/// Handles user profile loading, updating, photo management, preferences,
/// location updates, and user search functionality. Works with UserRepository
/// to perform user-related operations and manages user state throughout the app.
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required UserRepository userRepository, Logger? logger})
    : _userRepository = userRepository,
      _logger = logger ?? Logger(),
      super(const UserInitial()) {
    // Register event handlers
    on<UserProfileLoadRequested>(_onProfileLoadRequested);
    on<UserProfileUpdateRequested>(_onProfileUpdateRequested);
    on<UserProfilePhotoUploadRequested>(_onProfilePhotoUploadRequested);
    on<UserProfilePhotoDeleteRequested>(_onProfilePhotoDeleteRequested);
    on<UserPreferencesUpdateRequested>(_onPreferencesUpdateRequested);
    on<UserLocationUpdateRequested>(_onLocationUpdateRequested);
    on<UserSearchRequested>(_onSearchRequested);
    on<UserErrorCleared>(_onErrorCleared);
  }

  final UserRepository _userRepository;
  final Logger _logger;

  /// Loads user profile by ID
  Future<void> _onProfileLoadRequested(
    UserProfileLoadRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('👤 Loading user profile: ${event.userId}');
      emit(const UserLoading());

      final user = await _userRepository.getUserById(event.userId);

      if (user != null) {
        _logger.i('✅ User profile loaded: ${user.username}');
        emit(UserProfileLoaded(user: user));
      } else {
        _logger.w('❌ User profile not found: ${event.userId}');
        emit(
          const UserError(
            message: 'User profile not found',
            errorCode: 'USER_NOT_FOUND',
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error loading user profile',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        UserError(
          message: e is AppException
              ? e.message
              : 'Failed to load user profile',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Updates user profile information
  Future<void> _onProfileUpdateRequested(
    UserProfileUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('📝 Updating user profile: ${event.userId}');
      emit(const UserLoading());

      final updatedUser = await _userRepository.updateUserProfile(
        event.userId,
        event.updates,
      );

      _logger.i('✅ User profile updated successfully');
      emit(
        UserProfileUpdated(
          user: updatedUser,
          message: 'Profile updated successfully',
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error updating user profile',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        UserError(
          message: e is AppException ? e.message : 'Failed to update profile',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Uploads a new profile photo
  Future<void> _onProfilePhotoUploadRequested(
    UserProfilePhotoUploadRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('📷 Uploading profile photo for: ${event.userId}');
      emit(const UserLoading());

      await _userRepository.uploadProfilePhoto(event.userId, event.photoPath);

      // Reload user to get updated photo URLs
      final updatedUser = await _userRepository.getUserById(event.userId);

      if (updatedUser != null) {
        _logger.i('✅ Profile photo uploaded successfully');
        emit(
          UserProfilePhotoUploaded(
            user: updatedUser,
            photoUrl: event.photoPath,
          ),
        );
      } else {
        throw const ServerException(
          'Failed to reload user after photo upload',
          code: 'RELOAD_FAILED',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error uploading profile photo',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        UserError(
          message: e is AppException ? e.message : 'Failed to upload photo',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Deletes a profile photo
  Future<void> _onProfilePhotoDeleteRequested(
    UserProfilePhotoDeleteRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('🗑️ Deleting profile photo: ${event.photoUrl}');
      emit(const UserLoading());

      await _userRepository.deleteProfilePhoto(event.userId, event.photoUrl);

      // Reload user to get updated photo URLs
      final updatedUser = await _userRepository.getUserById(event.userId);

      if (updatedUser != null) {
        _logger.i('✅ Profile photo deleted successfully');
        emit(
          UserProfilePhotoDeleted(
            user: updatedUser,
            message: 'Photo deleted successfully',
          ),
        );
      } else {
        throw const ServerException(
          'Failed to reload user after photo deletion',
          code: 'RELOAD_FAILED',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error deleting profile photo',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        UserError(
          message: e is AppException ? e.message : 'Failed to delete photo',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Updates user preferences
  Future<void> _onPreferencesUpdateRequested(
    UserPreferencesUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('⚙️ Updating user preferences: ${event.userId}');
      emit(const UserLoading());

      await _userRepository.updateUserPreferences(
        event.userId,
        event.preferences,
      );

      // Reload user to get updated preferences
      final updatedUser = await _userRepository.getUserById(event.userId);

      if (updatedUser != null) {
        _logger.i('✅ User preferences updated successfully');
        emit(
          UserPreferencesUpdated(
            user: updatedUser,
            message: 'Preferences updated successfully',
          ),
        );
      } else {
        throw const ServerException(
          'Failed to reload user after preferences update',
          code: 'RELOAD_FAILED',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error updating user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        UserError(
          message: e is AppException
              ? e.message
              : 'Failed to update preferences',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Updates user location (placeholder - would need location update in repository)
  Future<void> _onLocationUpdateRequested(
    UserLocationUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('📍 Updating user location: ${event.userId}');
      emit(const UserLoading());

      await _userRepository.updateUserLocation(
        event.userId,
        event.latitude,
        event.longitude,
      );

      // Get updated user data
      final updatedUser = await _userRepository.getUserById(event.userId);
      if (updatedUser == null) {
        throw Exception('Failed to get updated user data');
      }

      _logger.i('✅ User location updated successfully');
      emit(
        UserLocationUpdated(
          user: updatedUser,
          message: 'Location updated successfully',
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error updating user location',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        UserError(
          message: e is AppException ? e.message : 'Failed to update location',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Searches for users based on filters
  Future<void> _onSearchRequested(
    UserSearchRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.i('🔍 Searching users with filters: ${event.filters}');
      emit(const UserLoading());

      final users = await _userRepository.searchUsers(
        query: event.filters['query'] as String?,
        minAge: event.filters['minAge'] as int?,
        maxAge: event.filters['maxAge'] as int?,
        gender: event.filters['gender'] as String?,
        interests: (event.filters['interests'] as List<dynamic>?)
            ?.cast<String>(),
        maxDistanceKm: event.filters['maxDistanceKm'] != null
            ? ((event.filters['maxDistanceKm'] as num).toDouble())
            : null,
        limit: event.limit,
      );

      _logger.i('✅ Found ${users.length} users');
      emit(
        UserSearchResultsLoaded(
          users: users,
          hasMore: users.length >= event.limit,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e('💥 Error searching users', error: e, stackTrace: stackTrace);
      emit(
        UserError(
          message: e is AppException ? e.message : 'Failed to search users',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Clears user-related errors
  void _onErrorCleared(UserErrorCleared event, Emitter<UserState> emit) {
    _logger.i('🧹 Clearing user error');
    emit(const UserInitial());
  }

  /// Gets the current user from the state, if available
  UserModel? get currentUser {
    final currentState = state;
    return switch (currentState) {
      UserProfileLoaded() => currentState.user,
      UserProfileUpdated() => currentState.user,
      UserProfilePhotoUploaded() => currentState.user,
      UserProfilePhotoDeleted() => currentState.user,
      UserPreferencesUpdated() => currentState.user,
      UserLocationUpdated() => currentState.user,
      _ => null,
    };
  }

  /// Checks if user operation is currently loading
  bool get isLoading => state is UserLoading;

  /// Gets the current error message, if any
  String? get errorMessage {
    final currentState = state;
    if (currentState is UserError) {
      return currentState.message;
    }
    return null;
  }
}
