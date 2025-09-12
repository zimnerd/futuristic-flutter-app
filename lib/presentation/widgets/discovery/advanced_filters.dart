import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import '../common/pulse_button.dart';

/// Advanced filters for enhanced discovery
class AdvancedFilters extends StatefulWidget {
  const AdvancedFilters({
    super.key,
    this.onApplyFilters,
    this.onResetFilters,
  });

  final Function(Map<String, dynamic>)? onApplyFilters;
  final VoidCallback? onResetFilters;

  @override
  State<AdvancedFilters> createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<AdvancedFilters>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter values
  RangeValues _ageRange = const RangeValues(18, 65);
  double _distance = 50.0;
  final List<String> _selectedInterests = [];
  String? _selectedEducation;
  String? _selectedOccupation;
  RangeValues? _heightRange;
  String? _selectedZodiacSign;
  final List<String> _selectedLifestyleChoices = [];
  bool _verifiedOnly = false;
  bool _activeRecentlyOnly = false;

  final List<String> _availableInterests = [
    'Music', 'Travel', 'Sports', 'Movies', 'Books', 'Cooking',
    'Art', 'Photography', 'Gaming', 'Fitness', 'Dancing', 'Hiking',
    'Technology', 'Fashion', 'Wine', 'Coffee', 'Yoga', 'Meditation',
  ];

  final List<String> _educationLevels = [
    'High School', 'Some College', "Bachelor's Degree", "Master's Degree",
    'PhD', 'Trade School', 'Other'
  ];

  final List<String> _occupationTypes = [
    'Technology', 'Healthcare', 'Finance', 'Education', 'Creative',
    'Business', 'Legal', 'Science', 'Engineering', 'Sales', 'Other'
  ];

  final List<String> _zodiacSigns = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  final List<String> _lifestyleOptions = [
    'Non-smoker', 'Occasional drinker', 'Non-drinker', 'Vegetarian',
    'Vegan', 'Fitness enthusiast', 'Pet lover', 'Traveler'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetAllFilters,
                  child: const Text(
                    'Reset All',
                    style: TextStyle(color: PulseColors.primary),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: PulseColors.primary,
            labelColor: PulseColors.primary,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(text: 'Basic'),
              Tab(text: 'Interests'),
              Tab(text: 'Background'),
              Tab(text: 'Lifestyle'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicFilters(),
                _buildInterestsFilters(),
                _buildBackgroundFilters(),
                _buildLifestyleFilters(),
              ],
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: PulseButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age range
          _buildSectionHeader('Age Range'),
          _buildAgeRangeSlider(),
          
          const SizedBox(height: 24),
          
          // Distance
          _buildSectionHeader('Distance'),
          _buildDistanceSlider(),
          
          const SizedBox(height: 24),
          
          // Height range
          _buildSectionHeader('Height Range (Optional)'),
          _buildHeightRangeSlider(),
          
          const SizedBox(height: 24),
          
          // Quick filters
          _buildSectionHeader('Quick Filters'),
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildInterestsFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Select Interests'),
          const SizedBox(height: 8),
          Text(
            'Choose interests you\'d like to match with',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildInterestsGrid(),
        ],
      ),
    );
  }

  Widget _buildBackgroundFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Education
          _buildSectionHeader('Education'),
          _buildEducationDropdown(),
          
          const SizedBox(height: 24),
          
          // Occupation
          _buildSectionHeader('Occupation Type'),
          _buildOccupationDropdown(),
          
          const SizedBox(height: 24),
          
          // Zodiac sign
          _buildSectionHeader('Zodiac Sign (Optional)'),
          _buildZodiacDropdown(),
        ],
      ),
    );
  }

  Widget _buildLifestyleFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Lifestyle Preferences'),
          const SizedBox(height: 8),
          Text(
            'Select lifestyle choices that matter to you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildLifestyleGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 80,
          divisions: 62,
          activeColor: PulseColors.primary,
          inactiveColor: PulseColors.primary.withValues(alpha: 0.3),
          labels: RangeLabels(
            _ageRange.start.round().toString(),
            _ageRange.end.round().toString(),
          ),
          onChanged: (values) {
            setState(() {
              _ageRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_ageRange.start.round()} years'),
            Text('${_ageRange.end.round()} years'),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      children: [
        Slider(
          value: _distance,
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: PulseColors.primary,
          inactiveColor: PulseColors.primary.withValues(alpha: 0.3),
          label: '${_distance.round()} km',
          onChanged: (value) {
            setState(() {
              _distance = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('1 km'),
            Text('${_distance.round()} km'),
            const Text('100+ km'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeightRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _heightRange ?? const RangeValues(150, 200),
          min: 140,
          max: 220,
          divisions: 80,
          activeColor: PulseColors.primary,
          inactiveColor: PulseColors.primary.withValues(alpha: 0.3),
          labels: _heightRange != null
              ? RangeLabels(
                  '${_heightRange!.start.round()} cm',
                  '${_heightRange!.end.round()} cm',
                )
              : null,
          onChanged: (values) {
            setState(() {
              _heightRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(_heightRange?.start ?? 150).round()} cm'),
            Text('${(_heightRange?.end ?? 200).round()} cm'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Verified profiles only'),
          subtitle: const Text('Show only verified users'),
          value: _verifiedOnly,
          activeColor: PulseColors.primary,
          onChanged: (value) {
            setState(() {
              _verifiedOnly = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Active recently'),
          subtitle: const Text('Show users active in the last 7 days'),
          value: _activeRecentlyOnly,
          activeColor: PulseColors.primary,
          onChanged: (value) {
            setState(() {
              _activeRecentlyOnly = value ?? false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          selectedColor: PulseColors.primary.withValues(alpha: 0.2),
          checkmarkColor: PulseColors.primary,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(interest);
              } else {
                _selectedInterests.remove(interest);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEducationDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedEducation,
      hint: const Text('Select education level'),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: _educationLevels.map((education) {
        return DropdownMenuItem(
          value: education,
          child: Text(education),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedEducation = value;
        });
      },
    );
  }

  Widget _buildOccupationDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedOccupation,
      hint: const Text('Select occupation type'),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: _occupationTypes.map((occupation) {
        return DropdownMenuItem(
          value: occupation,
          child: Text(occupation),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOccupation = value;
        });
      },
    );
  }

  Widget _buildZodiacDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedZodiacSign,
      hint: const Text('Select zodiac sign'),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: _zodiacSigns.map((sign) {
        return DropdownMenuItem(
          value: sign,
          child: Text(sign),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedZodiacSign = value;
        });
      },
    );
  }

  Widget _buildLifestyleGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _lifestyleOptions.map((option) {
        final isSelected = _selectedLifestyleChoices.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: PulseColors.primary.withValues(alpha: 0.2),
          checkmarkColor: PulseColors.primary,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedLifestyleChoices.add(option);
              } else {
                _selectedLifestyleChoices.remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _resetAllFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 65);
      _distance = 50.0;
      _selectedInterests.clear();
      _selectedEducation = null;
      _selectedOccupation = null;
      _heightRange = null;
      _selectedZodiacSign = null;
      _selectedLifestyleChoices.clear();
      _verifiedOnly = false;
      _activeRecentlyOnly = false;
    });
    widget.onResetFilters?.call();
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'ageRange': {'min': _ageRange.start, 'max': _ageRange.end},
      'distance': _distance,
      'interests': _selectedInterests,
      'education': _selectedEducation,
      'occupation': _selectedOccupation,
      'heightRange': _heightRange != null 
          ? {'min': _heightRange!.start, 'max': _heightRange!.end}
          : null,
      'zodiacSign': _selectedZodiacSign,
      'lifestyle': _selectedLifestyleChoices,
      'verifiedOnly': _verifiedOnly,
      'activeRecentlyOnly': _activeRecentlyOnly,
    };
    
    widget.onApplyFilters?.call(filters);
    Navigator.pop(context);
  }
}
