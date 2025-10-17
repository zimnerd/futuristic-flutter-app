import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/services/preferences_service.dart';
import 'filter_event.dart';
import 'filter_state.dart';

/// BLoC for managing filter preferences
class FilterBLoC extends Bloc<FilterEvent, FilterState> {
  final PreferencesService _preferencesService;
  final Logger _logger = Logger();

  FilterBLoC(this._preferencesService) : super(FilterInitial()) {
    on<LoadFilterPreferences>(_onLoadFilterPreferences);
    on<UpdateFilterPreferences>(_onUpdateFilterPreferences);
    on<UpdateAgeRange>(_onUpdateAgeRange);
    on<UpdateMaxDistance>(_onUpdateMaxDistance);
    on<UpdateInterests>(_onUpdateInterests);
    on<UpdateEducation>(_onUpdateEducation);
    on<UpdateOccupation>(_onUpdateOccupation);
    on<UpdateRelationshipType>(_onUpdateRelationshipType);
    on<UpdateDrinkingHabits>(_onUpdateDrinkingHabits);
    on<UpdateSmokingHabits>(_onUpdateSmokingHabits);
    on<UpdateExercise>(_onUpdateExercise);
    on<UpdateVerificationPreference>(_onUpdateVerificationPreference);
    on<UpdatePhotosPreference>(_onUpdatePhotosPreference);
    on<SaveFilterPreferences>(_onSaveFilterPreferences);
    on<ResetFilterPreferences>(_onResetFilterPreferences);
    on<LoadFilterOptions>(_onLoadFilterOptions);
  }

  Future<void> _onLoadFilterPreferences(
    LoadFilterPreferences event,
    Emitter<FilterState> emit,
  ) async {
    try {
      emit(FilterLoading());
      _logger.d('Loading filter preferences');

      final preferences = await _preferencesService.getFilterPreferences();
      final interests = await _preferencesService.getAvailableInterests();
      final educationLevels = await _preferencesService.getEducationLevels();

      emit(FilterLoaded(
        preferences: preferences,
        availableInterests: interests,
        availableEducationLevels: educationLevels,
      ));

      _logger.d('Filter preferences loaded successfully');
    } catch (e) {
      _logger.e('Error loading filter preferences: $e');
      emit(FilterError('Failed to load filter preferences'));
    }
  }

  Future<void> _onUpdateFilterPreferences(
    UpdateFilterPreferences event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      
      if (_preferencesService.validatePreferences(event.preferences)) {
        emit(currentState.copyWith(preferences: event.preferences));
        _logger.d('Filter preferences updated');
      } else {
        emit(FilterError('Invalid filter preferences'));
      }
    }
  }

  Future<void> _onUpdateAgeRange(
    UpdateAgeRange event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        minAge: event.minAge,
        maxAge: event.maxAge,
      );

      if (_preferencesService.validatePreferences(updatedPreferences)) {
        emit(currentState.copyWith(preferences: updatedPreferences));
        _logger.d('Age range updated: ${event.minAge}-${event.maxAge}');
      } else {
        emit(FilterError('Invalid age range'));
      }
    }
  }

  Future<void> _onUpdateMaxDistance(
    UpdateMaxDistance event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        maxDistance: event.distance,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Max distance updated: ${event.distance}km');
    }
  }

  Future<void> _onUpdateInterests(
    UpdateInterests event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        interests: event.interests,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Interests updated: ${event.interests.length} selected');
    }
  }

  Future<void> _onUpdateEducation(
    UpdateEducation event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        education: event.education,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Education preference updated: ${event.education}');
    }
  }

  Future<void> _onUpdateOccupation(
    UpdateOccupation event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        occupation: event.occupation,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Occupation preference updated: ${event.occupation}');
    }
  }

  Future<void> _onUpdateRelationshipType(
    UpdateRelationshipType event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        relationshipType: event.relationshipType,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Relationship type preference updated: ${event.relationshipType}');
    }
  }

  Future<void> _onUpdateDrinkingHabits(
    UpdateDrinkingHabits event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        drinkingHabits: event.drinkingHabits,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Drinking habits preference updated: ${event.drinkingHabits}');
    }
  }

  Future<void> _onUpdateSmokingHabits(
    UpdateSmokingHabits event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        smokingHabits: event.smokingHabits,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Smoking habits preference updated: ${event.smokingHabits}');
    }
  }

  Future<void> _onUpdateExercise(
    UpdateExercise event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        exercise: event.exercise,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Exercise preference updated: ${event.exercise}');
    }
  }

  Future<void> _onUpdateVerificationPreference(
    UpdateVerificationPreference event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        showOnlyVerified: event.showOnlyVerified,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Verification preference updated: ${event.showOnlyVerified}');
    }
  }

  Future<void> _onUpdatePhotosPreference(
    UpdatePhotosPreference event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      final updatedPreferences = currentState.preferences.copyWith(
        showOnlyWithPhotos: event.showOnlyWithPhotos,
      );

      emit(currentState.copyWith(preferences: updatedPreferences));
      _logger.d('Photos preference updated: ${event.showOnlyWithPhotos}');
    }
  }

  Future<void> _onSaveFilterPreferences(
    SaveFilterPreferences event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      
      try {
        emit(FilterSaving(currentState.preferences));
        _logger.d('Saving filter preferences');

        final success = await _preferencesService.saveFilterPreferences(
          currentState.preferences,
        );

        if (success) {
          emit(FilterSaved(currentState.preferences));
          _logger.d('Filter preferences saved successfully');
          
          // Return to loaded state after brief success indication
          await Future.delayed(const Duration(seconds: 1));
          emit(currentState);
        } else {
          emit(FilterError('Failed to save filter preferences'));
        }
      } catch (e) {
        _logger.e('Error saving filter preferences: $e');
        emit(FilterError('Failed to save filter preferences'));
      }
    }
  }

  Future<void> _onResetFilterPreferences(
    ResetFilterPreferences event,
    Emitter<FilterState> emit,
  ) async {
    try {
      emit(FilterLoading());
      _logger.d('Resetting filter preferences');

      final success = await _preferencesService.resetFilters();
      
      if (success) {
        // Reload preferences after reset
        add(LoadFilterPreferences());
      } else {
        emit(FilterError('Failed to reset filter preferences'));
      }
    } catch (e) {
      _logger.e('Error resetting filter preferences: $e');
      emit(FilterError('Failed to reset filter preferences'));
    }
  }

  Future<void> _onLoadFilterOptions(
    LoadFilterOptions event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      final currentState = state as FilterLoaded;
      
      try {
        _logger.d('Loading filter options');

        final interests = await _preferencesService.getAvailableInterests();
        final educationLevels = await _preferencesService.getEducationLevels();

        emit(currentState.copyWith(
          availableInterests: interests,
          availableEducationLevels: educationLevels,
        ));

        _logger.d('Filter options loaded successfully');
      } catch (e) {
        _logger.e('Error loading filter options: $e');
        // Don't emit error, just keep current state
      }
    }
  }
}
