import 'package:flutter/material.dart';

import '../../../data/models/voice_message.dart';
import '../../theme/pulse_colors.dart';

/// Widget for displaying a list of voice messages
class VoiceMessageListWidget extends StatelessWidget {
  final List<VoiceMessage> messages;
  final Function(VoiceMessage) onMessageTap;
  final Function(VoiceMessage)? onMessageReply;
  final Function(VoiceMessage)? onMessageDelete;
  final String emptyStateTitle;
  final String emptyStateSubtitle;

  const VoiceMessageListWidget({
    super.key,
    required this.messages,
    required this.onMessageTap,
    this.onMessageReply,
    this.onMessageDelete,
    required this.emptyStateTitle,
    required this.emptyStateSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageCard(context, message);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            emptyStateTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            emptyStateSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, VoiceMessage message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onMessageTap(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Play button and waveform
              Expanded(
                child: Row(
                  children: [
                    _buildPlayButton(message),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWaveform(message),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _formatDuration(message.duration),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 8),
                              if (!message.isPlayed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PulseColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Message info and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.senderName != null)
                    Text(
                      message.senderName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(message.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButtons(context, message),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(VoiceMessage message) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PulseColors.primary,
        boxShadow: [
          BoxShadow(
            color: PulseColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        message.isPlayed ? Icons.replay : Icons.play_arrow,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildWaveform(VoiceMessage message) {
    return SizedBox(
      height: 40,
      child: Row(
        children: message.waveformData.map((amplitude) {
          return Container(
            width: 3,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: amplitude * 40,
            decoration: BoxDecoration(
              color: message.isPlayed ? Colors.grey[400] : PulseColors.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VoiceMessage message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onMessageReply != null)
          IconButton(
            onPressed: () => onMessageReply!(message),
            icon: const Icon(Icons.reply),
            iconSize: 20,
            color: Colors.blue,
            tooltip: 'Reply',
          ),
        if (onMessageDelete != null)
          IconButton(
            onPressed: () => _showDeleteDialog(context, message),
            icon: const Icon(Icons.delete_outline),
            iconSize: 20,
            color: Colors.red,
            tooltip: 'Delete',
          ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, VoiceMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Voice Message'),
        content: const Text(
          'Are you sure you want to delete this voice message? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onMessageDelete!(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
