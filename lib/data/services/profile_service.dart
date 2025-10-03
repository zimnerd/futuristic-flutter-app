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
      
      final response = await _apiClient.get('/users/$userId');
      
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

      final response = await _apiClient.get('/users/me');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final userData = responseData['data'] as Map<String, dynamic>;
        
        _logger.i('✅ Current profile loaded successfully');
        
        // Convert API user data to domain UserProfile entity
        return _convertUserDataToEntity(userData);
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
  
  /// Convert API user data to domain UserProfile entity
  domain.UserProfile _convertUserDataToEntity(Map<String, dynamic> userData) {
    // Extract photos from API response
    final photosList = userData['photos'] as List<dynamic>?;
    final photos =
        photosList?.map((photo) {
          // Handle both string URL format (legacy) and Photo object format (new)
          if (photo is String) {
            return domain.ProfilePhoto(
              id: _uuid.v4(),
              url: photo,
              order: 0,
              isVerified: userData['verified'] as bool? ?? false,
            );
          } else if (photo is Map<String, dynamic>) {
            return domain.ProfilePhoto(
              id: photo['id'] as String? ?? _uuid.v4(),
              url: photo['url'] as String,
              order: photo['order'] as int? ?? 0,
              isVerified:
                  photo['isVerified'] as bool? ??
                  (userData['verified'] as bool? ?? false),
              uploadedAt: photo['createdAt'] != null
                  ? DateTime.parse(photo['createdAt'] as String)
                  : null,
              description: photo['description'] as String?,
            );
          } else {
            throw Exception('Invalid photo format: $photo');
          }
        }).toList() ??
        [];

    // Calculate age from user data if available
    int age = 18; // Default minimum age
    DateTime? dateOfBirth;
    
    if (userData['dateOfBirth'] != null) {
      dateOfBirth = DateTime.parse(userData['dateOfBirth'] as String);
      age = DateTime.now().difference(dateOfBirth).inDays ~/ 365;
    } else if (userData['age'] != null) {
      age = userData['age'] as int;
    }

    // Extract age change count
    final ageChangeCount = userData['ageChangeCount'] as int? ?? 0;

    // Extract name
    final firstName = userData['firstName'] as String?;
    final lastName = userData['lastName'] as String?;
    final username = userData['username'] as String?;
    final name = firstName != null && lastName != null
        ? '$firstName $lastName'
        : (username ?? 'Unknown');

    // Parse location
    final locationStr = userData['location'] as String?;
    final location = _parseLocation(locationStr ?? '');

    return domain.UserProfile(
      id: userData['id'] as String? ?? '',
      name: name,
      age: age,
      dateOfBirth: dateOfBirth,
      ageChangeCount: ageChangeCount,
      bio: userData['bio'] as String? ?? '',
      photos: photos,
      location: location,
      isVerified: userData['verified'] as bool? ?? false,
      verified: userData['verified'] as bool? ?? false,
      interests:
          (userData['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      gender: userData['gender'] as String?,
      lastActiveAt: userData['lastActive'] != null
          ? DateTime.parse(userData['lastActive'] as String)
          : null,
      isOnline: userData['isOnline'] as bool? ?? false,
    );
  }

  /// Parse location string into UserLocation
  domain.UserLocation _parseLocation(String locationStr) {
    // Location format: "City, Country" or just "City"
    final parts = locationStr.split(', ');
    return domain.UserLocation(
      latitude: 0.0, // Default coordinates
      longitude: 0.0,
      address: locationStr,
      city: parts.isNotEmpty ? parts[0] : '',
      country: parts.length > 1 ? parts[1] : '',
    );
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
      
      final response = await _apiClient.post('/users/me/profile', data: data);
      
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
  /// 
  /// NOTE: This method now tracks changed fields and only sends what actually changed.
  /// The backend will only update fields that are provided (not null/undefined).
  Future<domain.UserProfile> updateProfile(
    domain.UserProfile profile, {
    domain.UserProfile? originalProfile,
  }) async {
    _logger.i('🔄 Starting profile update for user: ${profile.id}');

    try {
      // Build map of only changed fields
      final changedBasicFields = <String, dynamic>{};
      final changedExtendedFields = <String, dynamic>{};

      // Check basic user info changes (name, dateOfBirth, bio)
      if (originalProfile != null) {
        // Check name change
        if (profile.name != originalProfile.name && profile.name.isNotEmpty) {
          final nameParts = profile.name.trim().split(' ');
          if (nameParts.isNotEmpty) {
            changedBasicFields['firstName'] = nameParts.first;
            if (nameParts.length > 1) {
              changedBasicFields['lastName'] = nameParts.sublist(1).join(' ');
            }
          }
        }

        // Check DOB change (compare date values only)
        if (profile.dateOfBirth != null &&
            originalProfile.dateOfBirth != null &&
            !_isSameDate(profile.dateOfBirth, originalProfile.dateOfBirth)) {
          final year = profile.dateOfBirth!.year.toString().padLeft(4, '0');
          final month = profile.dateOfBirth!.month.toString().padLeft(2, '0');
          final day = profile.dateOfBirth!.day.toString().padLeft(2, '0');
          changedBasicFields['dateOfBirth'] = '$year-$month-$day';
        } else if (profile.dateOfBirth != null &&
            originalProfile.dateOfBirth == null) {
          // First time setting DOB
          final year = profile.dateOfBirth!.year.toString().padLeft(4, '0');
          final month = profile.dateOfBirth!.month.toString().padLeft(2, '0');
          final day = profile.dateOfBirth!.day.toString().padLeft(2, '0');
          changedBasicFields['dateOfBirth'] = '$year-$month-$day';
        }

        // Check bio change
        if (profile.bio != originalProfile.bio) {
          changedBasicFields['bio'] = profile.bio;
        }

        // Check interests change (User model field, goes to /users/me)
        if (!_areListsEqual(profile.interests, originalProfile.interests)) {
          changedBasicFields['interests'] = profile.interests;
        }

        // Check extended profile fields (Profile model fields, go to /users/me/profile)
        // Map mobile fields to backend Prisma schema fields:
        // - job → occupation (backend field name)
        // - school → education (backend field name)
        // - company → not in schema (store in occupation if needed)
        if (profile.job != originalProfile.job && profile.job != null) {
          changedExtendedFields['occupation'] = profile.job;
        }
        if (profile.school != originalProfile.school &&
            profile.school != null) {
          changedExtendedFields['education'] = profile.school;
        }
        // Note: 'company' field not in backend Profile schema - combining with occupation if present
        if (profile.company != originalProfile.company &&
            profile.company != null) {
          // Optionally combine company with occupation: "Job Title at Company"
          final occupation = profile.job ?? '';
          if (occupation.isNotEmpty) {
            changedExtendedFields['occupation'] =
                '$occupation at ${profile.company}';
          }
        }
      } else {
        // No original profile - send all fields (backward compatibility)
        _logger.w('⚠️ No original profile provided - sending all fields');
        return _updateProfileLegacy(profile);
      }

      // Update basic user info if any changed
      if (changedBasicFields.isNotEmpty) {
        _logger.i(
          '📤 Sending basic user info update: ${changedBasicFields.keys}',
        );
        final response = await _apiClient.put(
          '/users/me',
          data: changedBasicFields,
        );
        if (response.statusCode != 200) {
          throw NetworkException('Failed to update basic user info');
        }
      } else {
        _logger.i('ℹ️ No basic user info changed');
      }

      // Update extended profile info if any changed
      if (changedExtendedFields.isNotEmpty) {
        _logger.i(
          '📤 Sending extended profile update: ${changedExtendedFields.keys}',
        );
        final response = await _apiClient.put(
          '/users/me/profile',
          data: changedExtendedFields,
        );
        if (response.statusCode != 200) {
          throw NetworkException('Failed to update extended profile');
        }
      } else {
        _logger.i('ℹ️ No extended profile fields changed');
      }

      // Fetch the updated profile from backend to get calculated age and other updates
      _logger.i('📥 Fetching updated profile from backend');
      final updatedProfile = await getCurrentProfile();

      _logger.i('✅ Profile update completed successfully');
      return updatedProfile;
    } catch (e) {
      _logger.e('❌ Profile update failed: $e');
      rethrow;
    }
  }

  /// Helper to check if two dates are the same (ignore time component)
  bool _isSameDate(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Helper to check if two lists are equal
  bool _areListsEqual(List<dynamic> list1, List<dynamic> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Legacy update method that sends all fields (for backward compatibility)
  Future<domain.UserProfile> _updateProfileLegacy(
    domain.UserProfile profile,
  ) async {
    _logger.i('🔄 Using legacy profile update (all fields)');

    try {
      // Update basic user info (name, dateOfBirth, bio, interests) via /users/me endpoint
      // Note: interests is a User model field, not Profile model field
      final basicData = <String, dynamic>{};

      // Split name into firstName and lastName
      if (profile.name.isNotEmpty) {
        final nameParts = profile.name.trim().split(' ');
        if (nameParts.isNotEmpty) {
          basicData['firstName'] = nameParts.first;
          if (nameParts.length > 1) {
            basicData['lastName'] = nameParts.sublist(1).join(' ');
          }
        }
      }

      if (profile.dateOfBirth != null) {
        final year = profile.dateOfBirth!.year.toString().padLeft(4, '0');
        final month = profile.dateOfBirth!.month.toString().padLeft(2, '0');
        final day = profile.dateOfBirth!.day.toString().padLeft(2, '0');
        basicData['dateOfBirth'] = '$year-$month-$day';
      }

      if (profile.bio.isNotEmpty) {
        basicData['bio'] = profile.bio;
      }

      if (profile.interests.isNotEmpty) {
        basicData['interests'] = profile.interests;
      }

      if (basicData.isNotEmpty) {
        final response = await _apiClient.put('/users/me', data: basicData);
        if (response.statusCode != 200) {
          throw NetworkException('Failed to update basic user info');
        }
      }

      // Update extended profile info if needed (occupation, education from job/school)
      // Map legacy fields: job → occupation, school → education
      final extendedData = <String, dynamic>{};

      if (profile.job != null && profile.job!.isNotEmpty) {
        if (profile.company != null && profile.company!.isNotEmpty) {
          extendedData['occupation'] = '${profile.job} at ${profile.company}';
        } else {
          extendedData['occupation'] = profile.job;
        }
      }
      
      if (profile.school != null && profile.school!.isNotEmpty) {
        extendedData['education'] = profile.school;
      }
      
      if (extendedData.isNotEmpty) {
        final response = await _apiClient.put(
          '/users/me/profile',
          data: extendedData,
        );
        if (response.statusCode != 200) {
          throw NetworkException('Failed to update extended profile');
        }
      }

      // Fetch the updated profile from backend to get calculated age and other updates
      _logger.i('📥 Fetching updated profile from backend');
      final updatedProfile = await getCurrentProfile();
      
      _logger.i('✅ Profile update completed successfully');
      return updatedProfile;
    } catch (e) {
      _logger.e('❌ Profile update failed: $e');
      rethrow;
    }
  }

  /// Update basic user information (name, date of birth, bio)
  /// This calls the /users/me endpoint for User table fields
  Future<void> updateBasicUserInfo({
    required String userId,
    String? name,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    try {
      _logger.i('🔄 Updating basic user info for user: $userId');

      final data = <String, dynamic>{};

      // Split name into firstName and lastName if provided
      if (name != null && name.isNotEmpty) {
        final nameParts = name.trim().split(' ');
        if (nameParts.isNotEmpty) {
          data['firstName'] = nameParts.first;
          if (nameParts.length > 1) {
            data['lastName'] = nameParts.sublist(1).join(' ');
          }
        }
      }

      if (dateOfBirth != null) {
        // Convert to date-only format (YYYY-MM-DD) without time component
        // This prevents time zone issues and matches backend expectations
        final year = dateOfBirth.year.toString().padLeft(4, '0');
        final month = dateOfBirth.month.toString().padLeft(2, '0');
        final day = dateOfBirth.day.toString().padLeft(2, '0');
        data['dateOfBirth'] = '$year-$month-$day';
      }
      if (bio != null && bio.isNotEmpty) data['bio'] = bio;

      if (data.isEmpty) {
        _logger.i('ℹ️ No basic user info to update');
        return;
      }

      _logger.i('📤 Sending basic user info update: $data');
      final response = await _apiClient.put('/users/me', data: data);

      if (response.statusCode == 200) {
        _logger.i('✅ Basic user info updated successfully');
      } else {
        throw NetworkException('Failed to update basic user info');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error updating basic user info: ${e.message}');
      _logger.e('Response data: ${e.response?.data}');
      throw NetworkException('Failed to update basic user info: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error updating basic user info: $e');
      throw UserException('Failed to update basic user info');
    }
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
      
      final response = await _apiClient.put('/users/me/profile', data: data);
      
      if (response.statusCode == 200) {
        final profile = UserProfile.fromJson(response.data['data']);
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
        '/media/upload',
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
        '/media/files/$photoId',
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
        '/users/me/photos/reorder',
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
        '/users/me/verification',
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
