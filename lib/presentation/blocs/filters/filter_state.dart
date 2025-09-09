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

  FilterLoaded({
    required this.preferences,
    this.availableInterests = const [],
    this.availableEducationLevels = const [],
  });

  FilterLoaded copyWith({
    FilterPreferences? preferences,
    List<String>? availableInterests,
    List<String>? availableEducationLevels,
  }) {
    return FilterLoaded(
      preferences: preferences ?? this.preferences,
      availableInterests: availableInterests ?? this.availableInterests,
      availableEducationLevels: availableEducationLevels ?? this.availableEducationLevels,
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
