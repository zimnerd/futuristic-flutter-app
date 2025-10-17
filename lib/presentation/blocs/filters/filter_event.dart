import '../../../domain/entities/filter_preferences.dart';

/// Events for FilterBLoC
abstract class FilterEvent {}

/// Load current filter preferences
class LoadFilterPreferences extends FilterEvent {}

/// Update filter preferences
class UpdateFilterPreferences extends FilterEvent {
  final FilterPreferences preferences;

  UpdateFilterPreferences(this.preferences);
}

/// Update age range
class UpdateAgeRange extends FilterEvent {
  final int minAge;
  final int maxAge;

  UpdateAgeRange(this.minAge, this.maxAge);
}

/// Update maximum distance
class UpdateMaxDistance extends FilterEvent {
  final double distance;

  UpdateMaxDistance(this.distance);
}

/// Update interests
class UpdateInterests extends FilterEvent {
  final List<String> interests;

  UpdateInterests(this.interests);
}

/// Update education preference
class UpdateEducation extends FilterEvent {
  final String? education;

  UpdateEducation(this.education);
}

/// Update occupation preference
class UpdateOccupation extends FilterEvent {
  final String? occupation;

  UpdateOccupation(this.occupation);
}

/// Update relationship type preference
class UpdateRelationshipType extends FilterEvent {
  final String? relationshipType;

  UpdateRelationshipType(this.relationshipType);
}

/// Update drinking habits preference
class UpdateDrinkingHabits extends FilterEvent {
  final String? drinkingHabits;

  UpdateDrinkingHabits(this.drinkingHabits);
}

/// Update smoking habits preference
class UpdateSmokingHabits extends FilterEvent {
  final String? smokingHabits;

  UpdateSmokingHabits(this.smokingHabits);
}

/// Update exercise preference
class UpdateExercise extends FilterEvent {
  final String? exercise;

  UpdateExercise(this.exercise);
}

/// Update pet preference
class UpdatePetPreference extends FilterEvent {
  final String? petPreference;

  UpdatePetPreference(this.petPreference);
}

/// Update verification preference
class UpdateVerificationPreference extends FilterEvent {
  final bool showOnlyVerified;

  UpdateVerificationPreference(this.showOnlyVerified);
}

/// Update photos preference
class UpdatePhotosPreference extends FilterEvent {
  final bool showOnlyWithPhotos;

  UpdatePhotosPreference(this.showOnlyWithPhotos);
}

/// Save current preferences
class SaveFilterPreferences extends FilterEvent {}

/// Reset preferences to defaults
class ResetFilterPreferences extends FilterEvent {}

/// Load available options (interests, education levels)
class LoadFilterOptions extends FilterEvent {}
