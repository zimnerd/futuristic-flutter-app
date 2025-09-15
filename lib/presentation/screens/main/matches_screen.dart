import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/pulse_colors.dart';
import '../../blocs/matching/matching_bloc.dart';
import '../../../domain/entities/user_profile.dart';

/// Enhanced matches screen with filters, search, view options and pagination
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

enum ViewMode { grid, list, slider }

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late AnimationController _matchAnimationController;
  late PageController _pageController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  
  int _currentIndex = 0;
  ViewMode _viewMode = ViewMode.grid;
  String _searchQuery = '';
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pageController = PageController();
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load matched profiles
    context.read<MatchingBloc>().add(const LoadPotentialMatches());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore) {
        _loadMoreMatches();
      }
    }
  }

  void _loadMoreMatches() {
    setState(() {
      _isLoadingMore = true;
    });
    
    // Load more matches
    context.read<MatchingBloc>().add(const LoadPotentialMatches());
    
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _matchAnimationController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MatchingBloc, MatchingState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: PulseColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header with search and filters
                _buildEnhancedHeader(state),

                // View mode toggle
                _buildViewModeToggle(),

                // Matches content based on view mode
                Expanded(
                  child: _buildMatchesContentByViewMode(state),
                ),

                // Load more indicator
                if (_isLoadingMore) _buildLoadMoreIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(MatchingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseColors.primary.withOpacity(0.05),
            PulseColors.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Title and stats row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: PulseColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Sparks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${state.profiles.length} mutual likes',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Connection insights
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PulseColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: PulseColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '92%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PulseColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your sparks...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.tune, color: PulseColors.primary),
                        onPressed: () => _showFiltersModal(),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'View:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          _buildViewModeButton(ViewMode.grid, Icons.grid_view),
          const SizedBox(width: 8),
          _buildViewModeButton(ViewMode.list, Icons.view_list),
          const SizedBox(width: 8),
          _buildViewModeButton(ViewMode.slider, Icons.view_carousel),
          const Spacer(),
          Text(
            'Showing ${_getFilteredProfiles().length} matches',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(ViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? PulseColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? PulseColors.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMatchesContentByViewMode(MatchingState state) {
    final filteredProfiles = _getFilteredProfiles();
    
    if (state.status == MatchingStatus.loading && filteredProfiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProfiles.isEmpty) {
      return _buildEmptyState();
    }

    switch (_viewMode) {
      case ViewMode.grid:
        return _buildGridView(filteredProfiles);
      case ViewMode.list:
        return _buildListView(filteredProfiles);
      case ViewMode.slider:
        return _buildSliderView(filteredProfiles);
    }
  }

  List<UserProfile> _getFilteredProfiles() {
    final profiles = context.read<MatchingBloc>().state.profiles;
    if (_searchQuery.isEmpty) return profiles;
    
    return profiles.where((profile) {
      final query = _searchQuery.toLowerCase();
      return profile.name.toLowerCase().contains(query) ||
             profile.bio.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildGridView(List<UserProfile> profiles) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) => _buildGridProfileCard(profiles[index]),
    );
  }

  Widget _buildListView(List<UserProfile> profiles) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      itemBuilder: (context, index) => _buildListProfileCard(profiles[index]),
    );
  }

  Widget _buildSliderView(List<UserProfile> profiles) {
    return Column(
      children: [
        // Slider indicators
        if (profiles.isNotEmpty) _buildPageIndicator(profiles.length),
        const SizedBox(height: 8),
        // Slider content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: profiles.length,
            itemBuilder: (context, index) => _buildSliderProfileCard(profiles[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildGridProfileCard(UserProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProfile(profile),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: profile.photos.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(profile.photos.first.url),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.photos.isEmpty
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.bio,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildListProfileCard(UserProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProfile(profile),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: profile.photos.isNotEmpty
                    ? CachedNetworkImageProvider(profile.photos.first.url)
                    : null,
                child: profile.photos.isEmpty
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PulseColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${profile.age}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: PulseColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _startChat(profile),
                    icon: const Icon(Icons.chat, color: PulseColors.primary),
                  ),
                  IconButton(
                    onPressed: () => _startCall(profile),
                    icon: const Icon(Icons.videocam, color: PulseColors.secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderProfileCard(UserProfile profile) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background image
            if (profile.photos.isNotEmpty)
              CachedNetworkImage(
                imageUrl: profile.photos.first.url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Content
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Age: ${profile.age}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startChat(profile),
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startCall(profile),
                          icon: const Icon(Icons.videocam),
                          label: const Text('Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages.clamp(0, 5), // Limit to 5 indicators
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex
                ? PulseColors.primary
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading more matches...'),
        ],
      ),
    );
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Age Range'),
            const SizedBox(height: 8),
            RangeSlider(
              values: const RangeValues(18, 35),
              min: 18,
              max: 65,
              divisions: 47,
              labels: const RangeLabels('18', '35'),
              onChanged: (values) {
                // Handle age range change
              },
            ),
            const SizedBox(height: 24),
            const Text('Distance'),
            const SizedBox(height: 8),
            Slider(
              value: 50,
              min: 1,
              max: 100,
              divisions: 99,
              label: '50 km',
              onChanged: (value) {
                // Handle distance change
              },
            ),
            const SizedBox(height: 24),
            const Text('Interests'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'Music', 'Sports', 'Travel', 'Food', 'Movies'
              ].map((interest) => FilterChip(
                label: Text(interest),
                selected: false,
                onSelected: (selected) {
                  // Handle interest selection
                },
              )).toList(),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Clear filters
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(UserProfile profile) {
    // Navigate to profile details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${profile.name}\'s profile')),
    );
  }

  void _startChat(UserProfile profile) {
    // Start chat with profile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with ${profile.name}')),
    );
  }

  void _startCall(UserProfile profile) {
    // Start video call with profile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting call with ${profile.name}')),
    );
  }
}