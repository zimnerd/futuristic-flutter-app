import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Screen for starting or editing a live stream
class StartStreamScreen extends StatefulWidget {
  final Map<String, dynamic>? streamToEdit;

  const StartStreamScreen({
    super.key,
    this.streamToEdit,
  });

  @override
  State<StartStreamScreen> createState() => _StartStreamScreenState();
}

class _StartStreamScreenState extends State<StartStreamScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'General';

  final List<String> _categories = [
    'General',
    'Gaming',
    'Music',
    'Art',
    'Education',
    'Fitness',
    'Cooking',
    'Travel',
    'Technology',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.streamToEdit != null) {
      _titleController.text = widget.streamToEdit!['title'] ?? '';
      _descriptionController.text = widget.streamToEdit!['description'] ?? '';
      _selectedCategory = widget.streamToEdit!['category'] ?? 'General';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.streamToEdit != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Stream' : 'Start Live Stream'),
        actions: [
          TextButton(
            onPressed: _startStream,
            child: Text(
              isEditing ? 'Update' : 'Start',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 60,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Camera Preview',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Stream Title',
                hintText: 'Enter a catchy title for your stream',
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
                hintText: 'Describe what your stream is about',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            
            const SizedBox(height: 16),
            
            // Category selection
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            
            const Spacer(),
            
            // Start/Update button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                ),
                child: Text(
                  isEditing ? 'Update Stream' : 'Go Live!',
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

  void _startStream() {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your stream'),
        ),
      );
      return;
    }
    
    // TODO: Implement stream creation/update
    final message = widget.streamToEdit != null 
        ? 'Stream updated successfully!'
        : 'Live stream started!';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    
    Navigator.pop(context);
  }
}
