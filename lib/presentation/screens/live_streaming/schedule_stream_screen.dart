import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/services/live_streaming_service.dart';
import '../../blocs/live_streaming/live_streaming_bloc.dart';
import '../../blocs/live_streaming/live_streaming_event.dart';
import '../../blocs/live_streaming/live_streaming_state.dart';
import '../../widgets/common/pulse_toast.dart';

/// Screen for scheduling a future live stream
/// Can also be used to edit an existing scheduled stream
class ScheduleStreamScreen extends StatefulWidget {
  final Map<String, dynamic>? streamToEdit;

  const ScheduleStreamScreen({super.key, this.streamToEdit});

  @override
  State<ScheduleStreamScreen> createState() => _ScheduleStreamScreenState();
}

class _ScheduleStreamScreenState extends State<ScheduleStreamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _selectedDateTime;
  String _streamType = 'public';
  double _maxViewers = 100;
  String? _thumbnailUrl;
  String? _localThumbnailPath;
  bool _isAdultsOnly = false;
  bool _isLoading = false;
  bool _isUploadingThumbnail = false;

  // Theme constants for DRY code
  static const _fieldFillColor = Color(0x0DFFFFFF); // white with alpha 0.05
  static const _borderColor = Color(0x33FFFFFF); // white with alpha 0.2

  @override
  void initState() {
    super.initState();
    _loadExistingStreamData();
  }

  /// Load existing stream data if editing
  void _loadExistingStreamData() {
    final streamData = widget.streamToEdit;
    if (streamData == null) return;

    // Pre-fill form fields
    _titleController.text = streamData['title'] ?? '';
    _descriptionController.text = streamData['description'] ?? '';

    // Parse and set scheduled date/time
    if (streamData['scheduledStartTime'] != null) {
      _selectedDateTime = DateTime.parse(streamData['scheduledStartTime']);
    }

    // Set stream type
    _streamType = streamData['type'] ?? 'public';

    // Set max viewers
    if (streamData['maxViewers'] != null) {
      _maxViewers = (streamData['maxViewers'] as num).toDouble();
    }

    // Set thumbnail URL if exists
    _thumbnailUrl = streamData['thumbnailUrl'];

    // Set adults only flag
    _isAdultsOnly = streamData['isAdultsOnly'] ?? false;

    // Parse tags
    if (streamData['tags'] != null && streamData['tags'] is List) {
      final tags = (streamData['tags'] as List).join(', ');
      _tagsController.text = tags;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour + 1, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _localThumbnailPath = pickedFile.path;
        _thumbnailUrl = null; // Clear previous URL
      });
    }
  }

  /// Upload thumbnail to server and return URL
  Future<String?> _uploadThumbnail(LiveStreamingService service) async {
    if (_localThumbnailPath == null) return null;

    setState(() => _isUploadingThumbnail = true);

    try {
      final url = await service.uploadThumbnail(_localThumbnailPath!);

      if (url != null) {
        setState(() {
          _thumbnailUrl = url;
          _isUploadingThumbnail = false;
        });
        return url;
      } else {
        setState(() => _isUploadingThumbnail = false);
        if (mounted) {
          _showError('Failed to upload thumbnail. Please try again.');
        }
        return null;
      }
    } catch (e) {
      setState(() => _isUploadingThumbnail = false);
      if (mounted) {
        _showError('Error uploading thumbnail: $e');
      }
      return null;
    }
  }

  Future<void> _scheduleStream() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      _showError('Please select a date and time for the stream');
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      _showError('Scheduled time must be in the future');
      return;
    }

    // Upload thumbnail if user selected a local file
    String? finalThumbnailUrl = _thumbnailUrl;
    if (_localThumbnailPath != null && _thumbnailUrl == null) {
      final service = context.read<LiveStreamingService>();
      finalThumbnailUrl = await _uploadThumbnail(service);

      // If upload failed and user had selected a thumbnail, don't proceed
      if (finalThumbnailUrl == null && _localThumbnailPath != null) {
        return; // Error already shown in _uploadThumbnail
      }
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (!mounted) return;

    // Check if editing existing stream or creating new one
    final isEditing = widget.streamToEdit != null;

    if (isEditing) {
      // Update existing scheduled stream
      context.read<LiveStreamingBloc>().add(
        UpdateScheduledStream(
          streamId: widget.streamToEdit!['id'],
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          scheduledStartTime: _selectedDateTime!,
          type: _streamType,
          maxViewers: _maxViewers.toInt(),
          thumbnailUrl: finalThumbnailUrl,
          tags: tags.isEmpty ? null : tags,
          isAdultsOnly: _isAdultsOnly,
        ),
      );
    } else {
      // Create new scheduled stream
      context.read<LiveStreamingBloc>().add(
        ScheduleLiveStream(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          scheduledStartTime: _selectedDateTime!,
          type: _streamType,
          maxViewers: _maxViewers.toInt(),
          thumbnailUrl: finalThumbnailUrl,
          tags: tags.isEmpty ? null : tags,
          isAdultsOnly: _isAdultsOnly,
        ),
      );
    }
  }

  void _showError(String message) {
    PulseToast.error(context, message: message);
  }

  void _showSuccess() {
    final message = widget.streamToEdit != null
        ? 'Stream updated successfully!'
        : 'Stream scheduled successfully!';
    PulseToast.success(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LiveStreamingBloc, LiveStreamingState>(
      listener: (context, state) {
        if (state is SchedulingStream) {
          setState(() => _isLoading = true);
        } else if (state is StreamScheduled ||
            state is ScheduledStreamUpdated) {
          setState(() => _isLoading = false);
          _showSuccess();
          Navigator.of(context).pop(true); // Return true to indicate success
        } else if (state is LiveStreamingError) {
          setState(() => _isLoading = false);
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.streamToEdit != null
                ? 'Edit Scheduled Stream'
                : 'Schedule Stream',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Enter stream title',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: _fieldFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      if (value.trim().length > 100) {
                        return 'Title must be less than 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Describe what your stream is about',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: _fieldFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().length > 500) {
                        return 'Description must be less than 500 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date and Time picker
                  InkWell(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _fieldFillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scheduled Date & Time *',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDateTime == null
                                      ? 'Select date and time'
                                      : DateFormat(
                                          'MMM dd, yyyy • hh:mm a',
                                        ).format(_selectedDateTime!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stream type selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _fieldFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stream Type',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStreamTypeButton(
                                'public',
                                'Public',
                                Icons.public,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStreamTypeButton(
                                'private',
                                'Private',
                                Icons.lock,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStreamTypeButton(
                                'premium',
                                'Premium',
                                Icons.star,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Max viewers slider
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _fieldFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Max Viewers',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _maxViewers.toInt().toString(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).primaryColor,
                            inactiveTrackColor: Colors.grey,
                            thumbColor: Theme.of(context).primaryColor,
                          ),
                          child: Slider(
                            value: _maxViewers,
                            min: 10,
                            max: 1000,
                            divisions: 99,
                            onChanged: (value) {
                              setState(() => _maxViewers = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thumbnail picker
                  InkWell(
                    onTap: _pickThumbnail,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: _fieldFillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child:
                          _localThumbnailPath == null && _thumbnailUrl == null
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Thumbnail (Optional)',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _localThumbnailPath != null
                                      ? Image.file(
                                          File(_localThumbnailPath!),
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 48,
                                                  ),
                                                );
                                              },
                                        )
                                      : Image.network(
                                          _thumbnailUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 48,
                                                  ),
                                                );
                                              },
                                        ),
                                ),
                                if (_isUploadingThumbnail)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Uploading thumbnail...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!_isUploadingThumbnail)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _thumbnailUrl = null;
                                            _localThumbnailPath = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags field
                  TextFormField(
                    controller: _tagsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tags',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Enter tags separated by commas',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: _fieldFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Adults only switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _fieldFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Adults Only (18+)',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        Switch(
                          value: _isAdultsOnly,
                          activeTrackColor: Colors.orange.withValues(
                            alpha: 0.5,
                          ),
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.orange;
                            }
                            return null;
                          }),
                          onChanged: (value) {
                            setState(() => _isAdultsOnly = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Schedule button
                  ElevatedButton(
                    onPressed: (_isLoading || _isUploadingThumbnail)
                        ? null
                        : _scheduleStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploadingThumbnail
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.streamToEdit != null
                                ? 'Update Stream'
                                : 'Schedule Stream',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamTypeButton(String value, String label, IconData icon) {
    final isSelected = _streamType == value;
    return InkWell(
      onTap: () => setState(() => _streamType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
