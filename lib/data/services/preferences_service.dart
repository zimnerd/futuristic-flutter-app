import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/filter_preferences.dart';

/// Service for managing user filter preferences
/// Handles saving, loading, and syncing filter preferences with backend
class PreferencesService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  PreferencesService(this._apiClient);

  /// Get user's current filter preferences from backend
  Future<FilterPreferences> getFilterPreferences() async {
    try {
      _logger.d('Fetching filter preferences from backend');
      
      final response = await _apiClient.get(ApiConstants.usersPreferences);
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;
        final preferences = FilterPreferences.fromJson(data);
        _logger.d('Filter preferences loaded successfully');
        return preferences;
      } else {
        _logger.w('Failed to load preferences, using defaults');
        return const FilterPreferences();
      }
    } catch (e) {
      _logger.e('Error loading filter preferences: $e');
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
    try {
      _logger.d('Fetching available interests');
      
      final response = await _apiClient.get('${ApiConstants.users}/interests');
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;
        final interests = List<String>.from(data['interests'] ?? []);
        _logger.d('Loaded ${interests.length} available interests');
        return interests;
      } else {
        _logger.w('Failed to load interests, using defaults');
        return _defaultInterests;
      }
    } catch (e) {
      _logger.e('Error loading interests: $e');
      return _defaultInterests;
    }
  }

  /// Get available education levels
  Future<List<String>> getEducationLevels() async {
    try {
      _logger.d('Fetching education levels');
      
      final response = await _apiClient.get(
        '${ApiConstants.users}/education-levels',
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;
        final levels = List<String>.from(data['levels'] ?? []);
        _logger.d('Loaded ${levels.length} education levels');
        return levels;
      } else {
        _logger.w('Failed to load education levels, using defaults');
        return _defaultEducationLevels;
      }
    } catch (e) {
      _logger.e('Error loading education levels: $e');
      return _defaultEducationLevels;
    }
  }

  /// Get available occupations
  Future<List<String>> getOccupations() async {
    // For now, return default occupations
    // TODO: Implement backend API call when available
    _logger.d('Using default occupations');
    return _defaultOccupations;
  }

  /// Get available relationship types
  Future<List<String>> getRelationshipTypes() async {
    // For now, return default relationship types
    // TODO: Implement backend API call when available
    _logger.d('Using default relationship types');
    return _defaultRelationshipTypes;
  }

  /// Get available drinking options
  Future<List<String>> getDrinkingOptions() async {
    // For now, return default drinking options
    // TODO: Implement backend API call when available
    _logger.d('Using default drinking options');
    return _defaultDrinkingOptions;
  }

  /// Get available smoking options
  Future<List<String>> getSmokingOptions() async {
    // For now, return default smoking options
    // TODO: Implement backend API call when available
    _logger.d('Using default smoking options');
    return _defaultSmokingOptions;
  }

  /// Get available exercise options
  Future<List<String>> getExerciseOptions() async {
    // For now, return default exercise options
    // TODO: Implement backend API call when available
    _logger.d('Using default exercise options');
    return _defaultExerciseOptions;
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
}

