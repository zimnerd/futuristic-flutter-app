import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_event.dart';
import '../../blocs/match/match_state.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/match/match_card.dart';

/// Screen displaying user's matches with filtering and management options
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MatchBloc _matchBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchBloc = context.read<MatchBloc>();

    // Load initial matches
    _loadMatches('matched');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMatches(String status) {
    _matchBloc.add(LoadMatches(status: status));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Matches',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => _onTabChanged(),
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.schedule),
              text: 'Pending',
            ),
            Tab(
              icon: Icon(Icons.all_inclusive),
              text: 'All',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
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

          return RefreshIndicator(
            onRefresh: () async => _loadMatches(status),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.matches.length,
              itemBuilder: (context, index) {
                final match = state.matches[index];
                return MatchCard(
                  match: match,
                  onTap: () => _onMatchTapped(match),
                  onAccept: status == 'pending' ? () => _acceptMatch(match.id) : null,
                  onReject: status == 'pending' ? () => _rejectMatch(match.id) : null,
                  onUnmatch: status == 'matched' ? () => _unmatchUser(match.id) : null,
                );
              },
            ),
          );
        }

        return _buildEmptyState(status);
      },
    );
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
    if (match.status == 'matched') {
      // Navigate to chat screen
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {
          'matchId': match.id,
          'otherUserId': _getOtherUserId(match),
        },
      );
    } else {
      // Show match details
      _showMatchDetails(match);
    }
  }

  void _acceptMatch(String matchId) {
    _matchBloc.add(AcceptMatch(matchId: matchId));
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Match accepted! You can now start chatting.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectMatch(String matchId) {
    _showRejectConfirmation(matchId);
  }

  void _unmatchUser(String matchId) {
    _showUnmatchConfirmation(matchId);
  }

  void _showRejectConfirmation(String matchId) {
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

  void _showUnmatchConfirmation(String matchId) {
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

  void _showMatchDetails(MatchModel match) {
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
                    if (match.matchReasons != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Why you matched:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...match.matchReasons!.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• ${entry.value}'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getOtherUserId(MatchModel match) {
    // Note: This would need the current user ID to determine the other user
    // For now, return a placeholder
    return match.user2Id; // This is simplified
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
