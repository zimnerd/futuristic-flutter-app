import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Enhanced filter options for message conversations
class MessageFilters {
  final MessageFilterType type;
  final MessageStatusFilter status;
  final MessageTimeFilter timeFilter;
  final bool showOnlineOnly;
  final bool showUnreadOnly;
  final MessageSortOption sortBy;

  const MessageFilters({
    this.type = MessageFilterType.all,
    this.status = MessageStatusFilter.all,
    this.timeFilter = MessageTimeFilter.all,
    this.showOnlineOnly = false,
    this.showUnreadOnly = false,
    this.sortBy = MessageSortOption.recent,
  });

  MessageFilters copyWith({
    MessageFilterType? type,
    MessageStatusFilter? status,
    MessageTimeFilter? timeFilter,
    bool? showOnlineOnly,
    bool? showUnreadOnly,
    MessageSortOption? sortBy,
  }) {
    return MessageFilters(
      type: type ?? this.type,
      status: status ?? this.status,
      timeFilter: timeFilter ?? this.timeFilter,
      showOnlineOnly: showOnlineOnly ?? this.showOnlineOnly,
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum MessageFilterType {
  all,
  matches,
  connections,
  archived,
}

enum MessageStatusFilter {
  all,
  online,
  offline,
  recently_active,
}

enum MessageTimeFilter {
  all,
  today,
  yesterday,
  this_week,
  this_month,
}

enum MessageSortOption {
  recent,
  alphabetical,
  unread_first,
  online_first,
}

/// Filter bottom sheet widget for message conversations
class MessageFilterBottomSheet extends StatefulWidget {
  final MessageFilters currentFilters;
  final Function(MessageFilters) onFiltersChanged;

  const MessageFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<MessageFilterBottomSheet> createState() => _MessageFilterBottomSheetState();
}

class _MessageFilterBottomSheetState extends State<MessageFilterBottomSheet> {
  late MessageFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PulseRadii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: PulseSpacing.md),
            decoration: BoxDecoration(
              color: PulseColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(PulseSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Filter Messages',
                  style: PulseTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = const MessageFilters();
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),

          // Filter options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    'Conversation Type',
                    _buildTypeFilters(),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  _buildFilterSection(
                    'Status',
                    _buildStatusFilters(),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  _buildFilterSection(
                    'Time',
                    _buildTimeFilters(),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  _buildFilterSection(
                    'Quick Filters',
                    _buildQuickFilters(),
                  ),
                  const SizedBox(height: PulseSpacing.lg),
                  _buildFilterSection(
                    'Sort By',
                    _buildSortOptions(),
                  ),
                  const SizedBox(height: PulseSpacing.xl),
                ],
              ),
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(PulseSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(_filters);
                  Navigator.of(context).pop();
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PulseTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.sm),
        content,
      ],
    );
  }

  Widget _buildTypeFilters() {
    return Wrap(
      spacing: PulseSpacing.sm,
      children: MessageFilterType.values.map((type) {
        final isSelected = _filters.type == type;
        return FilterChip(
          label: Text(_getTypeLabel(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(type: selected ? type : MessageFilterType.all);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStatusFilters() {
    return Wrap(
      spacing: PulseSpacing.sm,
      children: MessageStatusFilter.values.map((status) {
        final isSelected = _filters.status == status;
        return FilterChip(
          label: Text(_getStatusLabel(status)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(status: selected ? status : MessageStatusFilter.all);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimeFilters() {
    return Wrap(
      spacing: PulseSpacing.sm,
      children: MessageTimeFilter.values.map((time) {
        final isSelected = _filters.timeFilter == time;
        return FilterChip(
          label: Text(_getTimeLabel(time)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(timeFilter: selected ? time : MessageTimeFilter.all);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Show online only'),
          subtitle: const Text('Only show users who are currently online'),
          value: _filters.showOnlineOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(showOnlineOnly: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Show unread only'),
          subtitle: const Text('Only show conversations with unread messages'),
          value: _filters.showUnreadOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(showUnreadOnly: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: MessageSortOption.values.map((option) {
        return RadioListTile<MessageSortOption>(
          title: Text(_getSortLabel(option)),
          value: option,
          groupValue: _filters.sortBy,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(sortBy: value);
            });
          },
        );
      }).toList(),
    );
  }

  String _getTypeLabel(MessageFilterType type) {
    switch (type) {
      case MessageFilterType.all:
        return 'All';
      case MessageFilterType.matches:
        return 'Matches';
      case MessageFilterType.connections:
        return 'Connections';
      case MessageFilterType.archived:
        return 'Archived';
    }
  }

  String _getStatusLabel(MessageStatusFilter status) {
    switch (status) {
      case MessageStatusFilter.all:
        return 'All';
      case MessageStatusFilter.online:
        return 'Online';
      case MessageStatusFilter.offline:
        return 'Offline';
      case MessageStatusFilter.recently_active:
        return 'Recently Active';
    }
  }

  String _getTimeLabel(MessageTimeFilter time) {
    switch (time) {
      case MessageTimeFilter.all:
        return 'All Time';
      case MessageTimeFilter.today:
        return 'Today';
      case MessageTimeFilter.yesterday:
        return 'Yesterday';
      case MessageTimeFilter.this_week:
        return 'This Week';
      case MessageTimeFilter.this_month:
        return 'This Month';
    }
  }

  String _getSortLabel(MessageSortOption option) {
    switch (option) {
      case MessageSortOption.recent:
        return 'Most Recent';
      case MessageSortOption.alphabetical:
        return 'Alphabetical';
      case MessageSortOption.unread_first:
        return 'Unread First';
      case MessageSortOption.online_first:
        return 'Online First';
    }
  }
}