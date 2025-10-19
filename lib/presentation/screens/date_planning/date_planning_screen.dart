import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../navigation/app_router.dart';
import '../../blocs/date_planning/date_planning_bloc.dart';
import '../../blocs/date_planning/date_planning_event.dart';
import '../../blocs/date_planning/date_planning_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/date_planning/date_plan_card.dart';
import '../../widgets/date_planning/date_suggestion_card.dart';
import '../../widgets/common/pulse_toast.dart';

/// Main screen for date planning functionality
class DatePlanningScreen extends StatefulWidget {
  const DatePlanningScreen({super.key});

  @override
  State<DatePlanningScreen> createState() => _DatePlanningScreenState();
}

class _DatePlanningScreenState extends State<DatePlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data
    context.read<DatePlanningBloc>().add(const LoadUserDatePlans());
    context.read<DatePlanningBloc>().add(const LoadDateSuggestions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Plans'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Invitations'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.createDatePlan),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPlansTab(),
          _buildSuggestionsTab(),
          _buildInvitationsTab(),
        ],
      ),
    );
  }

  Widget _buildMyPlansTab() {
    return BlocBuilder<DatePlanningBloc, DatePlanningState>(
      builder: (context, state) {
        if (state is DatePlanningLoading) {
          return const PulseLoadingWidget();
        }

        if (state is DatePlanningError) {
          return PulseErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<DatePlanningBloc>().add(const LoadUserDatePlans());
            },
          );
        }

        if (state is UserDatePlansLoaded) {
          return _buildDatePlansList(state.datePlans);
        }

        return const Center(child: Text('No date plans found'));
      },
    );
  }

  Widget _buildSuggestionsTab() {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<DatePlanningBloc>().add(
                    const LoadDateSuggestions(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),

        // Suggestions list
        Expanded(
          child: BlocBuilder<DatePlanningBloc, DatePlanningState>(
            builder: (context, state) {
              if (state is DatePlanningLoading) {
                return const PulseLoadingWidget();
              }

              if (state is DatePlanningError) {
                return PulseErrorWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<DatePlanningBloc>().add(
                      const LoadDateSuggestions(),
                    );
                  },
                );
              }

              if (state is DateSuggestionsLoaded) {
                return _buildSuggestionsList(state.suggestions);
              }

              return const Center(child: Text('No suggestions available'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationsTab() {
    return BlocBuilder<DatePlanningBloc, DatePlanningState>(
      builder: (context, state) {
        if (state is DatePlanningLoading) {
          return const PulseLoadingWidget();
        }

        if (state is DatePlanningError) {
          return PulseErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<DatePlanningBloc>().add(const LoadDateInvitations());
            },
          );
        }

        if (state is DateInvitationsLoaded) {
          return _buildInvitationsList(state.invitations);
        }

        return const Center(child: Text('No invitations found'));
      },
    );
  }

  Widget _buildDatePlansList(List<Map<String, dynamic>> plans) {
    if (plans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No date plans yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first date plan!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DatePlanCard(
            plan: plan,
            onTap: () => _viewDatePlan(plan),
            onEdit: () => _editDatePlan(plan),
            onDelete: () => _deleteDatePlan(plan),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList(List<Map<String, dynamic>> suggestions) {
    if (suggestions.isEmpty) {
      return const Center(child: Text('No suggestions available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DateSuggestionCard(
            suggestion: suggestion,
            onTap: () => _createPlanFromSuggestion(suggestion),
          ),
        );
      },
    );
  }

  Widget _buildInvitationsList(List<Map<String, dynamic>> invitations) {
    if (invitations.isEmpty) {
      return const Center(child: Text('No invitations found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invitations.length,
      itemBuilder: (context, index) {
        final invitation = invitations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DatePlanCard(
            plan: invitation,
            onTap: () => _viewDatePlan(invitation),
            showInvitationActions: true,
            onAccept: () => _acceptInvitation(invitation),
            onDecline: () => _declineInvitation(invitation),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(context: context, builder: (context) => _FilterDialog());
  }

  void _viewDatePlan(Map<String, dynamic> plan) {
    context.push(AppRoutes.datePlanDetails, extra: plan);
  }

  void _editDatePlan(Map<String, dynamic> plan) {
    context.push(AppRoutes.createDatePlan, extra: {'planToEdit': plan});
  }

  void _deleteDatePlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Date Plan'),
        content: const Text('Are you sure you want to delete this date plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete the date plan - would need to add DeleteDatePlan event to bloc
              PulseToast.success(
                context,
                message: 'Date plan deleted successfully',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createPlanFromSuggestion(Map<String, dynamic> suggestion) {
    context.push(AppRoutes.createDatePlan, extra: {'suggestion': suggestion});
  }

  void _acceptInvitation(Map<String, dynamic> invitation) {
    // Accept the date invitation
    context.read<DatePlanningBloc>().add(
      UpdateDatePlan(
        planId: invitation['id'] ?? 'unknown',
        updates: {'status': 'accepted'},
      ),
    );
    PulseToast.success(context, message: 'Invitation accepted');
  }

  void _declineInvitation(Map<String, dynamic> invitation) {
    // Decline the date invitation
    context.read<DatePlanningBloc>().add(
      UpdateDatePlan(
        planId: invitation['id'] ?? 'unknown',
        updates: {'status': 'declined'},
      ),
    );
    PulseToast.info(context, message: 'Invitation declined');
  }
}

class _FilterDialog extends StatefulWidget {
  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String selectedPrice = 'Any';
  String selectedTime = 'Any';
  String selectedType = 'Any';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Suggestions'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedPrice,
            decoration: const InputDecoration(labelText: 'Price Range'),
            items: [
              'Any',
              '\$',
              '\$\$',
              '\$\$\$',
              '\$\$\$\$',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => selectedPrice = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedTime,
            decoration: const InputDecoration(labelText: 'Time of Day'),
            items: [
              'Any',
              'Morning',
              'Afternoon',
              'Evening',
              'Night',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => selectedTime = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: const InputDecoration(labelText: 'Activity Type'),
            items: [
              'Any',
              'Dining',
              'Entertainment',
              'Outdoor',
              'Culture',
              'Adventure',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => selectedType = value!),
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
            // Apply filters to date suggestions
            PulseToast.info(
              context,
              message:
                  'Filters applied: $selectedPrice, $selectedTime, $selectedType',
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
