import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../blocs/date_planning/date_planning_bloc.dart';
import '../../blocs/date_planning/date_planning_event.dart';
import '../../widgets/common/pulse_toast.dart';

/// Screen for creating or editing a date plan
class CreateDatePlanScreen extends StatefulWidget {
  final Map<String, dynamic>? planToEdit;
  final Map<String, dynamic>? suggestion;

  const CreateDatePlanScreen({
    super.key,
    this.planToEdit,
    this.suggestion,
  });

  @override
  State<CreateDatePlanScreen> createState() => _CreateDatePlanScreenState();
}

class _CreateDatePlanScreenState extends State<CreateDatePlanScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  final List<String> _activities = [];
  final _activityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.planToEdit != null) {
      final plan = widget.planToEdit!;
      _titleController.text = plan['title'] ?? '';
      _descriptionController.text = plan['description'] ?? '';
      _locationController.text = plan['location'] ?? '';
      _budgetController.text = plan['budget'] ?? '';
      _activities.addAll(List<String>.from(plan['activities'] ?? []));
    } else if (widget.suggestion != null) {
      final suggestion = widget.suggestion!;
      _titleController.text = suggestion['title'] ?? '';
      _descriptionController.text = suggestion['description'] ?? '';
      _locationController.text = suggestion['location'] ?? '';
      _budgetController.text = suggestion['estimatedCost'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.planToEdit != null;
    final isFromSuggestion = widget.suggestion != null;
    
    return KeyboardDismissibleScaffold(
      appBar: AppBar(
        title: Text(
          isEditing 
              ? 'Edit Date Plan' 
              : isFromSuggestion 
                  ? 'Create from Suggestion'
                  : 'Create Date Plan',
        ),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: Text(
              isEditing ? 'Update' : 'Create',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Plan Title',
                hintText: 'Give your date plan a name',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            
            const SizedBox(height: 16),
            
            // Description input
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your date plan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            
            const SizedBox(height: 16),
            
            // Location input
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Where will this date take place?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Date and time selection
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _selectedTime.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Budget input
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget (optional)',
                hintText: 'Estimated budget for this date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 24),
            
            // Activities section
            const Text(
              'Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Add activity input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activityController,
                    decoration: const InputDecoration(
                      hintText: 'Add an activity',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addActivity(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addActivity,
                  child: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Activities list
            if (_activities.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  return Card(
                    child: ListTile(
                      title: Text(activity),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeActivity(index),
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.local_activity, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No activities added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Create/Update button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                ),
                child: Text(
                  isEditing ? 'Update Plan' : 'Create Plan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _addActivity() {
    final activity = _activityController.text.trim();
    if (activity.isNotEmpty) {
      setState(() {
        _activities.add(activity);
        _activityController.clear();
      });
    }
  }

  void _removeActivity(int index) {
    setState(() {
      _activities.removeAt(index);
    });
  }

  void _savePlan() {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final budget = _budgetController.text.trim();
    
    if (title.isEmpty) {
      PulseToast.error(
        context,
        message: 'Please enter a title for your date plan',
      );
      return;
    }
    
    if (location.isEmpty) {
      PulseToast.error(
        context,
        message: 'Please enter a location for your date plan',
      );
      return;
    }

    // Combine date and time
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Check if date is in the future
    if (scheduledDateTime.isBefore(DateTime.now())) {
      PulseToast.error(
        context,
        message: 'Please select a future date and time',
      );
      return;
    }

    try {
      if (widget.planToEdit != null) {
        // Update existing plan
        final planId = widget.planToEdit!['id'] as String;
        context.read<DatePlanningBloc>().add(UpdateDatePlan(
          planId: planId,
          updates: {
            'title': title,
            'description': description,
            'location': location,
            'budget': budget,
            'scheduledDate': scheduledDateTime.toIso8601String(),
            'activities': _activities,
          },
        ));
      } else {
        // Create new plan
        context.read<DatePlanningBloc>().add(CreateDatePlan(
          title: title,
          description: description,
          scheduledDate: scheduledDateTime,
          location: location,
          budget: budget.isNotEmpty ? budget : null,
          activities: _activities,
        ));
      }

      final message = widget.planToEdit != null 
          ? 'Date plan updated successfully!'
          : 'Date plan created successfully!';
      
      PulseToast.success(
        context,
        message: message,
      );
      
      Navigator.pop(context);
    } catch (e) {
      PulseToast.error(
        context,
        message: 'Failed to save plan: $e',
      );
    }
  }
}
