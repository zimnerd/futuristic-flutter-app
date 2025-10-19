import '../../../domain/entities/filter_preferences.dart';

/// States for FilterBLoC
abstract class FilterState {}

/// Initial state
class FilterInitial extends FilterState {}

/// Loading state
class FilterLoading extends FilterState {}

/// Preferences loaded successfully
class FilterLoaded extends FilterState {
  final FilterPreferences preferences;
  final List<String> availableInterests;
  final List<String> availableEducationLevels;
  final List<String> availableOccupations;
  final List<String> availableRelationshipTypes;
  final List<String> availableDrinkingOptions;
  final List<String> availableSmokingOptions;
  final List<String> availableExerciseOptions;

  FilterLoaded({
    required this.preferences,
    this.availableInterests = const [],
    this.availableEducationLevels = const [],
    this.availableOccupations = const [],
    this.availableRelationshipTypes = const [],
    this.availableDrinkingOptions = const [],
    this.availableSmokingOptions = const [],
    this.availableExerciseOptions = const [],
  });

  FilterLoaded copyWith({
    FilterPreferences? preferences,
    List<String>? availableInterests,
    List<String>? availableEducationLevels,
    List<String>? availableOccupations,
    List<String>? availableRelationshipTypes,
    List<String>? availableDrinkingOptions,
    List<String>? availableSmokingOptions,
    List<String>? availableExerciseOptions,
  }) {
    return FilterLoaded(
      preferences: preferences ?? this.preferences,
      availableInterests: availableInterests ?? this.availableInterests,
      availableEducationLevels:
          availableEducationLevels ?? this.availableEducationLevels,
      availableOccupations: availableOccupations ?? this.availableOccupations,
      availableRelationshipTypes:
          availableRelationshipTypes ?? this.availableRelationshipTypes,
      availableDrinkingOptions:
          availableDrinkingOptions ?? this.availableDrinkingOptions,
      availableSmokingOptions:
          availableSmokingOptions ?? this.availableSmokingOptions,
      availableExerciseOptions:
          availableExerciseOptions ?? this.availableExerciseOptions,
    );
  }
}

/// Saving preferences
class FilterSaving extends FilterState {
  final FilterPreferences preferences;

  FilterSaving(this.preferences);
}

/// Preferences saved successfully
class FilterSaved extends FilterState {
  final FilterPreferences preferences;

  FilterSaved(this.preferences);
}

/// Error state
class FilterError extends FilterState {
  final String message;

  FilterError(this.message);
}
