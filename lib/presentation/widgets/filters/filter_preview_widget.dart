import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../domain/entities/filter_preferences.dart';
import '../../blocs/filters/filter_bloc.dart';
import '../../blocs/filters/filter_event.dart';
import '../common/pulse_button.dart';

/// Compact filter modal - single column, minimal space, maximum efficiency
/// Like Bumble but even better - instant inline editing without modals
class FilterPreviewWidget extends StatefulWidget {
  final FilterPreferences preferences;
  final VoidCallback? onAdvancedTap;

  const FilterPreviewWidget({
    super.key,
    required this.preferences,
    this.onAdvancedTap,
  });

  @override
  State<FilterPreviewWidget> createState() => _FilterPreviewWidgetState();
}

class _FilterPreviewWidgetState extends State<FilterPreviewWidget> {
  late int _minAge;
  late int _maxAge;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _minAge = widget.preferences.minAge;
    _maxAge = widget.preferences.maxAge;
    _distance = widget.preferences.maxDistance;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: context.surfaceColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Single column filter list - compact!
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Age - single range slider
                  _buildFilterRow(
                    context,
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: '$_minAge - $_maxAge',
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values: RangeValues(
                                _minAge.toDouble(),
                                _maxAge.toDouble(),
                              ),
                              min: 18,
                              max: 99,
                              divisions: 81,
                              labels: RangeLabels('$_minAge', '$_maxAge'),
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _minAge = values.start.toInt();
                                  _maxAge = values.end.toInt();
                                });
                                context.read<FilterBLoC>().add(
                                  UpdateAgeRange(
                                    values.start.toInt(),
                                    values.end.toInt(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Distance
                  _buildFilterRow(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'Distance',
                    value: '${_distance.toInt()} km',
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _distance,
                              min: 1,
                              max: 500,
                              divisions: 99,
                              onChanged: (val) {
                                setState(() => _distance = val);
                                context.read<FilterBLoC>().add(
                                  UpdateMaxDistance(val),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${_distance.toInt()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Education
                  _buildCompactFilterRow(
                    context,
                    icon: Icons.school_outlined,
                    label: 'Education',
                    options: [
                      'Any',
                      'High School',
                      'Bachelor',
                      'Master',
                      'PhD',
                    ],
                    selected: widget.preferences.education ?? 'Any',
                    onSelect: (edu) {
                      context.read<FilterBLoC>().add(
                        UpdateEducation(edu == 'Any' ? null : edu),
                      );
                    },
                  ),

                  // Looking for
                  _buildCompactFilterRow(
                    context,
                    icon: Icons.favorite_outline,
                    label: 'Looking for',
                    options: ['Any', 'Dating', 'Relationship', 'Casual'],
                    selected: widget.preferences.relationshipType ?? 'Any',
                    onSelect: (type) {
                      context.read<FilterBLoC>().add(
                        UpdateRelationshipType(type == 'Any' ? null : type),
                      );
                    },
                  ),

                  // Toggles - inline
                  _buildToggleRow(
                    context,
                    icon: Icons.star_outline,
                    label: 'Verified Only',
                    value: widget.preferences.showOnlyVerified,
                    onToggle: () {
                      context.read<FilterBLoC>().add(
                        UpdateVerificationPreference(
                          !widget.preferences.showOnlyVerified,
                        ),
                      );
                    },
                  ),
                  _buildToggleRow(
                    context,
                    icon: Icons.image_outlined,
                    label: 'Has Photos',
                    value: widget.preferences.showOnlyWithPhotos,
                    onToggle: () {
                      context.read<FilterBLoC>().add(
                        UpdatePhotosPreference(
                          !widget.preferences.showOnlyWithPhotos,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
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
                    child: PulseButton(
                      text: 'Advanced',
                      onPressed: widget.onAdvancedTap,
                      variant: PulseButtonVariant.primary,
                      size: PulseButtonSize.medium,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context, {
    IconData? icon,
    required String label,
    required String value,
    required Widget child,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: context.primaryColor),
                const SizedBox(width: 10),
              ] else ...[
                const SizedBox(width: 28),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
        ),
        child,
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCompactFilterRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.primaryColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.primaryColor
                        : context.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? context.primaryColor
                          : context.borderColor.shade300,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? context.surfaceColor
                          : context.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? context.primaryColor : context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value
                      ? context.primaryColor
                      : context.borderColor.shade300,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  value ? 'Yes' : 'No',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: value ? context.surfaceColor : context.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
            child: Text(
              'Reset',
              style: TextStyle(color: context.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
