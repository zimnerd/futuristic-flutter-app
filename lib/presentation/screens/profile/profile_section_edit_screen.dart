import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';

/// Profile section edit screen for editing individual profile sections
class ProfileSectionEditScreen extends StatefulWidget {
  final String sectionType;
  final Map<String, dynamic>? initialData;

  const ProfileSectionEditScreen({
    super.key,
    required this.sectionType,
    this.initialData,
  });

  @override
  State<ProfileSectionEditScreen> createState() => _ProfileSectionEditScreenState();
}

class _ProfileSectionEditScreenState extends State<ProfileSectionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _formData = Map.from(widget.initialData ?? {});
    _initializeControllers();
  }

  void _initializeControllers() {
    switch (widget.sectionType) {
      case 'basic_info':
        _controllers['name'] = TextEditingController(text: _formData['name'] ?? '');
        _controllers['age'] = TextEditingController(text: _formData['age']?.toString() ?? '');
        _controllers['bio'] = TextEditingController(text: _formData['bio'] ?? '');
        break;
      case 'work_education':
        _controllers['job'] = TextEditingController(text: _formData['job'] ?? '');
        _controllers['company'] = TextEditingController(text: _formData['company'] ?? '');
        _controllers['school'] = TextEditingController(text: _formData['school'] ?? '');
        break;
      case 'interests':
        // Interests are handled separately as a list
        break;
      case 'preferences':
        // Preferences are handled as dropdown selections
        break;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getSectionTitle(),
          style: PulseTextStyles.titleLarge.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PulseColors.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveSection,
            child: Text(
              'Save',
              style: PulseTextStyles.titleMedium.copyWith(
                color: PulseColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PulseSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionDescription(),
                const SizedBox(height: PulseSpacing.xl),
                _buildSectionContent(),
                const SizedBox(height: PulseSpacing.xxl),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDescription() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: PulseColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PulseSpacing.sm),
            decoration: BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            child: Icon(
              _getSectionIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSectionTitle(),
                  style: PulseTextStyles.titleLarge.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: PulseSpacing.xs),
                Text(
                  _getSectionDescription(),
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (widget.sectionType) {
      case 'basic_info':
        return _buildBasicInfoSection();
      case 'work_education':
        return _buildWorkEducationSection();
      case 'interests':
        return _buildInterestsSection();
      case 'preferences':
        return _buildPreferencesSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _controllers['name']!,
          label: 'Name',
          hint: 'Enter your first name',
          icon: Icons.person,
          isRequired: true,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Name is required';
            }
            if (value!.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['age']!,
          label: 'Age',
          hint: 'Enter your age',
          icon: Icons.cake,
          keyboardType: TextInputType.number,
          isRequired: true,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Age is required';
            }
            final age = int.tryParse(value!);
            if (age == null || age < 18 || age > 100) {
              return 'Please enter a valid age (18-100)';
            }
            return null;
          },
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['bio']!,
          label: 'Bio',
          hint: 'Tell people about yourself...',
          icon: Icons.description,
          maxLines: 4,
          maxLength: 500,
          validator: (value) {
            if (value != null && value.length > 500) {
              return 'Bio must be less than 500 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWorkEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _controllers['job']!,
          label: 'Job Title',
          hint: 'e.g., Software Engineer',
          icon: Icons.work,
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['company']!,
          label: 'Company',
          hint: 'e.g., Google',
          icon: Icons.business,
        ),
        const SizedBox(height: PulseSpacing.lg),
        _buildTextField(
          controller: _controllers['school']!,
          label: 'School',
          hint: 'e.g., Harvard University',
          icon: Icons.school,
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    final availableInterests = [
      'Music', 'Travel', 'Fitness', 'Photography', 'Cooking', 'Reading',
      'Movies', 'Art', 'Sports', 'Gaming', 'Dancing', 'Hiking',
      'Yoga', 'Coffee', 'Wine', 'Fashion', 'Technology', 'Animals',
    ];

    final selectedInterests = List<String>.from(_formData['interests'] ?? []);

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your interests (max 10)',
              style: PulseTextStyles.titleMedium.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: PulseSpacing.md),
            Text(
              'Choose what you\'re passionate about to help people understand you better.',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Wrap(
              spacing: PulseSpacing.sm,
              runSpacing: PulseSpacing.sm,
              children: availableInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected && selectedInterests.length < 10) {
                        selectedInterests.add(interest);
                      } else if (!selected) {
                        selectedInterests.remove(interest);
                      }
                      _formData['interests'] = selectedInterests;
                    });
                  },
                  selectedColor: PulseColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: PulseColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? PulseColors.primary : PulseColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: PulseSpacing.md),
            Text(
              '${selectedInterests.length}/10 selected',
              style: PulseTextStyles.bodySmall.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferencesSection() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreferenceDropdown(
              title: 'I am',
              value: _formData['gender']?.toString() ?? 'Woman',
              options: ['Woman', 'Man', 'Non-binary', 'Other'],
              onChanged: (value) {
                setState(() {
                  _formData['gender'] = value;
                });
              },
            ),
            const SizedBox(height: PulseSpacing.lg),
            _buildPreferenceDropdown(
              title: 'Looking for',
              value: _formData['lookingFor']?.toString() ?? 'Men',
              options: ['Men', 'Women', 'Non-binary', 'Everyone'],
              onChanged: (value) {
                setState(() {
                  _formData['lookingFor'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: PulseTextStyles.titleMedium.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: PulseColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.error),
            ),
            filled: true,
            fillColor: PulseColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceDropdown({
    required String title,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PulseTextStyles.titleMedium.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PulseSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.md),
              borderSide: BorderSide(color: PulseColors.primary, width: 2),
            ),
            filled: true,
            fillColor: PulseColors.surfaceVariant.withValues(alpha: 0.5),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(PulseSpacing.md),
              side: BorderSide(color: PulseColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.md),
              ),
            ),
            child: Text(
              'Cancel',
              style: PulseTextStyles.titleMedium.copyWith(
                color: PulseColors.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: PulseSpacing.md),
        Expanded(
          flex: 2,
          child: PulseButton(
            text: 'Save Changes',
            onPressed: _saveSection,
          ),
        ),
      ],
    );
  }

  String _getSectionTitle() {
    switch (widget.sectionType) {
      case 'basic_info':
        return 'Basic Information';
      case 'work_education':
        return 'Work & Education';
      case 'interests':
        return 'Interests';
      case 'preferences':
        return 'Dating Preferences';
      default:
        return 'Edit Profile';
    }
  }

  String _getSectionDescription() {
    switch (widget.sectionType) {
      case 'basic_info':
        return 'Update your name, age, and bio to help people get to know you better.';
      case 'work_education':
        return 'Share your professional and educational background.';
      case 'interests':
        return 'Select your hobbies and interests to find better matches.';
      case 'preferences':
        return 'Set your dating preferences and who you\'re looking for.';
      default:
        return 'Edit your profile information.';
    }
  }

  IconData _getSectionIcon() {
    switch (widget.sectionType) {
      case 'basic_info':
        return Icons.person;
      case 'work_education':
        return Icons.work;
      case 'interests':
        return Icons.favorite;
      case 'preferences':
        return Icons.tune;
      default:
        return Icons.edit;
    }
  }

  void _saveSection() {
    if (_formKey.currentState?.validate() ?? false) {
      // Update form data from controllers
      for (final entry in _controllers.entries) {
        _formData[entry.key] = entry.value.text.trim();
      }

      // Convert age to int if it's in the form data
      if (_formData.containsKey('age') && _formData['age'] is String) {
        _formData['age'] = int.tryParse(_formData['age']) ?? 18;
      }

      // Navigate back with the updated data
      context.pop(_formData);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getSectionTitle()} updated successfully'),
          backgroundColor: PulseColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}