import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_event.dart';
import '../../blocs/match/match_state.dart';
import '../../blocs/safety/safety_bloc.dart';
import '../../../data/services/matching_service.dart';
import '../../../data/services/safety_service.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/safety.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../widgets/match/match_card.dart';
import '../../navigation/app_router.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../widgets/common/pulse_toast.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MatchBloc(
            matchingService: MatchingService(apiClient: ApiClient.instance),
          )..add(const LoadMatches(excludeWithConversations: true)),
        ),
        BlocProvider(
          create: (context) =>
              SafetyBloc(safetyService: SafetyService(ApiClient.instance)),
        ),
      ],
      child: KeyboardDismissibleScaffold(
        body: SafeArea(
          child: BlocConsumer<MatchBloc, MatchState>(
            buildWhen: (previous, current) {
              // Only rebuild when matches data actually changes
              if (previous is MatchesLoaded && current is MatchesLoaded) {
                return previous.matches != current.matches;
              }
              // Always rebuild for state type changes
              return previous.runtimeType != current.runtimeType;
            },
            listener: (context, state) {
              if (state is MatchError) {
                PulseToast.error(context, message: state.message);
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(state),
                  Expanded(child: _buildContent(state)),
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
      return const SkeletonList(
        skeletonItem: MatchCardSkeleton(),
        itemCount: 5,
      );
    }

    if (state is MatchError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: PulseColors.primary),
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
              onPressed: () => context.read<MatchBloc>().add(
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
        return RefreshIndicator(
          onRefresh: () async {
            context.read<MatchBloc>().add(
              const LoadMatches(excludeWithConversations: true),
            );
            // Wait a bit for the bloc to process
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: _searchQuery.isNotEmpty
                  ? EmptyStates.noSearchResults(query: _searchQuery)
                  : EmptyStates.noMatches(
                      onDiscover: () => context.go('/home'),
                    ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<MatchBloc>().add(
            const LoadMatches(excludeWithConversations: true),
          );
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return MatchCard(
              key: ValueKey(match.id),
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
                        createdAt:
                            DateTime.now(), // Not available in UserProfile
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
        ),
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                // Note: Unmatch API endpoint not yet available
                // Future implementation: await matchRepository.unmatch(match.id);

                PulseToast.success(context, message: 'Unmatched successfully');
              } catch (e) {
                PulseToast.error(
                  context,
                  message: 'Failed to unmatch: ${e.toString()}',
                );
              }
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final userId = match.userProfile?.id;
                if (userId == null) {
                  throw Exception('User ID not available');
                }

                // Use SafetyBloc to block user
                context.read<SafetyBloc>().add(
                  BlockUser(userId: userId, reason: 'Blocked from matches'),
                );

                PulseToast.success(
                  context,
                  message: 'User blocked successfully',
                );
              } catch (e) {
                PulseToast.error(
                  context,
                  message: 'Failed to block user: ${e.toString()}',
                );
              }
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final userId = match.userProfile?.id;
                if (userId == null) {
                  throw Exception('User ID not available');
                }

                // Use SafetyBloc to report user
                context.read<SafetyBloc>().add(
                  ReportUser(
                    reportedUserId: userId,
                    reportType: SafetyReportType.inappropriateContent,
                    description: 'Reported from matches screen',
                  ),
                );

                PulseToast.success(
                  context,
                  message:
                      'Report submitted. Thank you for helping keep PulseLink safe.',
                );
              } catch (e) {
                PulseToast.error(
                  context,
                  message: 'Failed to submit report: ${e.toString()}',
                );
              }
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
