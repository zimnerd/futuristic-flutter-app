import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/exceptions/app_exceptions.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/photo_manager_service.dart';
import '../../../data/models/profile_model.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for managing profile-related state and operations
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;
  final PhotoManagerService _photoManager;
  final Logger _logger;

  UserProfile? _currentProfile;
  UserProfile? _originalProfile; // TODO: Use for delta tracking in updateProfileWithDetails
  List<String> _availableInterests = [];
  List<String> _tempPhotoIds = []; // Track temp photo uploads

  ProfileBloc({
    required ProfileService profileService,
    required PhotoManagerService photoManager,
    Logger? logger,
  })  : _profileService = profileService,
        _photoManager = photoManager,
        _logger = logger ?? Logger(),
        super(const ProfileInitial()) {
    
    // Register event handlers
    on<LoadProfile>(_onLoadProfile);
    on<CreateProfile>(_onCreateProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
    on<DeletePhoto>(_onDeletePhoto);
    on<ReorderPhotos>(_onReorderPhotos);
    on<UpdatePreferences>(_onUpdatePreferences);
    on<RequestVerification>(_onRequestVerification);
    on<LoadAvailableInterests>(_onLoadAvailableInterests);
    on<RefreshProfile>(_onRefreshProfile);
    on<CalculateCompletion>(_onCalculateCompletion);
    on<ClearProfile>(_onClearProfile);
    on<UpdateLocation>(_onUpdateLocation);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
    on<CancelProfileChanges>(_onCancelProfileChanges);
  }

  /// Get current profile
  UserProfile? get currentProfile => _currentProfile;

  /// Get available interests
  List<String> get availableInterests => _availableInterests;

  /// Load user profile
  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('📱 Loading profile for user: ${event.userId}');
      emit(const ProfileLoading());

      final profile = await _profileService.getProfile(event.userId);
      final completion = _profileService.calculateCompletionPercentage(profile);
      
      _currentProfile = profile;
      _originalProfile = profile; // Store original for comparison
      
      emit(ProfileLoaded(
        profile: profile,
        completionPercentage: completion,
      ));
      
      _logger.i('✅ Profile loaded successfully ($completion% complete)');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error loading profile: ${e.message}');
      emit(ProfileError('Network error: ${e.message}'));
    } on UserException catch (e) {
      _logger.e('❌ User error loading profile: ${e.message}');
      emit(ProfileError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error loading profile: $e');
      emit(const ProfileError('Failed to load profile'));
    }
  }

  /// Create new profile
  Future<void> _onCreateProfile(CreateProfile event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('🆕 Creating profile for user: ${event.userId}');
      emit(const ProfileLoading());

      final profile = await _profileService.createProfile(
        userId: event.userId,
        bio: event.bio,
        interests: event.interests,
        preferences: event.preferences,
        location: event.location,
      );
      
      _currentProfile = profile;
      emit(ProfileCreated(profile));
      
      _logger.i('✅ Profile created successfully');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error creating profile: ${e.message}');
      emit(ProfileError('Network error: ${e.message}'));
    } on UserException catch (e) {
      _logger.e('❌ User error creating profile: ${e.message}');
      emit(ProfileError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error creating profile: $e');
      emit(const ProfileError('Failed to create profile'));
    }
  }

  /// Update profile
  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('🔄 Updating profile for user: ${event.userId}');
      emit(const ProfileLoading());

      // FIRST: Save photos (confirm temp uploads + delete marked photos)
      if (_tempPhotoIds.isNotEmpty || _photoManager.getPhotosToDelete().isNotEmpty) {
        _logger.i('💾 Saving photo changes...');
        
        final photoResult = await _photoManager.savePhotos(
          tempPhotoIds: _tempPhotoIds,
        );

        if (photoResult.hasFailures) {
          _logger.w('⚠️ Some photo operations failed: ${photoResult.allFailures}');
          // Continue with profile update but warn user
        }

        // Clear temp photo IDs after save attempt
        _tempPhotoIds.clear();
      }

      // THEN: Update profile fields (only changed fields sent)
      final profile = await _profileService.updateProfileWithDetails(
        userId: event.userId,
        bio: event.bio,
        interests: event.interests,
        dealBreakers: event.dealBreakers,
        preferences: event.preferences,
        location: event.location,
      );
      
      _currentProfile = profile;
      _originalProfile = profile; // Update original to new state
      
      emit(ProfileUpdated(profile: profile));
      
      _logger.i('✅ Profile updated successfully');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error updating profile: ${e.message}');
      emit(ProfileError('Network error: ${e.message}'));
    } on UserException catch (e) {
      _logger.e('❌ User error updating profile: ${e.message}');
      emit(ProfileError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error updating profile: $e');
      emit(const ProfileError('Failed to update profile'));
    }
  }

  /// Upload photo
  Future<void> _onUploadPhoto(UploadPhoto event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('📸 Uploading temp photo for user: ${event.userId}');
      emit(const PhotoUploading());

      // Upload to temporary storage (instant upload on selection)
      final result = await _photoManager.uploadTempPhoto(
        File(event.imagePath),
      );

      // Store temp photo ID for confirmation on save
      _tempPhotoIds.add(result.mediaId);
      
      emit(PhotoUploaded(
        photo: ProfilePhoto(
          id: result.mediaId, // Use actual media ID
          url: result.url, // Temp URL for preview
          isPrimary: event.isPrimary,
          order: event.order,
          createdAt: DateTime.now(),
        ),
        updatedProfile: _currentProfile!, // Don't reload yet - not confirmed
      ));
      
      _logger.i('✅ Temp photo uploaded: ${result.mediaId}');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error uploading photo: ${e.message}');
      emit(PhotoUploadError('Network error: ${e.message}'));
    } on MediaException catch (e) {
      _logger.e('❌ Media error uploading photo: ${e.message}');
      emit(PhotoUploadError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error uploading photo: $e');
      emit(const PhotoUploadError('Failed to upload photo'));
    }
  }

  /// Delete photo
  Future<void> _onDeletePhoto(DeletePhoto event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('🗑️ Marking photo for deletion: ${event.photoId}');
      emit(const PhotoDeleting());

      // Mark photo for deletion (will delete on save)
      _photoManager.markPhotoForDeletion(event.photoId);

      // If it's a temp photo, also remove from temp list
      _tempPhotoIds.remove(event.photoId);

      emit(
        PhotoDeleted(
          updatedProfile: _currentProfile!, // Don't reload yet
          message: 'Photo marked for deletion',
        ),
      );
      
      _logger.i('✅ Photo marked for deletion');
    } catch (e) {
      _logger.e('❌ Unexpected error marking photo for deletion: $e');
      emit(const PhotoDeleteError('Failed to delete photo'));
    }
  }

  /// Reorder photos
  Future<void> _onReorderPhotos(ReorderPhotos event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('🔀 Reordering photos for user: ${event.userId}');
      emit(const ProfileLoading());

      final photoOrders = event.photoIds.asMap().entries.map((entry) =>
        PhotoOrder(photoId: entry.value, order: entry.key)).toList();

      await _profileService.reorderPhotos(
        photoOrders: photoOrders,
      );

      // Reload profile to get updated photos
      final updatedProfile = await _profileService.getProfile(event.userId);
      _currentProfile = updatedProfile;
      
      emit(PhotosReordered(updatedProfile));
      
      _logger.i('✅ Photos reordered successfully');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error reordering photos: ${e.message}');
      emit(ProfileError('Network error: ${e.message}'));
    } on MediaException catch (e) {
      _logger.e('❌ Media error reordering photos: ${e.message}');
      emit(ProfileError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error reordering photos: $e');
      emit(const ProfileError('Failed to reorder photos'));
    }
  }

  /// Update preferences
  Future<void> _onUpdatePreferences(UpdatePreferences event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('⚙️ Updating preferences for user: ${event.userId}');
      emit(const PreferencesUpdating());

      final preferences = await _profileService.updatePreferences(
        userId: event.userId,
        ageRange: event.ageRange,
        maxDistance: event.maxDistance,
        genderPreference: event.genderPreference,
        lookingFor: event.lookingFor,
        dealBreakers: event.dealBreakers,
        interests: event.interests,
        lifestyle: event.lifestyle,
      );
      
      emit(PreferencesUpdated(preferences: preferences));
      
      _logger.i('✅ Preferences updated successfully');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error updating preferences: ${e.message}');
      emit(PreferencesError('Network error: ${e.message}'));
    } on UserException catch (e) {
      _logger.e('❌ User error updating preferences: ${e.message}');
      emit(PreferencesError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error updating preferences: $e');
      emit(const PreferencesError('Failed to update preferences'));
    }
  }

  /// Request verification
  Future<void> _onRequestVerification(RequestVerification event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('🔒 Requesting ${event.verificationType} verification');
      emit(const VerificationRequesting());

      await _profileService.requestVerification(
        userId: event.userId,
        verificationType: event.verificationType,
      );
      
      emit(VerificationRequested(verificationType: event.verificationType));
      
      _logger.i('✅ Verification requested successfully');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error requesting verification: ${e.message}');
      emit(VerificationError('Network error: ${e.message}'));
    } on UserException catch (e) {
      _logger.e('❌ User error requesting verification: ${e.message}');
      emit(VerificationError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error requesting verification: $e');
      emit(const VerificationError('Failed to request verification'));
    }
  }

  /// Load available interests
  Future<void> _onLoadAvailableInterests(LoadAvailableInterests event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('📋 Loading available interests');
      
      final interests = await _profileService.getAvailableInterests();
      _availableInterests = interests;
      
      emit(AvailableInterestsLoaded(interests));
      
      _logger.i('✅ Available interests loaded: ${interests.length} items');
    } on NetworkException catch (e) {
      _logger.e('❌ Network error loading interests: ${e.message}');
      emit(ProfileError('Network error: ${e.message}'));
    } on UserException catch (e) {
      _logger.e('❌ User error loading interests: ${e.message}');
      emit(ProfileError(e.message));
    } catch (e) {
      _logger.e('❌ Unexpected error loading interests: $e');
      emit(const ProfileError('Failed to load interests'));
    }
  }

  /// Refresh profile
  Future<void> _onRefreshProfile(RefreshProfile event, Emitter<ProfileState> emit) async {
    await _onLoadProfile(LoadProfile(event.userId), emit);
  }

  /// Calculate completion percentage
  Future<void> _onCalculateCompletion(CalculateCompletion event, Emitter<ProfileState> emit) async {
    final completion = _profileService.calculateCompletionPercentage(event.profile);
    
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(completionPercentage: completion));
    }
  }

  /// Clear profile
  Future<void> _onClearProfile(ClearProfile event, Emitter<ProfileState> emit) async {
    _currentProfile = null;
    _availableInterests.clear();
    emit(const ProfileCleared());
    _logger.i('🧹 Profile data cleared');
  }

  /// Update location
  Future<void> _onUpdateLocation(UpdateLocation event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('📍 Updating location for user: ${event.userId}');
      
      // Update profile with new location
      await _onUpdateProfile(
        UpdateProfile(userId: event.userId, location: event.location),
        emit,
      );
      
      emit(LocationUpdated(location: event.location));
      
      _logger.i('✅ Location updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating location: $e');
      emit(const LocationError('Failed to update location'));
    }
  }

  /// Update privacy settings
  Future<void> _onUpdatePrivacySettings(UpdatePrivacySettings event, Emitter<ProfileState> emit) async {
    try {
      _logger.i('🔒 Updating privacy settings: ${event.settings}');
      
      // Call the profile service to save privacy settings to backend
      await _profileService.updatePrivacySettings(event.settings);
      
      emit(const PrivacySettingsUpdated());
      
      _logger.i('✅ Privacy settings updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating privacy settings: $e');
      emit(ProfileError('Failed to update privacy settings: ${e.toString()}'));
    }
  }

  /// Cancel profile changes (clear temp photos and deletion markers)
  void _onCancelProfileChanges(CancelProfileChanges event, Emitter<ProfileState> emit) {
    _logger.i('↩️ Canceling profile changes');
    
    // Clear temp photo IDs
    _tempPhotoIds.clear();
    
    // Clear deletion markers
    _photoManager.cancelPhotoChanges();
    
    // Temp files will auto-cleanup after 24 hours
    _logger.i('✅ Profile changes cancelled');
  }
}
