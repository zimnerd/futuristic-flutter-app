import 'package:flutter/material.dart';

import '../../../data/models/safety.dart';
import '../../theme/pulse_colors.dart';

/// Widget for displaying safety tips in a list format
class SafetyTipsWidget extends StatelessWidget {
  final List<SafetyTip> tips;
  final VoidCallback? onTipRead;

  const SafetyTipsWidget({super.key, required this.tips, this.onTipRead});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No safety tips available',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tip = tips[index];
        return _buildTipCard(context, tip);
      },
    );
  }

  Widget _buildTipCard(BuildContext context, SafetyTip tip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(tip.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(tip.category),
            color: _getCategoryColor(tip.category),
          ),
        ),
        title: Text(
          tip.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(
              _getPriorityIcon(tip.priority),
              size: 16,
              color: _getPriorityColor(tip.priority),
            ),
            const SizedBox(width: 4),
            Text(
              _getPriorityLabel(tip.priority).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getPriorityColor(tip.priority),
              ),
            ),
            const Spacer(),
            if (tip.isActive)
              const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tip.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated: ${_formatDate(tip.updatedAt ?? tip.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () {
                  // Mark as read logic would go here
                  onTipRead?.call();
                },
                child: const Text('Share Tip'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(SafetyTipCategory category) {
    switch (category) {
      case SafetyTipCategory.datingSafety:
        return PulseColors.primary;
      case SafetyTipCategory.meetingTips:
        return Colors.orange;
      case SafetyTipCategory.privacyProtection:
        return Colors.green;
      case SafetyTipCategory.onlineSafety:
        return Colors.blue;
      case SafetyTipCategory.emergencyPreparedness:
        return Colors.red;
      case SafetyTipCategory.scamAwareness:
        return Colors.purple;
      case SafetyTipCategory.general:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(SafetyTipCategory category) {
    switch (category) {
      case SafetyTipCategory.datingSafety:
        return Icons.favorite;
      case SafetyTipCategory.meetingTips:
        return Icons.people;
      case SafetyTipCategory.privacyProtection:
        return Icons.privacy_tip;
      case SafetyTipCategory.onlineSafety:
        return Icons.security;
      case SafetyTipCategory.emergencyPreparedness:
        return Icons.warning;
      case SafetyTipCategory.scamAwareness:
        return Icons.shield;
      case SafetyTipCategory.general:
        return Icons.info;
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 3) {
      return Colors.red; // High priority
    } else if (priority >= 2) {
      return Colors.orange; // Medium priority
    } else {
      return Colors.green; // Low priority
    }
  }

  IconData _getPriorityIcon(int priority) {
    if (priority >= 3) {
      return Icons.priority_high;
    } else if (priority >= 2) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  String _getPriorityLabel(int priority) {
    if (priority >= 3) {
      return 'High';
    } else if (priority >= 2) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
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
