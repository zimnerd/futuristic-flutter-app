import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../theme/pulse_colors.dart';
import '../../../domain/entities/filter_preferences.dart';
import '../../blocs/filters/filter_bloc.dart';
import '../../blocs/filters/filter_event.dart';

/// Reusable filter preview widget showing current filter summary
/// Used in discovery screen and other places that need quick filter overview
class FilterPreviewWidget extends StatelessWidget {
  final FilterPreferences preferences;
  final VoidCallback? onAdvancedTap;

  const FilterPreviewWidget({
    super.key,
    required this.preferences,
    this.onAdvancedTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter sections grid - 2 columns
          _buildFilterGrid(context),
          const SizedBox(height: 24),
          // Action buttons
          _buildActionButtons(context),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildFilterGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildFilterChip(
          context,
          icon: Icons.cake_outlined,
          label: 'Age',
          value: '${preferences.minAge} - ${preferences.maxAge}',
          onTap: () => _showAgeEditor(context),
        ),
        _buildFilterChip(
          context,
          icon: Icons.location_on_outlined,
          label: 'Distance',
          value: '${preferences.maxDistance.toInt()} km',
          onTap: () => _showDistanceEditor(context),
        ),
        _buildFilterChip(
          context,
          icon: Icons.school_outlined,
          label: 'Education',
          value: preferences.education ?? 'Any',
          onTap: () => _showEducationEditor(context),
        ),
        _buildFilterChip(
          context,
          icon: Icons.favorite_outline,
          label: 'Looking for',
          value: preferences.relationshipType ?? 'Any',
          onTap: () => _showRelationshipEditor(context),
        ),
        _buildFilterChip(
          context,
          icon: Icons.star_outline,
          label: 'Verified',
          value: preferences.showOnlyVerified ? 'Yes' : 'No',
          onTap: () => _toggleVerified(context),
        ),
        _buildFilterChip(
          context,
          icon: Icons.image_outlined,
          label: 'Photos',
          value: preferences.showOnlyWithPhotos ? 'Yes' : 'No',
          onTap: () => _togglePhotos(context),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.borderColor.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: PulseColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showResetConfirm(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textPrimary,
              side: BorderSide(color: context.borderColor.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onAdvancedTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: context.surfaceColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Advanced',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.surfaceColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAgeEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AgeEditorSheet(preferences: preferences),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showDistanceEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _DistanceEditorSheet(preferences: preferences),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showEducationEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _EducationEditorSheet(preferences: preferences),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showRelationshipEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _RelationshipEditorSheet(preferences: preferences),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _toggleVerified(BuildContext context) {
    context.read<FilterBLoC>().add(
          UpdateVerificationPreference(!preferences.showOnlyVerified),
        );
  }

  void _togglePhotos(BuildContext context) {
    context.read<FilterBLoC>().add(
          UpdatePhotosPreference(!preferences.showOnlyWithPhotos),
        );
  }

  void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(
          'Reset Filters?',
          style: TextStyle(color: context.textPrimary),
        ),
        content: Text(
          'Restore all filters to default values',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<FilterBLoC>().add(ResetFilterPreferences());
              Navigator.pop(context);
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Age range quick editor
class _AgeEditorSheet extends StatefulWidget {
  final FilterPreferences preferences;

  const _AgeEditorSheet({required this.preferences});

  @override
  State<_AgeEditorSheet> createState() => _AgeEditorSheetState();
}

class _AgeEditorSheetState extends State<_AgeEditorSheet> {
  late RangeValues _ageRange;

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.preferences.minAge.toDouble(),
      widget.preferences.maxAge.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Age Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} years',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 99,
                  divisions: 81,
                  onChanged: (RangeValues values) {
                    setState(() => _ageRange = values);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FilterBLoC>().add(
                            UpdateAgeRange(
                              _ageRange.start.toInt(),
                              _ageRange.end.toInt(),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Distance quick editor
class _DistanceEditorSheet extends StatefulWidget {
  final FilterPreferences preferences;

  const _DistanceEditorSheet({required this.preferences});

  @override
  State<_DistanceEditorSheet> createState() => _DistanceEditorSheetState();
}

class _DistanceEditorSheetState extends State<_DistanceEditorSheet> {
  late double _distance;

  @override
  void initState() {
    super.initState();
    _distance = widget.preferences.maxDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maximum Distance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '${_distance.toInt()} km',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _distance,
                  min: 1,
                  max: 200,
                  divisions: 199,
                  onChanged: (value) {
                    setState(() => _distance = value);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FilterBLoC>().add(
                            UpdateMaxDistance(_distance),
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Education quick editor
class _EducationEditorSheet extends StatefulWidget {
  final FilterPreferences preferences;

  const _EducationEditorSheet({required this.preferences});

  @override
  State<_EducationEditorSheet> createState() => _EducationEditorSheetState();
}

class _EducationEditorSheetState extends State<_EducationEditorSheet> {
  late String? _education;
  late List<String> _educationOptions;

  @override
  void initState() {
    super.initState();
    _education = widget.preferences.education;
    _educationOptions = [
      'Any',
      'High School',
      'Bachelor',
      'Master',
      'PhD',
      'Vocational',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._educationOptions.map(
                  (option) => GestureDetector(
                    onTap: () {
                      setState(() => _education = option == 'Any' ? null : option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: context.borderColor.shade200,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.textPrimary,
                            ),
                          ),
                          if ((_education == null && option == 'Any') ||
                              (_education == option))
                            Icon(
                              Icons.check_circle,
                              color: PulseColors.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FilterBLoC>().add(
                            UpdateEducation(_education),
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Relationship type quick editor
class _RelationshipEditorSheet extends StatefulWidget {
  final FilterPreferences preferences;

  const _RelationshipEditorSheet({required this.preferences});

  @override
  State<_RelationshipEditorSheet> createState() =>
      _RelationshipEditorSheetState();
}

class _RelationshipEditorSheetState extends State<_RelationshipEditorSheet> {
  late String? _relationshipType;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _relationshipType = widget.preferences.relationshipType;
    _options = [
      'Any',
      'Casual dating',
      'Long-term relationship',
      'Friendship',
      'Not sure yet',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Looking For',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._options.map(
                  (option) => GestureDetector(
                    onTap: () {
                      setState(
                        () => _relationshipType =
                            option == 'Any' ? null : option,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: context.borderColor.shade200,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.textPrimary,
                            ),
                          ),
                          if ((_relationshipType == null && option == 'Any') ||
                              (_relationshipType == option))
                            Icon(
                              Icons.check_circle,
                              color: PulseColors.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FilterBLoC>().add(
                            UpdateRelationshipType(_relationshipType),
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
