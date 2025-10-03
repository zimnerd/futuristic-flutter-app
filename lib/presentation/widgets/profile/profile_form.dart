import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/pulse_colors.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController bioController;
  final TextEditingController ageController;
  final TextEditingController jobController;
  final TextEditingController companyController;
  final TextEditingController schoolController;
  final String selectedGender;
  final String selectedPreference;
  final List<String> selectedInterests;
  final Function(String) onGenderChanged;
  final Function(String) onPreferenceChanged;
  final Function(List<String>) onInterestsChanged;

  const ProfileForm({
    super.key,
    required this.nameController,
    required this.bioController,
    required this.ageController,
    required this.jobController,
    required this.companyController,
    required this.schoolController,
    required this.selectedGender,
    required this.selectedPreference,
    required this.selectedInterests,
    required this.onGenderChanged,
    required this.onPreferenceChanged,
    required this.onInterestsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: 24),
        _buildAboutSection(context),
        const SizedBox(height: 24),
        _buildWorkEducationSection(context),
        const SizedBox(height: 24),
        _buildPreferencesSection(),
        const SizedBox(height: 24),
        _buildInterestsSection(),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: nameController,
          label: 'Name',
          hint: 'Enter your name',
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: ageController,
                label: 'Age',
                hint: '18',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 18 || age > 100) {
                    return 'Age must be between 18-100';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown<String>(
                label: 'Gender',
                value: selectedGender,
                items: ['Woman', 'Man', 'Non-binary', 'Other'],
                onChanged: onGenderChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: headingColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: bioController,
          label: 'Bio',
          hint: 'Tell us about yourself...',
          maxLines: 4,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildWorkEducationSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work & Education',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: headingColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: jobController,
          label: 'Job Title',
          hint: 'Software Engineer',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: companyController,
          label: 'Company',
          hint: 'Google',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: schoolController,
          label: 'School',
          hint: 'Stanford University',
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final headingColor = isDark ? Colors.white : Colors.black87;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dating Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown<String>(
              label: 'Looking for',
              value: selectedPreference,
              items: ['Men', 'Women', 'Everyone'],
              onChanged: onPreferenceChanged,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInterestsSection() {
    final availableInterests = [
      'Photography', 'Travel', 'Music', 'Sports', 'Movies', 'Books',
      'Cooking', 'Art', 'Gaming', 'Fitness', 'Dancing', 'Nature',
      'Technology', 'Fashion', 'Food', 'Wine', 'Coffee', 'Hiking',
      'Beach', 'Mountains', 'Concerts', 'Museums', 'Theatre', 'Yoga',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select up to 10 interests',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableInterests.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && selectedInterests.length < 10) {
                  onInterestsChanged([...selectedInterests, interest]);
                } else if (!selected) {
                  onInterestsChanged(
                    selectedInterests.where((i) => i != interest).toList(),
                  );
                }
              },
              selectedColor: PulseColors.primary.withValues(alpha: 0.2),
              checkmarkColor: PulseColors.primary,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected ? PulseColors.primary : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required Function(T) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PulseColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
