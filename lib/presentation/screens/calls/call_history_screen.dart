import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/call_history_repository.dart';
import '../../blocs/call_history/call_history_barrel.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/pulse_toast.dart';
import 'call_details_screen.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Screen for displaying call history with filters and pagination
class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  CallHistoryFilters? _currentFilters;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial call history
    context.read<CallHistoryBloc>().add(const LoadCallHistory());
    // Load call statistics
    context.read<CallHistoryBloc>().add(const LoadCallStatistics());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CallHistoryBloc>().add(const LoadMoreCallHistory());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _FilterDialog(
        currentFilters: _currentFilters,
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          context.read<CallHistoryBloc>().add(
            ApplyCallHistoryFilters(filters: filters),
          );
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    context.read<CallHistoryBloc>().add(
      RefreshCallHistory(filters: _currentFilters),
    );
    // Wait for refresh to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _viewCallDetails(String callId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CallHistoryBloc>(),
          child: CallDetailsScreen(callId: callId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call History'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter calls',
          ),
        ],
      ),
      body: BlocConsumer<CallHistoryBloc, CallHistoryState>(
        listener: (context, state) {
          if (state is CallHistoryError) {
            PulseToast.error(context, message: state.message);
          } else if (state is CallHistoryDeleted) {
            PulseToast.success(context, message: 'Call deleted successfully');
          }
        },
        builder: (context, state) {
          if (state is CallHistoryLoading) {
            return Center(child: LoadingIndicator());
          }

          if (state is CallHistoryLoaded) {
            return _buildLoadedContent(state);
          }

          if (state is CallHistoryRefreshing) {
            return _buildLoadedContent(
              CallHistoryLoaded(
                calls: state.existingCalls,
                pagination: PaginationMetadata(
                  page: 1,
                  limit: 20,
                  total: state.existingCalls.length,
                  totalPages: 1,
                  hasNext: false,
                  hasPrev: false,
                ),
                appliedFilters: state.appliedFilters,
              ),
            );
          }

          if (state is CallHistoryDeleting) {
            return _buildLoadedContent(
              CallHistoryLoaded(
                calls: state.calls,
                pagination: state.pagination,
              ),
            );
          }

          // Initial state
          return Center(child: Text('Pull down to refresh call history'));
        },
      ),
    );
  }

  Widget _buildLoadedContent(CallHistoryLoaded state) {
    if (state.calls.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call_end,
                      size: 64,
                      color: context.outlineColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentFilters != null
                          ? 'No calls found with current filters'
                          : 'No call history yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.onSurfaceVariantColor,
                      ),
                    ),
                    if (_currentFilters != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentFilters = null;
                          });
                          context.read<CallHistoryBloc>().add(
                            const ApplyCallHistoryFilters(),
                          );
                        },
                        child: Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics header
        if (state.statistics != null) _buildStatisticsHeader(state.statistics!),
        // Active filters chip
        if (state.appliedFilters != null) _buildActiveFiltersChip(),
        // Call list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.calls.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.calls.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: LoadingIndicator()),
                  );
                }

                final call = state.calls[index];
                return _buildCallItem(call);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsHeader(CallStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: context.outlineColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Total',
            value: stats.totalCalls.toString(),
            icon: Icons.call,
          ),
          _buildStatItem(
            label: 'Completed',
            value: stats.completedCalls.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatItem(
            label: 'Missed',
            value: stats.missedCalls.toString(),
            icon: Icons.call_missed,
            color: Colors.orange,
          ),
          _buildStatItem(
            label: 'Avg Duration',
            value: _formatDuration(stats.avgDuration),
            icon: Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.onSurfaceVariantColor),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'Filters active',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _currentFilters = null;
              });
              context.read<CallHistoryBloc>().add(
                const ApplyCallHistoryFilters(),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallItem(CallHistoryItem call) {
    final otherParticipant = call.participants.firstWhere(
      (p) => p.role != 'caller',
      orElse: () => call.participants.first,
    );

    final callTypeIcon = call.type == 'VIDEO' ? Icons.videocam : Icons.phone;
    final statusIcon = _getStatusIcon(call.status);
    final statusColor = _getStatusColor(call.status);

    return Dismissible(
      key: Key(call.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: context.errorColor,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Delete Call'),
            content: Text(
              'Are you sure you want to delete this call from your history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(
                  foregroundColor: context.errorColor,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<CallHistoryBloc>().add(DeleteCallRecord(call.id));
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: otherParticipant.user.profileImage != null
              ? NetworkImage(otherParticipant.user.profileImage!)
              : null,
          child: otherParticipant.user.profileImage == null
              ? Text(otherParticipant.user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(
          otherParticipant.user.displayName,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Text(
              _formatCallInfo(call),
              style: TextStyle(
                fontSize: 12,
                color: context.onSurfaceVariantColor,
              ),
            ),
            if (call.averageQuality != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.signal_cellular_alt,
                size: 16,
                color: _getQualityColor(call.averageQuality!.toDouble()),
              ),
            ],
          ],
        ),
        trailing: Icon(callTypeIcon, color: Theme.of(context).primaryColor),
        onTap: () => _viewCallDetails(call.id),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'ANSWERED':
      case 'ENDED':
        return Icons.call_made;
      case 'MISSED':
        return Icons.call_missed;
      case 'REJECTED':
        return Icons.call_missed_outgoing;
      case 'FAILED':
        return Icons.error_outline;
      default:
        return Icons.call;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ANSWERED':
      case 'ENDED':
        return Colors.green;
      case 'MISSED':
        return Colors.orange;
      case 'REJECTED':
      case 'FAILED':
        return Colors.red;
      default:
        return context.outlineColor;
    }
  }

  Color _getQualityColor(double quality) {
    if (quality >= 80) return Colors.green;
    if (quality >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatCallInfo(CallHistoryItem call) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final startedAt = call.startedAt ?? DateTime.now();
    final duration = call.duration != null
        ? ' • ${_formatDuration(call.duration!)}'
        : '';
    return '${dateFormat.format(startedAt)}$duration';
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

/// Dialog for filtering call history
class _FilterDialog extends StatefulWidget {
  final CallHistoryFilters? currentFilters;
  final Function(CallHistoryFilters?) onApplyFilters;

  const _FilterDialog({
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedType;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentFilters?.type;
    _selectedStatus = widget.currentFilters?.status;
    _startDate = widget.currentFilters?.startDate;
    _endDate = widget.currentFilters?.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter Calls'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('All'),
                  selected: _selectedType == null,
                  onSelected: (selected) =>
                      setState(() => _selectedType = null),
                ),
                ChoiceChip(
                  label: Text('Video'),
                  selected: _selectedType == 'VIDEO',
                  onSelected: (selected) =>
                      setState(() => _selectedType = selected ? 'VIDEO' : null),
                ),
                ChoiceChip(
                  label: Text('Audio'),
                  selected: _selectedType == 'AUDIO',
                  onSelected: (selected) =>
                      setState(() => _selectedType = selected ? 'AUDIO' : null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('All'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) =>
                      setState(() => _selectedStatus = null),
                ),
                ChoiceChip(
                  label: Text('Completed'),
                  selected: _selectedStatus == 'ANSWERED',
                  onSelected: (selected) => setState(
                    () => _selectedStatus = selected ? 'ANSWERED' : null,
                  ),
                ),
                ChoiceChip(
                  label: Text('Missed'),
                  selected: _selectedStatus == 'MISSED',
                  onSelected: (selected) => setState(
                    () => _selectedStatus = selected ? 'MISSED' : null,
                  ),
                ),
                ChoiceChip(
                  label: Text('Rejected'),
                  selected: _selectedStatus == 'REJECTED',
                  onSelected: (selected) => setState(
                    () => _selectedStatus = selected ? 'REJECTED' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDate != null
                          ? DateFormat('MMM d, y').format(_startDate!)
                          : 'Start Date',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _endDate != null
                          ? DateFormat('MMM d, y').format(_endDate!)
                          : 'End Date',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedType = null;
              _selectedStatus = null;
              _startDate = null;
              _endDate = null;
            });
          },
          child: Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final filters =
                (_selectedType != null ||
                    _selectedStatus != null ||
                    _startDate != null ||
                    _endDate != null)
                ? CallHistoryFilters(
                    type: _selectedType,
                    status: _selectedStatus,
                    startDate: _startDate,
                    endDate: _endDate,
                  )
                : null;
            widget.onApplyFilters(filters);
            Navigator.pop(context);
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}
