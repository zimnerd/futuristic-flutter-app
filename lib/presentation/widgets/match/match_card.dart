import 'package:flutter/material.dart';
import '../../../data/models/match_model.dart';

/// Card widget for displaying match information
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onUnmatch,
  });

  final MatchModel match;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onUnmatch;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile photo placeholder
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Match info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match ${match.id.substring(0, 8)}...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${_getStatusText(match.status)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _getStatusColor(match.status),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (match.compatibilityScore > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Compatibility: ${(match.compatibilityScore * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(match.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(match.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Action buttons
              if (onAccept != null || onReject != null || onUnmatch != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onAccept != null)
                      _ActionButton(
                        onPressed: onAccept!,
                        icon: Icons.check,
                        label: 'Accept',
                        color: Colors.green,
                      ),
                    if (onReject != null)
                      _ActionButton(
                        onPressed: onReject!,
                        icon: Icons.close,
                        label: 'Reject',
                        color: Colors.red,
                      ),
                    if (onUnmatch != null)
                      _ActionButton(
                        onPressed: onUnmatch!,
                        icon: Icons.heart_broken,
                        label: 'Unmatch',
                        color: Colors.orange,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'matched':
        return 'Active Match';
      case 'pending':
        return 'Waiting for Response';
      case 'rejected':
        return 'Declined';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'matched':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
    );
  }
}
