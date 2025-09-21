import 'package:flutter/material.dart';
import '../../../data/models/ai_companion.dart';
import '../../theme/pulse_colors.dart';

/// Widget for creating or editing AI companions
class CompanionCreationWidget extends StatefulWidget {
  final ScrollController? scrollController;
  final AICompanion? existingCompanion;
  final Function(
    String name,
    CompanionPersonality personality,
    CompanionAppearance appearance, {
    CompanionGender? gender,
    CompanionAge? ageGroup,
    String? description,
    List<String>? interests,
    Map<String, dynamic>? voiceSettings,
  })
  onCompanionCreated;

  const CompanionCreationWidget({
    super.key,
    this.scrollController,
    this.existingCompanion,
    required this.onCompanionCreated,
  });

  @override
  State<CompanionCreationWidget> createState() => _CompanionCreationWidgetState();
}

class _CompanionCreationWidgetState extends State<CompanionCreationWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _interestsController = TextEditingController();
  
  CompanionPersonality _selectedPersonality = CompanionPersonality.mentor;
  CompanionGender? _selectedGender;
  CompanionAge? _selectedAgeGroup;
  String _selectedAvatarStyle = 'realistic';
  String _selectedVoiceType = 'warm';
  String _selectedSpeechSpeed = 'normal';
  
  final String _selectedHairColor = 'brown';
  final String _selectedEyeColor = 'brown';
  
  final List<Map<String, dynamic>> _avatarStyles = [
    {'value': 'realistic', 'label': 'Realistic', 'icon': Icons.person},
    {'value': 'cartoon', 'label': 'Cartoon', 'icon': Icons.emoji_emotions},
    {'value': 'anime', 'label': 'Anime', 'icon': Icons.face},
    {'value': 'minimalist', 'label': 'Minimalist', 'icon': Icons.circle},
  ];

  final List<Map<String, dynamic>> _voiceTypes = [
    {'value': 'warm', 'label': 'Warm', 'description': 'Friendly and caring'},
    {
      'value': 'professional',
      'label': 'Professional',
      'description': 'Clear and confident',
    },
    {'value': 'casual', 'label': 'Casual', 'description': 'Relaxed and fun'},
    {
      'value': 'energetic',
      'label': 'Energetic',
      'description': 'Upbeat and motivating',
    },
  ];

  final List<Map<String, dynamic>> _speechSpeeds = [
    {'value': 'slow', 'label': 'Slow', 'description': 'Thoughtful pace'},
    {'value': 'normal', 'label': 'Normal', 'description': 'Natural pace'},
    {'value': 'fast', 'label': 'Fast', 'description': 'Quick and dynamic'},
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.existingCompanion != null) {
      _nameController.text = widget.existingCompanion!.name;
      _selectedPersonality = widget.existingCompanion!.personality;
      _selectedGender = widget.existingCompanion!.gender;
      _selectedAgeGroup = widget.existingCompanion!.ageGroup;
      _descriptionController.text = widget.existingCompanion!.description;
      _interestsController.text = widget.existingCompanion!.interests.join(
        ', ',
      );
      _selectedVoiceType =
          widget.existingCompanion!.voiceSettings['voiceType'] ?? 'warm';
      _selectedSpeechSpeed =
          widget.existingCompanion!.voiceSettings['speechSpeed'] ?? 'normal';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Constrain height
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create AI Companion',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Companion Name',
                        hintText: 'Give your companion a name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText:
                            'Describe your companion\'s personality traits',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gender Selection
                    const Text(
                      'Choose Gender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGenderSelection(),
                    const SizedBox(height: 24),

                    // Age Group Selection
                    const Text(
                      'Choose Age Group',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAgeGroupSelection(),
                    const SizedBox(height: 24),

                    // Personality Selection
                    const Text(
                      'Choose Personality Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPersonalityGrid(),
                    const SizedBox(height: 24),

                    // Appearance Selection
                    const Text(
                      'Choose Avatar Style',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAvatarStyleGrid(),
                    const SizedBox(height: 24),

                    // Interests Field
                    TextFormField(
                      controller: _interestsController,
                      decoration: const InputDecoration(
                        labelText: 'Interests (Optional)',
                        hintText:
                            'e.g. dating, relationships, self-improvement (separate with commas)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Voice Settings
                    const Text(
                      'Voice Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildVoiceSettings(),
                    const SizedBox(height: 32),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createCompanion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.existingCompanion != null
                              ? 'Update Companion'
                              : 'Create Companion',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Make cards taller to fit content
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: CompanionPersonality.values.length,
      itemBuilder: (context, index) {
        final personality = CompanionPersonality.values[index];
        final isSelected = personality == _selectedPersonality;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPersonality = personality;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                ? PulseColors.primary.withValues(alpha: 0.1)
                : Colors.grey[100],
              border: Border.all(
                color: isSelected 
                  ? PulseColors.primary
                  : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  personality.emoji,
                  style: const TextStyle(
                    fontSize: 24,
                  ), // Slightly smaller emoji
                ),
                const SizedBox(height: 6),
                Text(
                  personality.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? PulseColors.primary : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Remove Expanded to prevent overflow, use Flexible instead
                Flexible(
                  child: Text(
                    personality.description,
                    style: TextStyle(
                      fontSize: 9, // Smaller font for description
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarStyleGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _avatarStyles.length,
      itemBuilder: (context, index) {
        final style = _avatarStyles[index];
        final isSelected = style['value'] == _selectedAvatarStyle;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatarStyle = style['value'];
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                ? PulseColors.secondary.withValues(alpha: 0.1)
                : Colors.grey[100],
              border: Border.all(
                color: isSelected 
                  ? PulseColors.secondary
                  : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  style['icon'],
                  size: 32,
                  color: isSelected ? PulseColors.secondary : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  style['label'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? PulseColors.secondary : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createCompanion() {
    if (_formKey.currentState!.validate()) {
      final appearance = CompanionAppearance(
        avatarStyle: _selectedAvatarStyle,
        hairColor: _selectedHairColor,
        eyeColor: _selectedEyeColor,
      );
      
      final interests = _interestsController.text.trim().isNotEmpty
          ? _interestsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];

      final voiceSettings = <String, dynamic>{
        'voiceType': _selectedVoiceType,
        'speechSpeed': _selectedSpeechSpeed,
      };
      
      widget.onCompanionCreated(
        _nameController.text.trim(),
        _selectedPersonality,
        appearance,
        gender: _selectedGender,
        ageGroup: _selectedAgeGroup,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        interests: interests.isNotEmpty ? interests : null,
        voiceSettings: voiceSettings,
      );
    }
  }

  Widget _buildGenderSelection() {
    return Row(
      children: CompanionGender.values.map((gender) {
        final isSelected = gender == _selectedGender;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = gender;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PulseColors.primary.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  border: Border.all(
                    color: isSelected ? PulseColors.primary : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(gender.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      gender.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? PulseColors.primary
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeGroupSelection() {
    return Column(
      children: CompanionAge.values.map((age) {
        final isSelected = age == _selectedAgeGroup;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedAgeGroup = age;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? PulseColors.secondary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                border: Border.all(
                  color: isSelected ? PulseColors.secondary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(age.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    age.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? PulseColors.secondary
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVoiceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Type Selection
        const Text(
          'Voice Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _voiceTypes.map((voice) {
            final isSelected = voice['value'] == _selectedVoiceType;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVoiceType = voice['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PulseColors.secondary.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  border: Border.all(
                    color: isSelected
                        ? PulseColors.secondary
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  voice['label'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? PulseColors.secondary : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Speech Speed Selection
        const Text(
          'Speech Speed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _speechSpeeds.map((speed) {
            final isSelected = speed['value'] == _selectedSpeechSpeed;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSpeechSpeed = speed['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PulseColors.success.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  border: Border.all(
                    color: isSelected ? PulseColors.success : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  speed['label'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? PulseColors.success : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
