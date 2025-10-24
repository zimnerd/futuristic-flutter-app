import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Widget for displaying date plan information
class DatePlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showInvitationActions;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const DatePlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showInvitationActions = false,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final String title = plan['title'] ?? 'Untitled Plan';
    final String description = plan['description'] ?? '';
    final String location = plan['location'] ?? '';
    final String date = plan['scheduledDate'] ?? '';
    final String budget = plan['budget'] ?? '';
    final List<dynamic> activities = plan['activities'] ?? [];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!showInvitationActions)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],

              const SizedBox(height: 12),

              // Plan details
              Column(
                children: [
                  if (date.isNotEmpty)
                    _buildDetailRow(context, Icons.calendar_today, 'Date', date),
                  if (location.isNotEmpty)
                    _buildDetailRow(context, Icons.location_on, 'Location', location),
                  if (budget.isNotEmpty)
                    _buildDetailRow(context, Icons.attach_money, 'Budget', budget),
                  if (activities.isNotEmpty)
                    _buildDetailRow(
                      context,
                      Icons.local_activity,
                      'Activities',
                      '${activities.length} activities planned',
                    ),
                ],
              ),

              if (showInvitationActions) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                        ),
                        child: Text(
                          'Accept',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: const Text('Decline'),
                      ),
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

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
