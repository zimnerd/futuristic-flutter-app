import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/event/event_bloc.dart';
import '../../blocs/event/event_event.dart';
import '../../theme/pulse_colors.dart';

class AdvancedFiltersModal extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? maxDistance;

  const AdvancedFiltersModal({
    super.key,
    this.startDate,
    this.endDate,
    this.maxDistance,
  });

  @override
  State<AdvancedFiltersModal> createState() => _AdvancedFiltersModalState();
}

class _AdvancedFiltersModalState extends State<AdvancedFiltersModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  double _maxDistance = 25.0;
  bool _hasAvailableSpots = false;
  bool _showJoinedOnly = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _maxDistance = widget.maxDistance ?? 25.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildDateFilters(),
          const SizedBox(height: 24),
          _buildDistanceFilter(),
          const SizedBox(height: 24),
          _buildAvailabilityFilter(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Advanced Filters',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: PulseColors.onSurface,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: PulseColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: PulseColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(
                label: 'From',
                date: _startDate,
                onTap: () => _selectDate(isStartDate: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateSelector(
                label: 'To',
                date: _endDate,
                onTap: () => _selectDate(isStartDate: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickDateFilters(),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: PulseColors.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? PulseColors.onSurface
                    : PulseColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilters() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeekend = today.add(Duration(days: 6 - now.weekday));
    final nextWeek = today.add(const Duration(days: 7));

    return Wrap(
      spacing: 8,
      children: [
        _buildQuickDateChip(
          'Today',
          startDate: today,
          endDate: today.add(const Duration(days: 1)),
        ),
        _buildQuickDateChip(
          'Tomorrow',
          startDate: tomorrow,
          endDate: tomorrow.add(const Duration(days: 1)),
        ),
        _buildQuickDateChip(
          'This Weekend',
          startDate: thisWeekend,
          endDate: thisWeekend.add(const Duration(days: 2)),
        ),
        _buildQuickDateChip(
          'Next Week',
          startDate: nextWeek,
          endDate: nextWeek.add(const Duration(days: 7)),
        ),
      ],
    );
  }

  Widget _buildQuickDateChip(
    String label, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final isSelected = _startDate != null &&
        _endDate != null &&
        _startDate!.isAtSameMomentAs(startDate) &&
        _endDate!.isAtSameMomentAs(endDate);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
        });
      },
      selectedColor: PulseColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : PulseColors.primary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? PulseColors.primary
              : PulseColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Max Distance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: PulseColors.onSurface,
              ),
            ),
            Text(
              '${_maxDistance.round()} km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: PulseColors.primary,
            thumbColor: PulseColors.primary,
            overlayColor: PulseColors.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: PulseColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Events with available spots'),
          subtitle: Text(
            'Show only events that are not full',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          value: _hasAvailableSpots,
          onChanged: (value) {
            setState(() {
              _hasAvailableSpots = value ?? false;
            });
          },
          activeColor: PulseColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Events I joined'),
          subtitle: Text(
            'Show only events you are attending',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          value: _showJoinedOnly,
          onChanged: (value) {
            setState(() {
              _showJoinedOnly = value ?? false;
            });
          },
          activeColor: PulseColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: PulseColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                color: PulseColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate
        ? _startDate ?? DateTime.now()
        : _endDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PulseColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: PulseColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  void _clearFilters() {
    context.read<EventBloc>().add(const ClearAdvancedFilters());
    Navigator.of(context).pop();
  }

  void _applyFilters() {
    context.read<EventBloc>().add(
      ApplyAdvancedFilters(
        startDate: _startDate,
        endDate: _endDate,
        maxDistance: _maxDistance,
        hasAvailableSpots: _hasAvailableSpots ? true : null,
        showJoinedOnly: _showJoinedOnly ? true : null,
      ),
    );
    Navigator.of(context).pop();
  }
}