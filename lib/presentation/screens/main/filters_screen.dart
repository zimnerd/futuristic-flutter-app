import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';

import '../../blocs/filters/filter_bloc.dart';
import '../heat_map_screen.dart';
import '../../blocs/filters/filter_event.dart';
import '../../blocs/filters/filter_state.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
import '../../../domain/entities/filter_preferences.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Screen for managing dating filter preferences
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FilterBLoC>().add(LoadFilterPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Preferences', style: PulseTextStyles.titleLarge),
        backgroundColor: PulseColors.primary,
        foregroundColor: context.onSurfaceColor,
        actions: [
          TextButton(
            onPressed: () {
              context.read<FilterBLoC>().add(ResetFilterPreferences());
            },
            child: Text(
              'Reset',
              style: PulseTextStyles.bodyLarge.copyWith(
                color: context.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<FilterBLoC, FilterState>(
        listener: (context, state) {
          if (state is FilterError) {
            PulseToast.error(context, message: state.message);
          } else if (state is FilterSaved) {
            PulseToast.success(context, message: 'Filter preferences saved!');

            // ✅ Apply saved filters to discovery automatically
            _applyFiltersToDiscovery(state.preferences);
          }
        },
        builder: (context, state) {
          if (state is FilterLoading) {
            return Center(
              child: CircularProgressIndicator(color: PulseColors.primary),
            );
          }

          if (state is FilterLoaded) {
            return _buildFilterContent(context, state);
          }

          if (state is FilterSaving) {
            return _buildSavingOverlay(context, state);
          }

          return _buildErrorState(context);
        },
      ),
    );
  }

  Widget _buildFilterContent(BuildContext context, FilterLoaded state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAgeRangeSection(context, state),
                const SizedBox(height: 32),
                _buildDistanceSection(context, state),
                const SizedBox(height: 32),
                _buildInterestsSection(context, state),
                const SizedBox(height: 32),
                _buildEducationSection(context, state),
                const SizedBox(height: 32),
                _buildOccupationSection(context, state),
                const SizedBox(height: 32),
                _buildRelationshipTypeSection(context, state),
                const SizedBox(height: 32),
                _buildLifestyleSection(context, state),
                const SizedBox(height: 32),
                _buildPreferencesSection(context, state),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        _buildSaveButton(context, state),
      ],
    );
  }

  Widget _buildAgeRangeSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Age Range', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        Text(
          '${state.preferences.minAge} - ${state.preferences.maxAge} years',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: PulseColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: PulseColors.primary,
            inactiveTrackColor: PulseColors.primary.withValues(alpha: 0.3),
            thumbColor: PulseColors.primary,
          ),
          child: RangeSlider(
            values: RangeValues(
              state.preferences.minAge.toDouble(),
              state.preferences.maxAge.toDouble(),
            ),
            min: 18,
            max: 99,
            divisions: 81,
            onChanged: (RangeValues values) {
              context.read<FilterBLoC>().add(
                UpdateAgeRange(values.start.round(), values.end.round()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Maximum Distance', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        Text(
          '${state.preferences.maxDistance.round()} km',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: PulseColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: PulseColors.primary,
            inactiveTrackColor: PulseColors.primary.withValues(alpha: 0.3),
            thumbColor: PulseColors.primary,
          ),
          child: Slider(
            value: state.preferences.maxDistance,
            min: 1,
            max: 500,
            divisions: 99,
            onChanged: (double value) {
              context.read<FilterBLoC>().add(UpdateMaxDistance(value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interests', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        if (state.availableInterests.isEmpty)
          Text(
            'Loading interests...',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.availableInterests.map((interest) {
              final isSelected = state.preferences.interests.contains(interest);
              return FilterChip(
                label: Text(
                  interest,
                  style: TextStyle(
                    color: isSelected ? Colors.white : PulseColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: PulseColors.primary,
                backgroundColor: context.outlineColor.withValues(alpha: 0.1),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? PulseColors.primary
                      : context.outlineColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                showCheckmark: true,
                onSelected: (bool selected) {
                  final updatedInterests = List<String>.from(
                    state.preferences.interests,
                  );
                  if (selected) {
                    updatedInterests.add(interest);
                  } else {
                    updatedInterests.remove(interest);
                  }
                  context.read<FilterBLoC>().add(
                    UpdateInterests(updatedInterests),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEducationSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Education Level', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: state.preferences.education,
          decoration: InputDecoration(
            hintText: 'Any education level',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Any education level'),
            ),
            ...state.availableEducationLevels.map((level) {
              return DropdownMenuItem<String>(value: level, child: Text(level));
            }),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdateEducation(value));
          },
        ),
      ],
    );
  }

  Widget _buildOccupationSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Occupation', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: state.preferences.occupation,
          decoration: InputDecoration(
            hintText: 'Any occupation',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Any occupation'),
            ),
            ...state.availableOccupations.map((occupation) {
              return DropdownMenuItem<String>(
                value: occupation,
                child: Text(occupation),
              );
            }),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdateOccupation(value));
          },
        ),
      ],
    );
  }

  Widget _buildRelationshipTypeSection(
    BuildContext context,
    FilterLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Relationship Goals', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: state.preferences.relationshipType,
          decoration: InputDecoration(
            hintText: 'Any relationship type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Any relationship type'),
            ),
            ...state.availableRelationshipTypes.map((type) {
              return DropdownMenuItem<String>(value: type, child: Text(type));
            }),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdateRelationshipType(value));
          },
        ),
      ],
    );
  }

  Widget _buildLifestyleSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lifestyle Preferences', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),

        // Drinking Habits
        DropdownButtonFormField<String>(
          initialValue: state.preferences.drinkingHabits,
          decoration: InputDecoration(
            labelText: 'Drinking Habits',
            hintText: 'Any',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Any')),
            ...state.availableDrinkingOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdateDrinkingHabits(value));
          },
        ),
        const SizedBox(height: 16),

        // Smoking Habits
        DropdownButtonFormField<String>(
          initialValue: state.preferences.smokingHabits,
          decoration: InputDecoration(
            labelText: 'Smoking Habits',
            hintText: 'Any',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Any')),
            ...state.availableSmokingOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdateSmokingHabits(value));
          },
        ),
        const SizedBox(height: 16),

        // Exercise Frequency
        DropdownButtonFormField<String>(
          initialValue: state.preferences.exercise,
          decoration: InputDecoration(
            labelText: 'Exercise Frequency',
            hintText: 'Any',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Any')),
            ...state.availableExerciseOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdateExercise(value));
          },
        ),
        const SizedBox(height: 16),

        // Pet Preferences
        DropdownButtonFormField<String>(
          initialValue: state.preferences.petPreference,
          decoration: InputDecoration(
            labelText: 'Pet Preferences',
            hintText: 'Any',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
          ),
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Any')),
            DropdownMenuItem<String>(
              value: 'LOVE_PETS',
              child: Text('Love Pets'),
            ),
            DropdownMenuItem<String>(
              value: 'LIKE_PETS',
              child: Text('Like Pets'),
            ),
            DropdownMenuItem<String>(
              value: 'HAVE_PETS',
              child: Text('Have Pets'),
            ),
            DropdownMenuItem<String>(
              value: 'ALLERGIC',
              child: Text('Allergic to Pets'),
            ),
            DropdownMenuItem<String>(
              value: 'NOT_A_PET_PERSON',
              child: Text('Not a Pet Person'),
            ),
          ],
          onChanged: (String? value) {
            context.read<FilterBLoC>().add(UpdatePetPreference(value));
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, FilterLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Preferences', style: PulseTextStyles.titleMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(
            'Only verified profiles',
            style: PulseTextStyles.bodyLarge,
          ),
          subtitle: Text(
            'Show only users with verified accounts',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          value: state.preferences.showOnlyVerified,
          activeThumbColor: PulseColors.primary,
          onChanged: (bool value) {
            context.read<FilterBLoC>().add(UpdateVerificationPreference(value));
          },
        ),
        SwitchListTile(
          title: Text(
            'Only profiles with photos',
            style: PulseTextStyles.bodyLarge,
          ),
          subtitle: Text(
            'Show only users who have uploaded photos',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          value: state.preferences.showOnlyWithPhotos,
          activeThumbColor: PulseColors.primary,
          onChanged: (bool value) {
            context.read<FilterBLoC>().add(UpdatePhotosPreference(value));
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, FilterLoaded state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // View Map Button
            SizedBox(
              width: double.infinity,
              child: PulseButton(
                text: 'View Map',
                onPressed: () {
                  showHeatMapModal(context);
                },
                variant: PulseButtonVariant.secondary,
                icon: Icon(Icons.map, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            // Save Preferences Button
            SizedBox(
              width: double.infinity,
              child: PulseButton(
                text: 'Save Preferences',
                onPressed: () {
                  context.read<FilterBLoC>().add(SaveFilterPreferences());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOverlay(BuildContext context, FilterSaving state) {
    return Stack(
      children: [
        _buildFilterContent(
          context,
          FilterLoaded(preferences: state.preferences),
        ),
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(PulseSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: PulseColors.primary),
                    SizedBox(height: PulseSpacing.md),
                    Text('Saving preferences...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: PulseColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load filter preferences',
            style: PulseTextStyles.titleMedium,
          ),
          const SizedBox(height: 24),
          PulseButton(
            text: 'Retry',
            onPressed: () {
              context.read<FilterBLoC>().add(LoadFilterPreferences());
            },
          ),
        ],
      ),
    );
  }

  /// Apply filter preferences to discovery
  void _applyFiltersToDiscovery(FilterPreferences preferences) {
    try {
      // Convert FilterPreferences to DiscoveryFilters format
      final filters = DiscoveryFilters(
        minAge: preferences.minAge,
        maxAge: preferences.maxAge,
        maxDistance: preferences.maxDistance,
        interests: preferences.interests,
        verifiedOnly: preferences.showOnlyVerified,
        premiumOnly: false, // Not in FilterPreferences, keep default
        recentlyActive: false, // Not in FilterPreferences, keep default
      );

      // Apply filters to discovery bloc
      context.read<DiscoveryBloc>().add(ApplyFilters(filters));
    } catch (e) {
      // Handle error silently or show debug info
      AppLogger.debug('Error applying filters to discovery: $e');
    }
  }
}
