import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/filters/filter_bloc.dart';
import '../../blocs/filters/filter_event.dart';
import '../../blocs/filters/filter_state.dart';
import '../../theme/pulse_colors.dart';
import '../discovery/advanced_filters.dart';

/// Responsive filter header component that adapts to screen size and context
class ResponsiveFilterHeader extends StatefulWidget {
  final VoidCallback? onFiltersChanged;
  final bool showCompactView;
  final bool isInDiscovery;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveFilterHeader({
    super.key,
    this.onFiltersChanged,
    this.showCompactView = false,
    this.isInDiscovery = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ResponsiveFilterHeader> createState() => _ResponsiveFilterHeaderState();
}

class _ResponsiveFilterHeaderState extends State<ResponsiveFilterHeader> {
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBLoC, FilterState>(
      builder: (context, state) {
        if (widget.showCompactView) {
          return _buildCompactFilterButton(context, state);
        }

        return Column(
          children: [
            _buildFilterToggleHeader(context, state),
            if (_isFilterExpanded) _buildExpandedFilters(context, state),
          ],
        );
      },
    );
  }

  Widget _buildCompactFilterButton(BuildContext context, FilterState state) {
    final hasActiveFilters = _hasActiveFilters(state);
    
    return GestureDetector(
      onTap: () => _showFiltersModal(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: hasActiveFilters 
            ? Border.all(color: PulseColors.primary, width: 2)
            : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune,
                color: widget.foregroundColor ?? 
                  (hasActiveFilters ? PulseColors.primary : Colors.grey),
                size: 24,
              ),
            ),
            if (hasActiveFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: PulseColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToggleHeader(BuildContext context, FilterState state) {
    final hasActiveFilters = _hasActiveFilters(state);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Quick filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickFilterChip('Age: 18-35', hasActiveFilters),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('Distance: 50km', hasActiveFilters),
                  const SizedBox(width: 8),
                  _buildQuickFilterChip('Interests', hasActiveFilters),
                ],
              ),
            ),
          ),
          
          // Expand/collapse button
          IconButton(
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            icon: Icon(
              _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
              color: PulseColors.primary,
            ),
          ),
          
          // More filters button
          TextButton.icon(
            onPressed: () => _showFiltersModal(context),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Filters'),
            style: TextButton.styleFrom(
              foregroundColor: hasActiveFilters ? PulseColors.primary : Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, bool isActive) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? PulseColors.primary : Colors.grey[600],
        ),
      ),
      selected: isActive,
      selectedColor: PulseColors.primary.withValues(alpha: 0.1),
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isActive ? PulseColors.primary : Colors.grey[300]!,
        width: 1,
      ),
      onSelected: (selected) {
        // Handle quick filter selection
        _showFiltersModal(context);
      },
    );
  }

  Widget _buildExpandedFilters(BuildContext context, FilterState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age range quick selector
          _buildQuickAgeSelector(),
          const SizedBox(height: 16),
          
          // Distance quick selector
          _buildQuickDistanceSelector(),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<FilterBLoC>().add(ResetFilterPreferences());
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAgeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Range',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildAgeChip('18-25'),
            _buildAgeChip('25-35'),
            _buildAgeChip('35-45'),
            _buildAgeChip('45+'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDistanceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildDistanceChip('10km'),
            _buildDistanceChip('25km'),
            _buildDistanceChip('50km'),
            _buildDistanceChip('100km'),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeChip(String range) {
    return FilterChip(
      label: Text(
        range,
        style: const TextStyle(fontSize: 12),
      ),
      selected: false, // TODO: Connect to actual filter state
      selectedColor: PulseColors.primary.withValues(alpha: 0.2),
      onSelected: (selected) {
        // TODO: Update age filter
      },
    );
  }

  Widget _buildDistanceChip(String distance) {
    return FilterChip(
      label: Text(
        distance,
        style: const TextStyle(fontSize: 12),
      ),
      selected: false, // TODO: Connect to actual filter state
      selectedColor: PulseColors.primary.withValues(alpha: 0.2),
      onSelected: (selected) {
        // TODO: Update distance filter
      },
    );
  }

  bool _hasActiveFilters(FilterState state) {
    if (state is FilterLoaded) {
      final prefs = state.preferences;
      return prefs.minAge != 18 ||
             prefs.maxAge != 99 ||
             prefs.maxDistance != 50.0 ||
             prefs.interests.isNotEmpty ||
             prefs.education?.isNotEmpty == true ||
             prefs.occupation?.isNotEmpty == true ||
             prefs.showOnlyVerified ||
             !prefs.showOnlyWithPhotos ||
             prefs.dealBreakers.isNotEmpty;
    }
    return false;
  }

  void _showFiltersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => AdvancedFilters(
          onApplyFilters: (filters) {
            // Apply filters to discovery
            widget.onFiltersChanged?.call();
          },
        ),
      ),
    );
  }
}