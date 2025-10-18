import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../presentation/theme/pulse_colors.dart';
import '../../../../domain/entities/event.dart';
import '../bloc/event_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../../../presentation/widgets/common/pulse_toast.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  DateTime? _selectedDateTime;
  String _selectedCategory = 'Social';
  bool _isPublic = true;
  
  final List<String> _categories = [
    'Social',
    'Sports',
    'Entertainment',
    'Educational',
    'Networking',
    'Outdoor',
    'Food',
    'Arts',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventCreated) {
          PulseToast.success(context, message: 'Event created successfully!',
          );
          // Navigate to the newly created event details
          context.go('/events/${state.event.id}');
        } else if (state is EventError) {
          PulseToast.error(context, message: 'Error: ${state.message}',
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _canSave() ? _saveEvent : null,
            child: Text(
              'Create',
              style: TextStyle(
                color: _canSave() ? PulseColors.primary : PulseColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title
              _buildSectionTitle('Event Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'What\'s the name of your event?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: PulseColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 24),

              // Event Description
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell people what your event is about...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: PulseColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 24),

              // Event Category
              _buildSectionTitle('Category'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PulseColors.onSurface.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: PulseColors.surface,
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getEventCategoryIcon(category),
                            size: 20,
                            color: PulseColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Date and Time
              _buildSectionTitle('Date & Time'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PulseColors.onSurface.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.access_time, color: PulseColors.primary),
                  title: Text(
                    _selectedDateTime != null
                        ? DateFormat('EEEE, MMM d, y • h:mm a').format(_selectedDateTime!)
                        : 'Select date and time',
                    style: TextStyle(
                      color: _selectedDateTime != null 
                          ? PulseColors.onSurface 
                          : PulseColors.onSurfaceVariant,
                    ),
                  ),
                  onTap: _selectDateTime,
                  tileColor: PulseColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Location
              _buildSectionTitle('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Where is your event taking place?',
                  prefixIcon: Icon(Icons.location_on, color: PulseColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: PulseColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 24),

              // Privacy Settings
              _buildSectionTitle('Privacy'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PulseColors.onSurface.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _isPublic == true ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _isPublic == true ? PulseColors.primary : PulseColors.onSurfaceVariant,
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.public, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Public Event'),
                        ],
                      ),
                      subtitle: const Text('Anyone can see and join this event'),
                      tileColor: PulseColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      onTap: () => setState(() => _isPublic = true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        _isPublic == false ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _isPublic == false ? PulseColors.primary : PulseColors.onSurfaceVariant,
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Private Event'),
                        ],
                      ),
                      subtitle: const Text('Only invited people can see and join'),
                      tileColor: PulseColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      onTap: () => setState(() => _isPublic = false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Max Attendees (Optional)
              _buildSectionTitle('Maximum Attendees (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _maxAttendeesController,
                decoration: InputDecoration(
                  hintText: 'Leave empty for unlimited',
                  prefixIcon: Icon(Icons.group, color: PulseColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: PulseColors.surface,
                ),
                  keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSave() ? _saveEvent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PulseColors.onSurfaceVariant,
                    side: BorderSide(
                      color: PulseColors.onSurface.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: PulseColors.onSurface,
      ),
    );
  }

  bool _canSave() {
    return _titleController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().isNotEmpty &&
           _locationController.text.trim().isNotEmpty &&
           _selectedDateTime != null;
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now.add(const Duration(hours: 1));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate() || !_canSave()) {
      return;
    }

    // Resolve coordinates from address or current location
    EventCoordinates? resolvedCoordinates;
    try {
      final address = _locationController.text.trim();
      if (address.isNotEmpty) {
        final positionFromAddress = await _locationService
            .getCoordinatesFromAddress(address);
        if (positionFromAddress != null) {
          resolvedCoordinates = EventCoordinates(
            lat: positionFromAddress.latitude,
            lng: positionFromAddress.longitude,
          );
        }
      }

      // Fallback to current location if geocoding didn't work
      if (resolvedCoordinates == null) {
        final currentPosition = await _locationService.getCurrentLocation();
        if (currentPosition != null) {
          resolvedCoordinates = EventCoordinates(
            lat: currentPosition.latitude,
            lng: currentPosition.longitude,
          );
        }
      }
    } catch (_) {
      // Silently handle and show a friendly error below
    }

    if (resolvedCoordinates == null) {
      if (mounted) {
        PulseToast.error(
          context,
          message:
              'Unable to determine location coordinates. Please enter a valid address or enable location services.',
        );
      }
      return;
    }

    final request = CreateEventRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      coordinates: resolvedCoordinates,
      date: _selectedDateTime!,
      category: _selectedCategory.toLowerCase(),
      // maxAttendees: int.tryParse(_maxAttendeesController.text),
    );
    if (!mounted) return;
    context.read<EventBloc>().add(CreateEvent(request));
  }

  IconData _getEventCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return Icons.people;
      case 'sports':
        return Icons.sports_soccer;
      case 'entertainment':
        return Icons.movie;
      case 'educational':
        return Icons.school;
      case 'networking':
        return Icons.business;
      case 'outdoor':
        return Icons.nature;
      case 'food':
        return Icons.restaurant;
      case 'arts':
        return Icons.palette;
      default:
        return Icons.event;
    }
  }
}