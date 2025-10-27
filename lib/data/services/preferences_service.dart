import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/filter_preferences.dart';

/// Cache entry for filter options with TTL
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  static const Duration defaultTTL = Duration(hours: 24);

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired() {
    return DateTime.now().difference(timestamp) > defaultTTL;
  }
}

/// Service for managing user filter preferences
/// Handles saving, loading, and syncing filter preferences with backend
class PreferencesService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  // Cache for filter options (24-hour TTL)
  _CacheEntry<List<String>>? _cachedInterests;
  _CacheEntry<List<String>>? _cachedEducationLevels;
  _CacheEntry<List<String>>? _cachedOccupations;
  _CacheEntry<List<String>>? _cachedRelationshipTypes;
  _CacheEntry<List<String>>? _cachedDrinkingOptions;
  _CacheEntry<List<String>>? _cachedSmokingOptions;
  _CacheEntry<List<String>>? _cachedExerciseOptions;

  PreferencesService(this._apiClient);

  /// Get user's current filter preferences from backend
  Future<FilterPreferences> getFilterPreferences() async {
    try {
      _logger.i('📥 Fetching filter preferences from backend...');

      final response = await _apiClient.get(ApiConstants.usersPreferences);

      if (response.statusCode == 200) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final data = responseData['data'] as Map<String, dynamic>;
          final preferences = FilterPreferences.fromJson(data);
          _logger.i(
            '✅ Filter preferences loaded: age ${preferences.minAge}-${preferences.maxAge}, distance ${preferences.maxDistance}km',
          );
          return preferences;
        } catch (e, stackTrace) {
          _logger.e('❌ Error parsing filter preferences JSON: $e');
          _logger.e('Stack trace: $stackTrace');
          _logger.e('Response data: ${response.data}');
          return const FilterPreferences();
        }
      } else {
        _logger.w(
          '❌ Failed to load preferences (status ${response.statusCode}), using defaults',
        );
        return const FilterPreferences();
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Network error loading filter preferences: $e');
      _logger.e('Stack trace: $stackTrace');
      return const FilterPreferences();
    }
  }

  /// Save filter preferences to backend
  Future<bool> saveFilterPreferences(FilterPreferences preferences) async {
    try {
      _logger.d('Saving filter preferences to backend');

      final response = await _apiClient.put(
        ApiConstants.usersPreferences,
        data: preferences.toJson(),
      );

      if (response.statusCode == 200) {
        _logger.d('Filter preferences saved successfully');
        return true;
      } else {
        _logger.e('Failed to save preferences: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error saving filter preferences: $e');
      return false;
    }
  }

  /// Get available interests for filtering
  Future<List<String>> getAvailableInterests() async {
    // Return cached data if valid
    if (_cachedInterests != null && !_cachedInterests!.isExpired()) {
      _logger.d(
        '💾 Returning cached interests (${_cachedInterests!.data.length} items)',
      );
      return _cachedInterests!.data;
    }

    try {
      _logger.i('📥 Fetching available interests from API...');

      final response = await _apiClient.get('${ApiConstants.users}/interests');

      if (response.statusCode == 200) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final data = responseData['data'] as Map<String, dynamic>;
          final interests = List<String>.from(data['interests'] ?? []);
          _logger.i(
            '✅ Loaded ${interests.length} available interests from API',
          );

          // Cache the results
          _cachedInterests = _CacheEntry(interests);
          return interests;
        } catch (e, stackTrace) {
          _logger.e('❌ Error parsing interests JSON: $e');
          _logger.e('Stack trace: $stackTrace');
          _logger.e('Response data: ${response.data}');
          return _defaultInterests;
        }
      } else {
        _logger.w(
          '❌ Failed to load interests (status ${response.statusCode}), using defaults',
        );
        return _defaultInterests;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Network error loading interests: $e');
      _logger.e('Stack trace: $stackTrace');
      return _defaultInterests;
    }
  }

  /// Get available education levels
  Future<List<String>> getEducationLevels() async {
    // Return cached data if valid
    if (_cachedEducationLevels != null &&
        !_cachedEducationLevels!.isExpired()) {
      _logger.d(
        '💾 Returning cached education levels (${_cachedEducationLevels!.data.length} items)',
      );
      return _cachedEducationLevels!.data;
    }

    try {
      _logger.i('📥 Fetching education levels from API...');

      final response = await _apiClient.get(
        '${ApiConstants.users}/education-levels',
      );

      if (response.statusCode == 200) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final data = responseData['data'] as Map<String, dynamic>;
          final levels = List<String>.from(data['levels'] ?? []);
          _logger.i('✅ Loaded ${levels.length} education levels from API');

          // Cache the results
          _cachedEducationLevels = _CacheEntry(levels);
          return levels;
        } catch (e, stackTrace) {
          _logger.e('❌ Error parsing education levels JSON: $e');
          _logger.e('Stack trace: $stackTrace');
          _logger.e('Response data: ${response.data}');
          return _defaultEducationLevels;
        }
      } else {
        _logger.w(
          '❌ Failed to load education levels (status ${response.statusCode}), using defaults',
        );
        return _defaultEducationLevels;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Network error loading education levels: $e');
      _logger.e('Stack trace: $stackTrace');
      return _defaultEducationLevels;
    }
  }

  /// Get available occupations
  Future<List<String>> getOccupations() async {
    // Return cached data if valid
    if (_cachedOccupations != null && !_cachedOccupations!.isExpired()) {
      _logger.d(
        '💾 Returning cached occupations (${_cachedOccupations!.data.length} items)',
      );
      return _cachedOccupations!.data;
    }

    try {
      _logger.i('📥 Fetching occupations from API...');
      final response = await _apiClient.getOccupations();

      if (response.statusCode == 200 && response.data != null) {
        try {
          final data = response.data;
          if (data is Map && data['data'] != null) {
            final occupations = (data['data']['occupations'] as List?)
                ?.map((e) => e.toString())
                .toList();
            if (occupations != null && occupations.isNotEmpty) {
              _logger.i('✅ Loaded ${occupations.length} occupations from API');

              // Cache the results
              _cachedOccupations = _CacheEntry(occupations);
              return occupations;
            }
          }
          _logger.w('❌ Response has invalid data structure');
        } catch (e, stackTrace) {
          _logger.e('❌ Error parsing occupations data: $e');
          _logger.e('Stack trace: $stackTrace');
          _logger.e('Response data: ${response.data}');
        }
      } else {
        _logger.w(
          '❌ Failed to load occupations (status ${response.statusCode ?? 'null'}), using defaults',
        );
      }

      return _defaultOccupations;
    } catch (e, stackTrace) {
      _logger.e('❌ Network error loading occupations: $e');
      _logger.e('Stack trace: $stackTrace');
      return _defaultOccupations;
    }
  }

  /// Get available relationship types
  Future<List<String>> getRelationshipTypes() async {
    // Return cached data if valid
    if (_cachedRelationshipTypes != null &&
        !_cachedRelationshipTypes!.isExpired()) {
      _logger.d(
        'Returning cached relationship types (${_cachedRelationshipTypes!.data.length} items)',
      );
      return _cachedRelationshipTypes!.data;
    }

    try {
      _logger.d('Fetching relationship types from API');
      final response = await _apiClient.getRelationshipTypes();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final types = (data['data']['types'] as List?)
              ?.map((e) => e.toString())
              .toList();
          if (types != null && types.isNotEmpty) {
            _logger.i('Loaded ${types.length} relationship types from API');

            // Cache the results
            _cachedRelationshipTypes = _CacheEntry(types);
            return types;
          }
        }
      }

      _logger.w('Backend returned invalid data, using defaults');
      return _defaultRelationshipTypes;
    } catch (e) {
      _logger.e('Error loading relationship types: $e');
      return _defaultRelationshipTypes;
    }
  }

  /// Get available drinking options
  Future<List<String>> getDrinkingOptions() async {
    // Return cached data if valid
    if (_cachedDrinkingOptions != null &&
        !_cachedDrinkingOptions!.isExpired()) {
      _logger.d(
        'Returning cached drinking options (${_cachedDrinkingOptions!.data.length} items)',
      );
      return _cachedDrinkingOptions!.data;
    }

    try {
      _logger.d('Fetching drinking options from API');
      final response = await _apiClient.getDrinkingOptions();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final options = (data['data']['options'] as List?)
              ?.map((e) => e.toString())
              .toList();
          if (options != null && options.isNotEmpty) {
            _logger.i('Loaded ${options.length} drinking options from API');

            // Cache the results
            _cachedDrinkingOptions = _CacheEntry(options);
            return options;
          }
        }
      }

      _logger.w('Backend returned invalid data, using defaults');
      return _defaultDrinkingOptions;
    } catch (e) {
      _logger.e('Error loading drinking options: $e');
      return _defaultDrinkingOptions;
    }
  }

  /// Get available smoking options
  Future<List<String>> getSmokingOptions() async {
    // Return cached data if valid
    if (_cachedSmokingOptions != null && !_cachedSmokingOptions!.isExpired()) {
      _logger.d(
        'Returning cached smoking options (${_cachedSmokingOptions!.data.length} items)',
      );
      return _cachedSmokingOptions!.data;
    }

    try {
      _logger.d('Fetching smoking options from API');
      final response = await _apiClient.getSmokingOptions();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final options = (data['data']['options'] as List?)
              ?.map((e) => e.toString())
              .toList();
          if (options != null && options.isNotEmpty) {
            _logger.i('Loaded ${options.length} smoking options from API');

            // Cache the results
            _cachedSmokingOptions = _CacheEntry(options);
            return options;
          }
        }
      }

      _logger.w('Backend returned invalid data, using defaults');
      return _defaultSmokingOptions;
    } catch (e) {
      _logger.e('Error loading smoking options: $e');
      return _defaultSmokingOptions;
    }
  }

  /// Get available exercise options
  Future<List<String>> getExerciseOptions() async {
    // Return cached data if valid
    if (_cachedExerciseOptions != null &&
        !_cachedExerciseOptions!.isExpired()) {
      _logger.d(
        'Returning cached exercise options (${_cachedExerciseOptions!.data.length} items)',
      );
      return _cachedExerciseOptions!.data;
    }

    try {
      _logger.d('Fetching exercise options from API');
      final response = await _apiClient.getExerciseOptions();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final options = (data['data']['options'] as List?)
              ?.map((e) => e.toString())
              .toList();
          if (options != null && options.isNotEmpty) {
            _logger.i('Loaded ${options.length} exercise options from API');

            // Cache the results
            _cachedExerciseOptions = _CacheEntry(options);
            return options;
          }
        }
      }

      _logger.w('Backend returned invalid data, using defaults');
      return _defaultExerciseOptions;
    } catch (e) {
      _logger.e('Error loading exercise options: $e');
      return _defaultExerciseOptions;
    }
  }

  /// Reset filters to default values
  Future<bool> resetFilters() async {
    try {
      _logger.d('Resetting filters to defaults');
      const defaultPreferences = FilterPreferences();
      return await saveFilterPreferences(defaultPreferences);
    } catch (e) {
      _logger.e('Error resetting filters: $e');
      return false;
    }
  }

  /// Validate filter preferences
  bool validatePreferences(FilterPreferences preferences) {
    if (preferences.minAge < 18 || preferences.minAge > 99) {
      _logger.w('Invalid minimum age: ${preferences.minAge}');
      return false;
    }

    if (preferences.maxAge < 18 || preferences.maxAge > 99) {
      _logger.w('Invalid maximum age: ${preferences.maxAge}');
      return false;
    }

    if (preferences.minAge > preferences.maxAge) {
      _logger.w('Minimum age greater than maximum age');
      return false;
    }

    if (preferences.maxDistance < 1 || preferences.maxDistance > 500) {
      _logger.w('Invalid distance: ${preferences.maxDistance}');
      return false;
    }

    return true;
  }

  /// Default interests if backend is unavailable
  static const List<String> _defaultInterests = [
    'Travel',
    'Music',
    'Sports',
    'Reading',
    'Cooking',
    'Movies',
    'Art',
    'Technology',
    'Fitness',
    'Photography',
    'Dancing',
    'Gaming',
    'Nature',
    'Fashion',
    'Food',
  ];

  /// Default education levels if backend is unavailable
  static const List<String> _defaultEducationLevels = [
    'High School',
    'Some College',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Trade School',
    'Other',
  ];

  /// Default occupations if backend is unavailable
  static const List<String> _defaultOccupations = [
    'Student',
    'Engineer',
    'Teacher',
    'Doctor',
    'Nurse',
    'Artist',
    'Designer',
    'Developer',
    'Manager',
    'Entrepreneur',
    'Marketing',
    'Sales',
    'Finance',
    'Healthcare',
    'Hospitality',
    'Retail',
    'Other',
  ];

  /// Default relationship types
  static const List<String> _defaultRelationshipTypes = [
    'Serious Relationship',
    'Casual Dating',
    'Friendship',
    'Not Sure Yet',
  ];

  /// Default drinking options
  static const List<String> _defaultDrinkingOptions = [
    'Never',
    'Socially',
    'Regularly',
    'Prefer Not to Say',
  ];

  /// Default smoking options
  static const List<String> _defaultSmokingOptions = [
    'Never',
    'Socially',
    'Regularly',
    'Trying to Quit',
  ];

  /// Default exercise options
  static const List<String> _defaultExerciseOptions = [
    'Daily',
    'Several Times a Week',
    'Once a Week',
    'Rarely',
    'Never',
  ];

  /// Get user privacy settings
  ///
  /// Returns privacy settings:
  /// - showAge: Display age on profile
  /// - showDistance: Display distance from other users
  /// - showLastActive: Display last active timestamp
  /// - showOnlineStatus: Display online/offline status
  /// - incognitoMode: Browse anonymously
  ///
  /// Throws exception if:
  /// - Network error
  /// - User not authenticated
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      _logger.d('PreferencesService: Fetching privacy settings');

      final response = await _apiClient.get(ApiConstants.usersPrivacy);

      _logger.d(
        'PreferencesService: Privacy settings response: ${response.data}',
      );

      final result = response.data as Map<String, dynamic>;

      // Return privacy settings with defaults
      return {
        'showAge': result['showAge'] as bool? ?? true,
        'showDistance': result['showDistance'] as bool? ?? true,
        'showLastActive': result['showLastActive'] as bool? ?? true,
        'showOnlineStatus': result['showOnlineStatus'] as bool? ?? true,
        'incognitoMode': result['incognitoMode'] as bool? ?? false,
      };
    } catch (e) {
      _logger.e('PreferencesService: Error fetching privacy settings: $e');
      rethrow;
    }
  }

  /// Update user privacy settings
  ///
  /// Parameters:
  /// - settings: Map of privacy settings to update
  ///
  /// Returns true if update successful
  ///
  /// Throws exception if:
  /// - Network error
  /// - User not authenticated
  /// - Invalid settings
  Future<bool> updatePrivacySettings(Map<String, bool> settings) async {
    try {
      _logger.d('PreferencesService: Updating privacy settings: $settings');

      final response = await _apiClient.post(
        ApiConstants.usersPrivacy,
        data: settings,
      );

      _logger.i('PreferencesService: Privacy settings updated successfully');

      // Check for success in response
      final result = response.data as Map<String, dynamic>?;
      return result?['success'] as bool? ?? true;
    } catch (e) {
      _logger.e('PreferencesService: Error updating privacy settings: $e');
      rethrow;
    }
  }
}
