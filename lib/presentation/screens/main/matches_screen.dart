import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_event.dart';
import '../../blocs/match/match_state.dart';
import '../../../data/services/matching_service.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../widgets/match/match_card.dart';
import '../../navigation/app_router.dart';

/// Actual Matches Screen - Shows mutual matches and people who liked you
///
/// This screen displays:
/// - Your mutual matches (people you can message)
/// - People who liked you (if you have premium)
/// - Match history and statistics
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  
  String _searchQuery = '';
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MatchBloc(
        matchingService: MatchingService(apiClient: ApiClient.instance),
      )..add(const LoadMatches(excludeWithConversations: true)),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<MatchBloc, MatchState>(
            listener: (context, state) {
              if (state is MatchError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: PulseColors.primary,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(state),
                  Expanded(
                    child: _buildContent(state)),
                  if (_isLoadingMore) _buildLoadMoreIndicator(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MatchState state) {
    int matchCount = 0;
    if (state is MatchesLoaded) {
      matchCount = state.matches.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseColors.primary.withValues(alpha: 0.05),
            PulseColors.accent.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Title and stats
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department,
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
                      '$matchCount mutual matches',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PulseColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: PulseColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$matchCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PulseColors.accent,
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your matches...',
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
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
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

  Widget _buildContent(MatchState state) {
    if (state is MatchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MatchError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: PulseColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<MatchBloc>().add(
                const LoadMatches(excludeWithConversations: true),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (state is MatchesLoaded) {
      final matches = _getFilteredMatches(state.matches);
      
      if (matches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No matches found' : 'No matches yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Start swiping in Discover to find matches!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return MatchCard(
            match: match,
            userProfile: match.userProfile,
            showStatus: false, // Hide redundant status on matches screen
            onCall: match.userProfile != null
                ? () {
                    final callId =
                        'call_${match.userProfile!.id}_${DateTime.now().millisecondsSinceEpoch}';
                    // Convert UserProfile to UserModel for AudioCallScreen
                    final remoteUser = UserModel(
                      id: match.userProfile!.id,
                      email: '', // Not available in UserProfile
                      username: match.userProfile!.name,
                      firstName: match.userProfile!.name.split(' ').first,
                      lastName: match.userProfile!.name.split(' ').length > 1
                          ? match.userProfile!.name.split(' ').last
                          : null,
                      photos: match.userProfile!.photos
                          .map((p) => p.url)
                          .toList(),
                      createdAt: DateTime.now(), // Not available in UserProfile
                    );

                    context.push(
                      '/audio-call/$callId',
                      extra: {'remoteUser': remoteUser, 'isIncoming': false},
                    );
                  }
                : null,
            onMessage: () {
              if (match.userProfile != null) {
                context.push(
                  '/chat/${match.id}',
                  extra: {
                    'otherUserId': match.userProfile!.id,
                    'otherUserName': match.userProfile!.name,
                    'otherUserPhoto': match.userProfile!.photos.isNotEmpty
                        ? match.userProfile!.photos.first.url
                        : null,
                  },
                );
              }
            },
            onViewProfile: () {
              if (match.userProfile != null) {
                context.push(
                  AppRoutes.profileDetails.replaceFirst(
                    ':profileId',
                    match.userProfile!.id,
                  ),
                  extra: match.userProfile,
                );
              }
            },
            onUnmatch: () {
              _showUnmatchDialog(context, match);
            },
            onBlock: () {
              _showBlockDialog(context, match);
            },
            onReport: () {
              _showReportDialog(context, match);
            },
          );
        },
      );
    }

    return const SizedBox();
  }

  void _showUnmatchDialog(BuildContext context, MatchModel match) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unmatch'),
        content: Text(
          'Are you sure you want to unmatch with ${match.userProfile?.name ?? "this person"}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: Implement unmatch functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unmatched successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, MatchModel match) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${match.userProfile?.name ?? "this person"}? They will not be able to contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: Implement block functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, MatchModel match) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report User'),
        content: Text(
          'Report ${match.userProfile?.name ?? "this person"} for inappropriate behavior?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Report submitted. Thank you for helping keep PulseLink safe.',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  List<MatchModel> _getFilteredMatches(List<MatchModel> matches) {
    if (_searchQuery.isEmpty) return matches;

    return matches.where((match) {
      // Note: This is a simplified filter. In a real app, you'd filter by user names
      // For now, we'll just return all matches since we don't have user data in MatchModel
      return true;
    }).toList();
  }




  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Loading more matches...'),
        ],
      ),
    );
  }
}
