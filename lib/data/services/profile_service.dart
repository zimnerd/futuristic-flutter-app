import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../exceptions/app_exceptions.dart';
import '../models/profile_model.dart';
import '../../domain/entities/user_profile.dart' as domain;
import 'auth_service.dart';

/// Service for managing user profiles and related operations
class ProfileService {
  final ApiClient _apiClient;
  final AuthService _authService;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  ProfileService({
    required ApiClient apiClient,
    required AuthService authService,
    Logger? logger,
  }) : _apiClient = apiClient,
        _authService = authService,
        _logger = logger ?? Logger();

  /// Get user profile by ID
  Future<UserProfile> getProfile(String userId) async {
    try {
      _logger.i('🔍 Fetching profile for user: $userId');
      
      final response = await _apiClient.get('/profiles/$userId');
      
      if (response.statusCode == 200) {
        final profile = UserProfile.fromJson(response.data['profile']);
        _logger.i('✅ Profile fetched successfully');
        return profile;
      } else {
        throw NetworkException('Failed to fetch profile');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error fetching profile: ${e.message}');
      throw NetworkException('Failed to fetch profile: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error fetching profile: $e');
      throw UserException('Failed to fetch profile');
    }
  }

  /// Get current user's profile
  Future<domain.UserProfile> getCurrentProfile() async {
    try {
      _logger.i('🔍 Fetching current user profile');

      final response = await _apiClient.get('/profiles/me');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final profile = UserProfile.fromJson(data);
        _logger.i('✅ Current profile loaded successfully');
        return _convertToEntity(profile);
      } else {
        _logger.w('⚠️ Failed to load current profile: ${response.statusCode}');
        throw UserException('Failed to fetch current profile');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error fetching current profile: ${e.message}');
      throw NetworkException('Failed to fetch current profile: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error fetching current profile: $e');
      throw UserException('Failed to fetch current profile');
    }
  }

  /// Helper method to get current user ID
  Future<String> _getCurrentUserId() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      throw AuthException('No authenticated user found');
    }
    return currentUser.id;
  }

  /// Create new user profile
  Future<UserProfile> createProfile({
    required String userId,
    String? bio,
    List<String> interests = const [],
    UserPreferences? preferences,
    UserLocation? location,
  }) async {
    try {
      _logger.i('🆕 Creating profile for user: $userId');
      
      final data = {
        'userId': userId,
        'bio': bio,
        'interests': interests,
        'preferences': preferences?.toJson(),
        'location': location?.toJson(),
      };
      
      final response = await _apiClient.post('/profiles', data: data);
      
      if (response.statusCode == 201) {
        final profile = UserProfile.fromJson(response.data['profile']);
        _logger.i('✅ Profile created successfully');
        return profile;
      } else {
        throw NetworkException('Failed to create profile');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error creating profile: ${e.message}');
      throw NetworkException('Failed to create profile: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error creating profile: $e');
      throw UserException('Failed to create profile');
    }
  }

  /// Update profile using a UserProfile object (wrapper for BLoC compatibility)
  Future<domain.UserProfile> updateProfile(domain.UserProfile profile) async {
    final updatedProfile = await updateProfileWithDetails(
      userId: profile.id,
      bio: profile.bio,
      interests: profile.interests,
      dealBreakers: profile.lifestyle['dealBreakers'] as List<String>?,
      preferences: _convertPreferences(profile.preferences),
      location: _convertLocation(profile.location),
    );
    return _convertToEntity(updatedProfile);
  }

  /// Update existing user profile with individual parameters
  Future<UserProfile> updateProfileWithDetails({
    required String userId,
    String? bio,
    List<String>? interests,
    List<String>? dealBreakers,
    UserPreferences? preferences,
    UserLocation? location,
  }) async {
    try {
      _logger.i('🔄 Updating profile for user: $userId');
      
      final data = <String, dynamic>{};
      if (bio != null) data['bio'] = bio;
      if (interests != null) data['interests'] = interests;
      if (dealBreakers != null) data['dealBreakers'] = dealBreakers;
      if (preferences != null) data['preferences'] = preferences.toJson();
      if (location != null) data['location'] = location.toJson();
      
      final response = await _apiClient.put('/profiles/$userId', data: data);
      
      if (response.statusCode == 200) {
        final profile = UserProfile.fromJson(response.data['profile']);
        _logger.i('✅ Profile updated successfully');
        return profile;
      } else {
        throw NetworkException('Failed to update profile');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error updating profile: ${e.message}');
      throw NetworkException('Failed to update profile: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error updating profile: $e');
      throw UserException('Failed to update profile');
    }
  }

  /// Upload photo by path (wrapper for BLoC compatibility)
  Future<String> uploadPhoto(String photoPath) async {
    // Get the current user ID from auth service
    final currentUserId = await _getCurrentUserId();
    final file = File(photoPath);
    final photo = await uploadPhotoWithDetails(
      userId: currentUserId,
      imageFile: file,
    );
    return photo.url;
  }

  /// Upload profile photo with compression (original method)
  Future<ProfilePhoto> uploadPhotoWithDetails({
    required String userId,
    required File imageFile,
    bool isPrimary = false,
    int order = 0,
  }) async {
    try {
      _logger.i('📸 Uploading photo for user: $userId');
      
      // Compress image before uploading
      final compressedImage = await _compressImage(imageFile);
      
      // Create multipart form data
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          compressedImage.path,
          filename: 'photo_${_uuid.v4()}.jpg',
        ),
        'isPrimary': isPrimary,
        'order': order,
      });
      
      final response = await _apiClient.post(
        '/profiles/$userId/photos',
        data: formData,
      );
      
      if (response.statusCode == 201) {
        final photo = ProfilePhoto.fromJson(response.data['photo']);
        _logger.i('✅ Photo uploaded successfully');
        return photo;
      } else {
        throw NetworkException('Failed to upload photo');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error uploading photo: ${e.message}');
      throw NetworkException('Failed to upload photo: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error uploading photo: $e');
      throw MediaException('Failed to upload photo');
    }
  }

  /// Delete photo by URL (wrapper for BLoC compatibility)
  Future<void> deletePhoto(String photoUrl) async {
    // Extract photo ID from URL and get current user ID
    final currentUserId = await _getCurrentUserId();
    final photoId = photoUrl.split('/').last.split('.').first;
    return deletePhotoWithDetails(
      userId: currentUserId,
      photoId: photoId,
    );
  }

  /// Delete profile photo (original method)
  Future<void> deletePhotoWithDetails({
    required String userId,
    required String photoId,
  }) async {
    try {
      _logger.i('🗑️ Deleting photo: $photoId for user: $userId');
      
      final response = await _apiClient.delete(
        '/profiles/$userId/photos/$photoId',
      );
      
      if (response.statusCode == 200) {
        _logger.i('✅ Photo deleted successfully');
      } else {
        throw NetworkException('Failed to delete photo');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error deleting photo: ${e.message}');
      throw NetworkException('Failed to delete photo: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error deleting photo: $e');
      throw MediaException('Failed to delete photo');
    }
  }

  /// Reorder profile photos
  Future<void> reorderPhotos({
    required String userId,
    required List<PhotoOrder> photoOrders,
  }) async {
    try {
      _logger.i('🔀 Reordering photos for user: $userId');
      
      final data = {
        'photoOrders': photoOrders.map((order) => order.toJson()).toList(),
      };
      
      final response = await _apiClient.patch(
        '/profiles/$userId/photos/reorder',
        data: data,
      );
      
      if (response.statusCode == 200) {
        _logger.i('✅ Photos reordered successfully');
      } else {
        throw NetworkException('Failed to reorder photos');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error reordering photos: ${e.message}');
      throw NetworkException('Failed to reorder photos: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error reordering photos: $e');
      throw MediaException('Failed to reorder photos');
    }
  }

  /// Update user preferences
  Future<UserPreferences> updatePreferences({
    required String userId,
    AgeRange? ageRange,
    double? maxDistance,
    List<String>? genderPreference,
    List<String>? lookingFor,
    List<String>? dealBreakers,
    List<String>? interests,
    LifestylePreferences? lifestyle,
  }) async {
    try {
      _logger.i('⚙️ Updating preferences for user: $userId');
      
      final data = <String, dynamic>{};
      if (ageRange != null) data['ageRange'] = ageRange.toJson();
      if (maxDistance != null) data['maxDistance'] = maxDistance;
      if (genderPreference != null) data['genderPreference'] = genderPreference;
      if (lookingFor != null) data['lookingFor'] = lookingFor;
      if (dealBreakers != null) data['dealBreakers'] = dealBreakers;
      if (interests != null) data['interests'] = interests;
      if (lifestyle != null) data['lifestyle'] = lifestyle.toJson();
      
      final response = await _apiClient.put(
        '/preferences/$userId',
        data: data,
      );
      
      if (response.statusCode == 200) {
        final preferences = UserPreferences.fromJson(response.data['preferences']);
        _logger.i('✅ Preferences updated successfully');
        return preferences;
      } else {
        throw NetworkException('Failed to update preferences');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error updating preferences: ${e.message}');
      throw NetworkException('Failed to update preferences: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error updating preferences: $e');
      throw UserException('Failed to update preferences');
    }
  }

  /// Request profile verification
  Future<void> requestVerification({
    required String userId,
    required String verificationType, // 'photo' or 'identity'
  }) async {
    try {
      _logger.i('🔒 Requesting $verificationType verification for user: $userId');
      
      final data = {
        'type': verificationType,
      };
      
      final response = await _apiClient.post(
        '/profiles/$userId/verification',
        data: data,
      );
      
      if (response.statusCode == 200) {
        _logger.i('✅ Verification request submitted successfully');
      } else {
        throw NetworkException('Failed to request verification');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error requesting verification: ${e.message}');
      throw NetworkException('Failed to request verification: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error requesting verification: $e');
      throw UserException('Failed to request verification');
    }
  }

  /// Get available interests list
  Future<List<String>> getAvailableInterests() async {
    try {
      _logger.i('📋 Fetching available interests');
      
      final response = await _apiClient.get('/interests');
      
      if (response.statusCode == 200) {
        final interests = List<String>.from(response.data['interests']);
        _logger.i('✅ Interests fetched successfully: ${interests.length} items');
        return interests;
      } else {
        throw NetworkException('Failed to fetch interests');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error fetching interests: ${e.message}');
      throw NetworkException('Failed to fetch interests: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error fetching interests: $e');
      throw UserException('Failed to fetch interests');
    }
  }

  /// Calculate profile completion percentage
  int calculateCompletionPercentage(UserProfile profile) {
    int score = 0;
    int maxScore = 100;

    // Basic info (30 points)
    if (profile.bio != null && profile.bio!.isNotEmpty) score += 15;
    if (profile.interests.isNotEmpty) score += 15;

    // Photos (40 points)
    if (profile.photos.isNotEmpty) {
      score += 20; // At least one photo
      if (profile.photos.length >= 3) score += 10; // Multiple photos
      if (profile.photos.any((photo) => photo.isVerified)) score += 10; // Verified photo
    }

    // Preferences (20 points)
    if (profile.preferences.genderPreference.isNotEmpty) score += 5;
    if (profile.preferences.lookingFor.isNotEmpty) score += 5;
    if (profile.preferences.lifestyle.hobbies.isNotEmpty) score += 10;

    // Location (10 points)
    if (profile.location != null) score += 10;

    return (score / maxScore * 100).round();
  }

  /// Compress image for upload
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${_uuid.v4()}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      } else {
        _logger.w('⚠️ Image compression failed, using original file');
        return file;
      }
    } catch (e) {
      _logger.w('⚠️ Image compression error: $e, using original file');
      return file;
    }
  }

  /// Convert data model UserProfile to domain entity
  domain.UserProfile _convertToEntity(UserProfile dataModel) {
    // Simple conversion using available fields
    return domain.UserProfile(
      id: dataModel.id,
      name: dataModel.userId, // Using userId as name for now
      age: 25, // Default age for now
      bio: dataModel.bio ?? '',
      photos: [], // Empty photos list for now
      location: domain.UserLocation(
        latitude: dataModel.location?.latitude ?? 0.0,
        longitude: dataModel.location?.longitude ?? 0.0,
        address: dataModel.location?.city ?? '',
        city: dataModel.location?.city ?? '',
        country: dataModel.location?.country ?? '',
      ),
      interests: dataModel.interests,
    );
  }

  /// Convert domain preferences to data model preferences
  UserPreferences? _convertPreferences(Map<String, dynamic> preferences) {
    try {
      return UserPreferences(
        id: preferences['id'] ?? _uuid.v4(),
        userId: preferences['userId'] ?? '',
        ageRange: AgeRange(
          min: preferences['ageRangeMin'] ?? 18,
          max: preferences['ageRangeMax'] ?? 50,
        ),
        maxDistance: preferences['maxDistance']?.toDouble() ?? 50.0,
        genderPreference: List<String>.from(preferences['genderPreference'] ?? []),
        lookingFor: List<String>.from(preferences['lookingFor'] ?? []),
        dealBreakers: List<String>.from(preferences['dealBreakers'] ?? []),
        interests: List<String>.from(preferences['interests'] ?? []),
        lifestyle: LifestylePreferences(
          drinkingHabits: preferences['drinkingHabits'],
          smokingHabits: preferences['smokingHabits'],
          exerciseFrequency: preferences['exerciseFrequency'],
          dietType: preferences['dietType'],
          religiosity: preferences['religiosity'],
          politicalViews: preferences['politicalViews'],
          hobbies: List<String>.from(preferences['hobbies'] ?? []),
          musicGenres: List<String>.from(preferences['musicGenres'] ?? []),
          travelPreferences: List<String>.from(preferences['travelPreferences'] ?? []),
        ),
        createdAt: DateTime.tryParse(preferences['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(preferences['updatedAt'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to convert preferences: $e');
      return null;
    }
  }

  /// Convert domain location to data model location
  UserLocation _convertLocation(domain.UserLocation location) {
    return UserLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      city: location.city,
      country: location.country,
      updatedAt: DateTime.now(),
    );
  }
}

/// Helper class for photo ordering
class PhotoOrder {
  final String photoId;
  final int order;

  PhotoOrder({
    required this.photoId,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'photoId': photoId,
      'order': order,
    };
  }
}
