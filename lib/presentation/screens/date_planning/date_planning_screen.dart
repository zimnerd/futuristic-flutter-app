import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/date_planning/date_planning_bloc.dart';
import '../../blocs/date_planning/date_planning_event.dart';
import '../../blocs/date_planning/date_planning_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/date_planning/date_plan_card.dart';
import '../../widgets/date_planning/date_suggestion_card.dart';
import 'create_date_plan_screen.dart';

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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateDatePlanScreen(),
              ),
            ),
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
        
        return const Center(
          child: Text('No date plans found'),
        );
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
              
              return const Center(
                child: Text('No suggestions available'),
              );
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
        
        return const Center(
          child: Text('No invitations found'),
        );
      },
    );
  }

  Widget _buildDatePlansList(List<Map<String, dynamic>> plans) {
    if (plans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No date plans yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first date plan!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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
      return const Center(
        child: Text('No suggestions available'),
      );
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
      return const Center(
        child: Text('No invitations found'),
      );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Suggestions'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter options will be added here'),
            // TODO: Add filter options
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
              // TODO: Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _viewDatePlan(Map<String, dynamic> plan) {
    // TODO: Navigate to date plan details
  }

  void _editDatePlan(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDatePlanScreen(planToEdit: plan),
      ),
    );
  }

  void _deleteDatePlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Date Plan'),
        content: const Text(
          'Are you sure you want to delete this date plan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete plan
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Date plan deleted successfully'),
                ),
              );
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

  void _createPlanFromSuggestion(Map<String, dynamic> suggestion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDatePlanScreen(suggestion: suggestion),
      ),
    );
  }

  void _acceptInvitation(Map<String, dynamic> invitation) {
    // TODO: Implement accept invitation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation accepted'),
      ),
    );
  }

  void _declineInvitation(Map<String, dynamic> invitation) {
    // TODO: Implement decline invitation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation declined'),
      ),
    );
  }
}
