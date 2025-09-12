import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Enhanced interests selector with search and categories
class InterestsSelector extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;
  final int maxInterests;
  final int minInterests;

  const InterestsSelector({
    super.key,
    required this.selectedInterests,
    required this.onInterestsChanged,
    this.maxInterests = 10,
    this.minInterests = 3,
  });

  @override
  State<InterestsSelector> createState() => _InterestsSelectorState();
}

class _InterestsSelectorState extends State<InterestsSelector>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedInterests = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedInterests = List.from(widget.selectedInterests);
    _tabController = TabController(length: _interestCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else if (_selectedInterests.length < widget.maxInterests) {
        _selectedInterests.add(interest);
      } else {
        _showMaxInterestsReachedDialog();
        return;
      }
    });
    widget.onInterestsChanged(_selectedInterests);
  }

  void _showMaxInterestsReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Interests Reached'),
        content: Text('You can select up to ${widget.maxInterests} interests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> _getFilteredInterests(List<String> interests) {
    if (_searchQuery.isEmpty) return interests;
    return interests
        .where((interest) =>
            interest.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Interests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedInterests.length}/${widget.maxInterests}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least ${widget.minInterests} interests that represent you',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search interests...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Selected interests (if any)
        if (_selectedInterests.isNotEmpty) ...[
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests.map((interest) {
              return _buildSelectedInterestChip(interest);
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Category tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: _interestCategories.map((category) {
              return Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(category.name),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Interests grid
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: _interestCategories.map((category) {
              final filteredInterests = _getFilteredInterests(category.interests);
              
              if (filteredInterests.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No interests found for "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3.5,
                ),
                itemCount: filteredInterests.length,
                itemBuilder: (context, index) {
                  final interest = filteredInterests[index];
                  final isSelected = _selectedInterests.contains(interest);
                  return _buildInterestChip(interest, isSelected);
                },
              );
            }).toList(),
          ),
        ),

        // Bottom info
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PulseColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: PulseColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your interests help us find better matches and show you to people with similar hobbies.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChip(String interest, bool isSelected) {
    return InkWell(
      onTap: () => _toggleInterest(interest),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PulseColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? PulseColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                interest,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PulseColors.primary, PulseColors.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            interest,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _toggleInterest(interest),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Interest categories data
class InterestCategory {
  final String name;
  final List<String> interests;

  const InterestCategory({
    required this.name,
    required this.interests,
  });
}

final List<InterestCategory> _interestCategories = [
  InterestCategory(
    name: 'Lifestyle',
    interests: [
      'Fitness', 'Yoga', 'Running', 'Hiking', 'Cycling', 'Swimming',
      'Dancing', 'Cooking', 'Baking', 'Gardening', 'Fashion', 'Beauty',
      'Wellness', 'Meditation', 'Mindfulness', 'Self-care', 'Nutrition',
    ],
  ),
  InterestCategory(
    name: 'Entertainment',
    interests: [
      'Movies', 'TV Shows', 'Netflix', 'Theater', 'Concerts', 'Festivals',
      'Comedy', 'Stand-up', 'Podcasts', 'YouTube', 'Streaming', 'Karaoke',
      'Board Games', 'Video Games', 'Esports', 'Anime', 'Comics',
    ],
  ),
  InterestCategory(
    name: 'Sports',
    interests: [
      'Football', 'Basketball', 'Soccer', 'Tennis', 'Baseball', 'Hockey',
      'Golf', 'Boxing', 'MMA', 'Wrestling', 'Volleyball', 'Badminton',
      'Table Tennis', 'Cricket', 'Rugby', 'Formula 1', 'Olympics',
    ],
  ),
  InterestCategory(
    name: 'Arts & Culture',
    interests: [
      'Music', 'Art', 'Photography', 'Writing', 'Poetry', 'Literature',
      'Museums', 'Galleries', 'Sculpture', 'Painting', 'Drawing',
      'Design', 'Architecture', 'History', 'Philosophy', 'Culture',
    ],
  ),
  InterestCategory(
    name: 'Technology',
    interests: [
      'Programming', 'AI', 'Machine Learning', 'Web Development',
      'Mobile Apps', 'Gaming', 'Crypto', 'Blockchain', 'Startups',
      'Tech News', 'Gadgets', 'Software', 'Hardware', 'Innovation',
    ],
  ),
  InterestCategory(
    name: 'Food & Drinks',
    interests: [
      'Coffee', 'Wine', 'Beer', 'Cocktails', 'Fine Dining', 'Street Food',
      'Vegan', 'Vegetarian', 'Sushi', 'Pizza', 'Burgers', 'Desserts',
      'Food Trucks', 'Farmers Markets', 'Craft Beer', 'Whiskey',
    ],
  ),
  InterestCategory(
    name: 'Travel',
    interests: [
      'Backpacking', 'Road Trips', 'City Breaks', 'Beach Holidays',
      'Mountain Adventures', 'Cultural Travel', 'Food Tourism',
      'Solo Travel', 'Group Travel', 'Luxury Travel', 'Budget Travel',
      'Photography Travel', 'Adventure Sports', 'Camping', 'Glamping',
    ],
  ),
  InterestCategory(
    name: 'Social',
    interests: [
      'Parties', 'Nightlife', 'Bars', 'Clubs', 'Social Events',
      'Networking', 'Meetups', 'Community Service', 'Volunteering',
      'Politics', 'Activism', 'Environmental Causes', 'Animal Rights',
      'Social Justice', 'Charity Work', 'Fundraising',
    ],
  ),
];
