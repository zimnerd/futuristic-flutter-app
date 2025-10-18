import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../blocs/date_planning/date_planning_bloc.dart';
import '../../blocs/date_planning/date_planning_event.dart';
import '../../widgets/common/pulse_toast.dart';

/// Screen showing detailed view of a date plan
class DatePlanDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> datePlan;

  const DatePlanDetailsScreen({
    super.key,
    required this.datePlan,
  });

  @override
  State<DatePlanDetailsScreen> createState() => _DatePlanDetailsScreenState();
}

class _DatePlanDetailsScreenState extends State<DatePlanDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final plan = widget.datePlan;
    final scheduledDate = DateTime.tryParse(plan['scheduledDate'] ?? '');
    final activities = List<String>.from(plan['activities'] ?? []);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(plan['title'] ?? 'Date Plan'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editPlan();
                  break;
                case 'share':
                  _sharePlan();
                  break;
                case 'delete':
                  _deletePlan();
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
                    Text('Edit Plan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Plan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete Plan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['title'] ?? 'Untitled Plan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan['description'] != null && plan['description'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        plan['description'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date & Time
            if (scheduledDate != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Date & Time'),
                  subtitle: Text(
                    '${_formatDate(scheduledDate)} at ${_formatTime(scheduledDate)}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Location
            if (plan['location'] != null && plan['location'].isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Location'),
                  subtitle: Text(plan['location']),
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () => _openLocation(plan['location']),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Budget
            if (plan['budget'] != null && plan['budget'].isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Budget'),
                  subtitle: Text(plan['budget']),
                ),
              ),
            const SizedBox(height: 16),
            
            // Activities
            if (activities.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activities.map((activity) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(activity)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendInvitation,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Invitation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editPlan,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Plan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _editPlan() {
    context.push(
      AppRoutes.createDatePlan,
      extra: {'planToEdit': widget.datePlan},
    );
  }

  void _sharePlan() {
    // Share plan functionality
    PulseToast.success(context, message: 'Plan shared!',
    );
  }

  void _deletePlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Date Plan'),
        content: const Text(
          'Are you sure you want to delete this date plan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final planId = widget.datePlan['id'] as String?;
              if (planId != null) {
                context.read<DatePlanningBloc>().add(CancelDatePlan(
                  planId: planId,
                  reason: 'Deleted by user',
                ));
              }
              Navigator.pop(context); // Close dialog
              context.pop(); // Return to previous screen
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sendInvitation() {
    // Show user picker dialog to send invitation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Invitation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose who to invite to this date:'),
            // In a real app, this would show a list of matches/contacts
            ListTile(
              leading: CircleAvatar(child: Text('A')),
              title: Text('Anna Smith'),
              subtitle: Text('Available today'),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('B')),
              title: Text('Bella Johnson'),
              subtitle: Text('Last seen 2 hours ago'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PulseToast.success(context, message: 'Invitation sent!',
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _openLocation(String location) {
    // Open location in maps app (would use url_launcher in real implementation)
    PulseToast.info(context, message: 'Opening $location in maps...',
    );
  }
}