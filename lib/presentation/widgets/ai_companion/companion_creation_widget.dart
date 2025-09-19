import 'package:flutter/material.dart';
import '../../../data/models/ai_companion.dart';
import '../../theme/pulse_colors.dart';

/// Widget for creating or editing AI companions
class CompanionCreationWidget extends StatefulWidget {
  final ScrollController? scrollController;
  final AICompanion? existingCompanion;
  final Function(String name, CompanionPersonality personality, CompanionAppearance appearance) onCompanionCreated;

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
  CompanionPersonality _selectedPersonality = CompanionPersonality.mentor;
  String _selectedAvatarStyle = 'realistic';
  final String _selectedHairColor = 'brown';
  final String _selectedEyeColor = 'brown';
  
  final List<Map<String, dynamic>> _avatarStyles = [
    {'value': 'realistic', 'label': 'Realistic', 'icon': Icons.person},
    {'value': 'cartoon', 'label': 'Cartoon', 'icon': Icons.emoji_emotions},
    {'value': 'anime', 'label': 'Anime', 'icon': Icons.face},
    {'value': 'minimalist', 'label': 'Minimalist', 'icon': Icons.circle},
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.existingCompanion != null) {
      _nameController.text = widget.existingCompanion!.name;
      _selectedPersonality = widget.existingCompanion!.personality;
      // Set appearance from existing companion if available
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        childAspectRatio: 1.2,
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
            padding: const EdgeInsets.all(16),
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
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  personality.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? PulseColors.primary : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  personality.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
      
      widget.onCompanionCreated(
        _nameController.text.trim(),
        _selectedPersonality,
        appearance,
      );
    }
  }
}
