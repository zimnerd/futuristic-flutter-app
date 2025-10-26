import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/call_history_repository.dart';
import '../../blocs/call_history/call_history_barrel.dart';
import '../../widgets/common/loading_indicator.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Screen for displaying detailed call information with quality metrics
class CallDetailsScreen extends StatefulWidget {
  final String callId;

  const CallDetailsScreen({super.key, required this.callId});

  @override
  State<CallDetailsScreen> createState() => _CallDetailsScreenState();
}

class _CallDetailsScreenState extends State<CallDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load call details when screen opens
    context.read<CallHistoryBloc>().add(ViewCallDetails(widget.callId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Call Details')),
      body: BlocBuilder<CallHistoryBloc, CallHistoryState>(
        builder: (context, state) {
          if (state is CallDetailsLoading) {
            return Center(child: LoadingIndicator());
          }

          if (state is CallDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CallHistoryBloc>().add(
                        ViewCallDetails(widget.callId),
                      );
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CallDetailsLoaded) {
            return _buildDetailsContent(state.details);
          }

          return Center(child: Text('Loading call details...'));
        },
      ),
    );
  }

  Widget _buildDetailsContent(CallDetails details) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCallInfoCard(details),
          const SizedBox(height: 16),
          _buildParticipantsCard(details),
          const SizedBox(height: 16),
          if (details.qualityStats != null) ...[
            _buildQualityStatsCard(details.qualityStats!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCallInfoCard(CallDetails details) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final duration = details.duration != null
        ? _formatDuration(details.duration!)
        : 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  details.type == 'VIDEO' ? Icons.videocam : Icons.phone,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${details.type == 'VIDEO' ? 'Video' : 'Audio'} Call',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateFormat.format(details.startedAt ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Status', _formatStatus(details.status)),
            _buildInfoRow('Duration', duration),
            if (details.endedAt != null)
              _buildInfoRow('Ended At', dateFormat.format(details.endedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(CallDetails details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...details.participants.map((participant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: participant.user.profileImage != null
                          ? NetworkImage(participant.user.profileImage!)
                          : null,
                      child: participant.user.profileImage == null
                          ? Text(participant.user.displayName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.user.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${participant.role} • ${_formatStatus(participant.status)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.onSurfaceVariantColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityStatsCard(QualityStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call Quality',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQualityMetric(
                  'Average',
                  stats.average.toStringAsFixed(1),
                  _getQualityColor(stats.average.toDouble()),
                ),
                _buildQualityMetric(
                  'Minimum',
                  stats.min.toStringAsFixed(1),
                  _getQualityColor(stats.min.toDouble()),
                ),
                _buildQualityMetric(
                  'Maximum',
                  stats.max.toStringAsFixed(1),
                  _getQualityColor(stats.max.toDouble()),
                ),
              ],
            ),
            if (stats.snapshots.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Quality tracked over ${stats.snapshots.length} snapshots',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceVariantColor,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildDistributionBars(stats.distribution),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBars(QualityDistribution distribution) {
    final total =
        distribution.excellent +
        distribution.good +
        distribution.fair +
        distribution.poor;

    if (total == 0) {
      return Text('No distribution data available');
    }

    return Column(
      children: [
        if (distribution.excellent > 0)
          _buildDistributionBar(
            'Excellent',
            distribution.excellent,
            total,
            Colors.green,
          ),
        if (distribution.good > 0)
          _buildDistributionBar(
            'Good',
            distribution.good,
            total,
            Colors.lightGreen,
          ),
        if (distribution.fair > 0)
          _buildDistributionBar(
            'Fair',
            distribution.fair,
            total,
            Colors.orange,
          ),
        if (distribution.poor > 0)
          _buildDistributionBar('Poor', distribution.poor, total, Colors.red),
      ],
    );
  }

  Widget _buildDistributionBar(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count ($percentage%)',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceVariantColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: context.outlineColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: context.onSurfaceVariantColor),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.onSurfaceVariantColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ANSWERED':
        return 'Answered';
      case 'ENDED':
        return 'Completed';
      case 'MISSED':
        return 'Missed';
      case 'REJECTED':
        return 'Rejected';
      case 'FAILED':
        return 'Failed';
      case 'INITIATED':
        return 'Initiated';
      case 'RINGING':
        return 'Ringing';
      default:
        return status;
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Color _getQualityColor(double quality) {
    if (quality >= 80) return Colors.green;
    if (quality >= 60) return Colors.orange;
    return Colors.red;
  }
}
