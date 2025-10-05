import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/logger.dart';

import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_event.dart';
import '../../blocs/match/match_state.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/match/match_card.dart';
import '../../navigation/app_router.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../profile/profile_details_screen.dart';

/// Enhanced match view modes
enum MatchViewMode { list, grid, slider }

/// Enhanced sorting options
enum MatchSortBy { recent, compatibility, name, distance }

/// Screen displaying user's matches with enhanced filtering, sorting and view modes
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MatchBloc _matchBloc;
  
  // Enhanced state variables
  MatchViewMode _currentViewMode = MatchViewMode.list;
  MatchSortBy _currentSortBy = MatchSortBy.recent;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _pageSize = 10;
  
  // Search functionality
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<MatchModel> _filteredMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchBloc = context.read<MatchBloc>();

    // Set up scroll controller for pagination
    _scrollController.addListener(_onScroll);

    // Load initial matches
    _loadMatches('matched');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted && 
        _scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMatches();
    }
  }

  void _loadMoreMatches() {
    if (!_isLoadingMore && mounted) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      final String status;
      switch (_tabController.index) {
        case 0:
          status = 'matched';
          break;
        case 1:
          status = 'pending';
          break;
        case 2:
          status = 'all';
          break;
        default:
          status = 'matched';
      }

      // Load more matches with pagination using offset
      _matchBloc.add(
        LoadMatches(
          status: status,
          limit: _pageSize,
          offset: (_currentPage - 1) * _pageSize,
          excludeWithConversations: true,
        ),
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMatches(String status) {
    if (mounted) {
      setState(() {
        _currentPage = 1;
      });
    }
    _matchBloc.add(
      LoadMatches(
        status: status,
        limit: _pageSize,
        offset: 0,
        excludeWithConversations: true,
      ),
    );
  }

  void _onTabChanged() {
    final String status;
    switch (_tabController.index) {
      case 0:
        status = 'matched';
        break;
      case 1:
        status = 'pending';
        break;
      case 2:
        status = 'all';
        break;
      default:
        status = 'matched';
    }
    _loadMatches(status);
  }

  IconData _getViewModeIcon() {
    switch (_currentViewMode) {
      case MatchViewMode.list:
        return Icons.list;
      case MatchViewMode.grid:
        return Icons.grid_view;
      case MatchViewMode.slider:
        return Icons.view_carousel;
    }
  }

  void _applySorting() {
    // Trigger a refresh with the new sorting
    final String status;
    switch (_tabController.index) {
      case 0:
        status = 'matched';
        break;
      case 1:
        status = 'pending';
        break;
      case 2:
        status = 'all';
        break;
      default:
        status = 'matched';
    }
    _loadMatches(status);
  }

  AppBar _buildMainAppBar() {
    return AppBar(
      title: const Text(
        'My Matches',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearchActive = true;
            });
          },
        ),
        // View mode toggle
        PopupMenuButton<MatchViewMode>(
          icon: Icon(_getViewModeIcon()),
          onSelected: (MatchViewMode mode) {
            if (mounted) {
              setState(() {
                _currentViewMode = mode;
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: MatchViewMode.list,
              child: Row(
                children: [
                  Icon(Icons.list),
                  SizedBox(width: 8),
                  Text('List View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MatchViewMode.grid,
              child: Row(
                children: [
                  Icon(Icons.grid_view),
                  SizedBox(width: 8),
                  Text('Grid View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MatchViewMode.slider,
              child: Row(
                children: [
                  Icon(Icons.view_carousel),
                  SizedBox(width: 8),
                  Text('Slider View'),
                ],
              ),
            ),
          ],
        ),
        // Sort options
        PopupMenuButton<MatchSortBy>(
          icon: const Icon(Icons.sort),
          onSelected: (MatchSortBy sortBy) {
            if (mounted) {
              setState(() {
                _currentSortBy = sortBy;
              });
            }
            _applySorting();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: MatchSortBy.recent,
              child: Row(
                children: [
                  Icon(Icons.access_time),
                  SizedBox(width: 8),
                  Text('Most Recent'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MatchSortBy.compatibility,
              child: Row(
                children: [
                  Icon(Icons.favorite),
                  SizedBox(width: 8),
                  Text('Compatibility'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MatchSortBy.name,
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha),
                  SizedBox(width: 8),
                  Text('Name A-Z'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: MatchSortBy.distance,
              child: Row(
                children: [
                  Icon(Icons.location_on),
                  SizedBox(width: 8),
                  Text('Distance'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        onTap: (_) => _onTabChanged(),
        tabs: const [
          Tab(icon: Icon(Icons.favorite), text: 'Active'),
          Tab(icon: Icon(Icons.schedule), text: 'Pending'),
          Tab(icon: Icon(Icons.all_inclusive), text: 'All'),
        ],
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearchActive = false;
            _searchController.clear();
            _searchQuery = '';
            _filterMatches();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search by match ID, status, compatibility...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterMatches();
        },
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
              _filterMatches();
            },
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        onTap: (_) => _onTabChanged(),
        tabs: const [
          Tab(icon: Icon(Icons.favorite), text: 'Active'),
          Tab(icon: Icon(Icons.schedule), text: 'Pending'),
          Tab(icon: Icon(Icons.all_inclusive), text: 'All'),
        ],
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
    );
  }

  void _filterMatches() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredMatches = [];
      });
      return;
    }

    final state = _matchBloc.state;
    if (state is MatchesLoaded) {
      final matches = state.matches;

      setState(() {
        _filteredMatches = matches.where((match) {
          final query = _searchQuery.toLowerCase();
          final matchId = match.id.toLowerCase();
          final status = match.status.toLowerCase();
          final compatibility = (match.compatibilityScore * 100)
              .round()
              .toString();

          return matchId.contains(query) ||
              status.contains(query) ||
              compatibility.contains(query);
        }).toList();
      });
    }
  }

  Widget _buildSearchNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
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
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      appBar: _isSearchActive ? _buildSearchAppBar() : _buildMainAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchesList('matched'),
          _buildMatchesList('pending'),
          _buildMatchesList('all'),
        ],
      ),
    );
  }

  Widget _buildMatchesList(String status) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state is MatchLoading) {
          return const Center(
            child: LoadingIndicator(message: 'Loading matches...'),
          );
        }

        if (state is MatchError) {
          return Center(
            child: ErrorMessage(
              message: state.message,
              onRetry: () => _loadMatches(status),
            ),
          );
        }

        if (state is MatchesLoaded) {
          if (state.matches.isEmpty) {
            return _buildEmptyState(status);
          }

          // Show search results or no results found when searching
          final displayMatches = _isSearchActive && _filteredMatches.isNotEmpty
              ? _filteredMatches
              : (_isSearchActive ? <MatchModel>[] : state.matches);

          if (_isSearchActive &&
              _filteredMatches.isEmpty &&
              _searchQuery.isNotEmpty) {
            return _buildSearchNoResults();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadMatches(status),
            child: Column(
              children: [
                Expanded(child: _buildMatchesView(displayMatches, status)),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        }

        return _buildEmptyState(status);
      },
    );
  }

  Widget _buildMatchesView(List<MatchModel> matches, String status) {
    // Apply sorting based on current sort option
    final sortedMatches = _sortMatches(matches);

    switch (_currentViewMode) {
      case MatchViewMode.list:
        return _buildListView(sortedMatches, status);
      case MatchViewMode.grid:
        return _buildGridView(sortedMatches, status);
      case MatchViewMode.slider:
        return _buildSliderView(sortedMatches, status);
    }
  }

  List<MatchModel> _sortMatches(List<MatchModel> matches) {
    final sortedList = List<MatchModel>.from(matches);

    switch (_currentSortBy) {
      case MatchSortBy.recent:
        sortedList.sort(
          (a, b) => (b.matchedAt ?? DateTime(1970)).compareTo(
            a.matchedAt ?? DateTime(1970),
          ),
        );
        break;
      case MatchSortBy.compatibility:
        sortedList.sort(
          (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
        );
        break;
      case MatchSortBy.name:
        sortedList.sort(
          (a, b) => a.user1Id.compareTo(b.user1Id),
        ); // Placeholder - would use actual name
        break;
      case MatchSortBy.distance:
        // Placeholder sorting - would use actual distance calculation
        sortedList.sort((a, b) => a.id.compareTo(b.id));
        break;
    }

    return sortedList;
  }

  Widget _buildListView(List<MatchModel> matches, String status) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return MatchCard(
          match: match,
          userProfile: match.userProfile,
          onTap: () => _onMatchTapped(match),
          onAccept: status == 'pending' ? () => _acceptMatch(match.id) : null,
          onReject: status == 'pending' ? () => _rejectMatch(match.id) : null,
          onUnmatch: status == 'matched' ? () => _unmatchUser(match.id) : null,
        );
      },
    );
  }

  Widget _buildGridView(List<MatchModel> matches, String status) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildGridMatchCard(match, status);
      },
    );
  }

  Widget _buildSliderView(List<MatchModel> matches, String status) {
    return PageView.builder(
      controller: PageController(viewportFraction: 0.85),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Container(
          margin: const EdgeInsets.all(16),
          child: _buildSliderMatchCard(match, status),
        );
      },
    );
  }

  Widget _buildGridMatchCard(MatchModel match, String status) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onMatchTapped(match),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${match.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(match.compatibilityScore * 100).round()}% match',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    _buildGridActionButtons(match, status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderMatchCard(MatchModel match, String status) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _onMatchTapped(match),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'User ${match.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(match.compatibilityScore * 100).round()}% compatibility',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const Spacer(),
                    _buildSliderActionButtons(match, status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridActionButtons(MatchModel match, String status) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptMatch(match.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rejectMatch(match.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSliderActionButtons(MatchModel match, String status) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptMatch(match.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(0, 40),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _rejectMatch(match.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(0, 40),
              ),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'matched') {
      return ElevatedButton.icon(
        onPressed: () => _onMatchTapped(match),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          minimumSize: const Size(double.infinity, 40),
        ),
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text('Message', style: TextStyle(color: Colors.white)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(String status) {
    final String title;
    final String subtitle;
    final IconData icon;

    switch (status) {
      case 'matched':
        title = 'No Active Matches';
        subtitle = 'Start swiping to find your perfect match!';
        icon = Icons.favorite_border;
        break;
      case 'pending':
        title = 'No Pending Matches';
        subtitle = 'People you like will appear here when they like you back.';
        icon = Icons.schedule;
        break;
      default:
        title = 'No Matches Yet';
        subtitle = 'Get started by exploring potential matches.';
        icon = Icons.search;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/discovery'),
            icon: const Icon(Icons.explore),
            label: const Text('Start Exploring'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMatchTapped(MatchModel match) {
    AppLogger.debug(
      '🎯 Match tapped: ${match.id}, userProfile: ${match.userProfile?.name}, status: ${match.status}',
    );
    
    if (match.userProfile != null && mounted) {
      AppLogger.debug(
        '📱 Showing profile modal for: ${match.userProfile!.name}',
      );
      _showProfileModal(match);
    } else {
      AppLogger.debug('ℹ️ Showing match details for: ${match.id}');
      // Show match details
      _showMatchDetails(match);
    }
  }

  void _acceptMatch(String matchId) {
    _matchBloc.add(AcceptMatch(matchId: matchId));
    
    // Show success message only if widget is still mounted
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match accepted! You can now start chatting.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _rejectMatch(String matchId) {
    _showRejectConfirmation(matchId);
  }

  void _unmatchUser(String matchId) {
    _showUnmatchConfirmation(matchId);
  }

  void _showRejectConfirmation(String matchId) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Match?'),
          content: const Text(
            'Are you sure you want to reject this match? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _matchBloc.add(RejectMatch(matchId: matchId));
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
    }
  }

  void _showUnmatchConfirmation(String matchId) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unmatch User?'),
          content: const Text(
            'Are you sure you want to unmatch this user? This will remove the match and end your conversation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _matchBloc.add(UnmatchUser(matchId: matchId));
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Unmatch'),
            ),
          ],
        ),
      );
    }
  }

  void _showProfileModal(MatchModel match) {
    if (mounted && match.userProfile != null) {
      context.push(
        AppRoutes.profileDetails.replaceFirst(':profileId', match.userProfile!.id),
        extra: {
          'profile': match.userProfile!,
          'context': ProfileContext.matches,
        },
      );
    }
  }

  void _showMatchDetails(MatchModel match) {
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildMatchDetailRow('Status', match.status.toUpperCase()),
                      _buildMatchDetailRow('Compatibility', '${(match.compatibilityScore * 100).round()}%'),
                      _buildMatchDetailRow('Matched At', _formatDate(match.matchedAt)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMatchDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
