import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/messaging/message_filters.dart';
import '../../widgets/messaging/message_search.dart';
import '../../widgets/messaging/match_stories_section.dart';
import '../../../data/services/conversation_service.dart';
import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_event.dart';
import '../../blocs/match/match_state.dart';
import '../../../blocs/chat_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

/// Enhanced messages screen with conversations list
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ConversationService _conversationService = ConversationService();
  MessageFilters _currentFilters = const MessageFilters();
  List<ConversationData> _allConversations = [];
  List<ConversationData> _filteredConversations = [];
  final Map<String, MatchStoryData> _enrichedMatches =
      {}; // Cache enriched matches by match ID
  Map<String, dynamic>?
  _pendingMatchNavigation; // Store match data for navigation after conversation creation
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadMatchStories();
  }

  /// Load conversations from backend API
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await _conversationService.getUserConversations();
      
      // Convert backend Conversation models to UI ConversationData
      final conversationDataList = conversations.map((conversation) {
        // Get the other participant (assuming 1-on-1 conversations)
        final otherParticipant = conversation.participants.firstWhere(
          (participant) => participant.id != conversation.id, // This needs proper user ID comparison
          orElse: () => conversation.participants.first,
        );

        return ConversationData(
          id: conversation.id,
          name: otherParticipant.displayName ?? otherParticipant.username ?? 'Unknown',
          avatar: otherParticipant.profileImageUrl ?? '',
          lastMessage: conversation.lastMessage?.content ?? 'No messages yet',
          timestamp: _formatTimestamp(conversation.lastActivity ?? conversation.updatedAt),
          unreadCount: conversation.unreadCount,
          isOnline: false, // We'd need real-time status for this
          type: MessageFilterType.all, // Default type, could be enhanced
        );
      }).toList();

      setState(() {
        _allConversations = conversationDataList;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversations: $e';
        _isLoading = false;
      });
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return '1d ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Load match stories for users that haven't been chatted with yet
  Future<void> _loadMatchStories() async {
    // Use MatchBloc to load real matches without existing conversations
    context.read<MatchBloc>().add(
      const LoadMatches(
        status: 'accepted', // Load accepted matches (mutual matches)
        limit: 20,
        offset: 0,
        excludeWithConversations: true, // Exclude matches with existing conversations
      ),
    );
  }

  /// Load more matches for pagination
  void _loadMoreMatches() {
    final currentState = context.read<MatchBloc>().state;
    if (currentState is MatchesLoaded && currentState.hasMore) {
      // Load more matches with offset, excluding those with conversations
      context.read<MatchBloc>().add(
        LoadMatches(
          status: 'accepted',
          limit: 20,
          offset: currentState.matches.length,
          excludeWithConversations: true, // Exclude matches with existing conversations
        ),
      );
    }
  }
  void _onMatchStoryTap(MatchStoryData match) {
    AppLogger.debug('Match tapped: ${match.name} (${match.userId})');
    // Create a conversation first, then navigate to chat when it's ready
    context.read<ChatBloc>().add(
      CreateConversation(participantId: match.userId),
    );

    // Store match data for navigation after conversation is created
    _pendingMatchNavigation = {
      'matchId': match.id, // Store match ID for removing from list
      'otherUserId': match.userId,
      'otherUserName': match.name,
      'otherUserPhoto': match.avatarUrl,
    };
    AppLogger.debug('Stored pending navigation: $_pendingMatchNavigation');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        AppLogger.debug('ChatBloc state changed: ${state.runtimeType}');
        if (state is ConversationCreated && _pendingMatchNavigation != null) {
          AppLogger.debug(
            'Navigating to chat with conversation ID: ${state.conversation.id}',
          );
          
          // Refresh matches list from API (will exclude matches with conversations)
          context.read<MatchBloc>().add(const LoadMatches(
            status: 'accepted',
            excludeWithConversations: true,
          ));
          AppLogger.debug(
            'Refreshing matches list after conversation creation',
          );
          
          // Navigate to the newly created conversation
          context.push(
            '/chat/${state.conversation.id}',
            extra: _pendingMatchNavigation,
          );
          // Clear pending navigation
          _pendingMatchNavigation = null;
        } else if (state is ConversationCreated) {
          AppLogger.debug(
            'ConversationCreated state received but _pendingMatchNavigation is null',
          );
        } else if (state is FirstMessageSent) {
          AppLogger.debug(
            'First message sent in conversation: ${state.conversationId} - refreshing matches optimistically',
          );
          // Optimistically refresh matches list when first message is sent
          context.read<MatchBloc>().add(const LoadMatches(
            status: 'accepted',
            excludeWithConversations: true,
          ));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Search bar
              _buildSearchBar(),

              // Match stories section - using BlocBuilder to get real match data
              BlocBuilder<MatchBloc, MatchState>(
                builder: (context, matchState) {
                if (matchState is MatchesLoaded) {
                  // Convert MatchModel to MatchStoryData synchronously for now
                  final matchStories = matchState.matches.map((match) {
                    // Use cached enriched match if available, otherwise create basic one
                    if (_enrichedMatches.containsKey(match.id)) {
                      return _enrichedMatches[match.id]!;
                    }

                    // Determine which user is the other user (not current user)
                      // Get current user ID from auth state
                      final authState = context.read<AuthBloc>().state;
                      final currentUserId = authState is AuthAuthenticated
                          ? authState.user.id
                          : '';
                    final otherUserId = match.user1Id == currentUserId
                        ? match.user2Id
                        : match.user1Id;

                      // Extract user data from matchReasons if available
                      final userData =
                          match.matchReasons?['user'] as Map<String, dynamic>?;
                      final userName =
                          userData?['name'] as String? ??
                          'Match ${match.id.substring(0, 8)}';
                      final avatarUrl = userData?['avatarUrl'] as String? ?? '';

                    final matchStory = MatchStoryData(
                      id: match.id,
                      userId: otherUserId,
                        name: userName, // Use real user name from API
                        avatarUrl: avatarUrl, // Use real photo from API
                      isSuperLike: false, // MatchModel doesn't have this info
                      matchedTime: match.matchedAt,
                    );

                    // Cache for future use
                    _enrichedMatches[match.id] = matchStory;
                    return matchStory;
                  }).toList();

                  if (matchStories.isNotEmpty) {
                    return MatchStoriesSection(
                      matches: matchStories,
                      onMatchTap: _onMatchStoryTap,
                      hasMore: matchState.hasMore,
                      onLoadMore: _loadMoreMatches,
                    );
                  }
                }

                if (matchState is MatchLoading) {
                  return Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (matchState is MatchError) {
                  return Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Failed to load matches: ${matchState.message}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadMatchStories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // Conversations list
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _filteredConversations.isEmpty
                          ? _buildEmptyState()
                          : _buildConversationsList(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Row(
        children: [
          Text(
            'Messages',
            style: PulseTextStyles.headlineLarge.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // AI Companion button
          IconButton(
            onPressed: () => context.go('/ai-companion'),
            icon: const Icon(Icons.smart_toy),
            style: IconButton.styleFrom(
              backgroundColor: PulseColors.primaryContainer,
              foregroundColor: PulseColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          // Filter button with indicator
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  _showFilterOptions();
                },
                icon: const Icon(Icons.filter_list),
                style: IconButton.styleFrom(
                  backgroundColor: _hasActiveFilters()
                      ? PulseColors.primary
                      : PulseColors.surfaceVariant,
                  foregroundColor: _hasActiveFilters()
                      ? Colors.white
                      : PulseColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PulseRadii.md),
                  ),
                ),
              ),
              if (_hasActiveFilters())
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: PulseColors.primary,
                        width: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: PulseSpacing.sm),
          IconButton(
            onPressed: () {
              _showMessageOptions(context);
            },
            icon: const Icon(Icons.more_vert),
            style: IconButton.styleFrom(
              backgroundColor: PulseColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: MessageSearchBar(
              controller: _searchController,
              hint: 'Search conversations...',
              onChanged: _handleSearch,
              onClear: () {
                _handleSearch('');
              },
            ),
          ),
          const SizedBox(width: PulseSpacing.sm),
          IconButton(
            onPressed: () {
              _showFullSearch();
            },
            icon: const Icon(Icons.search),
            style: IconButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(ConversationData conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: PulseSpacing.md),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConversation(conversation),
          borderRadius: BorderRadius.circular(PulseRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(PulseSpacing.md),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PulseColors.outline,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: conversation.avatar,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: PulseColors.surfaceVariant,
                            child: const Icon(Icons.person),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: PulseColors.surfaceVariant,
                            child: const Icon(Icons.person),
                          ),
                        ),
                      ),
                    ),
                    if (conversation.isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: PulseColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: PulseColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: PulseSpacing.md),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            conversation.name,
                            style: PulseTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PulseColors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            conversation.timestamp,
                            style: PulseTextStyles.labelSmall.copyWith(
                              color: PulseColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PulseSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage,
                              style: PulseTextStyles.bodyMedium.copyWith(
                                color: conversation.unreadCount > 0
                                    ? PulseColors.onSurface
                                    : PulseColors.onSurfaceVariant,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: PulseSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PulseSpacing.sm,
                                vertical: PulseSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: PulseColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: PulseTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: PulseColors.error,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'Failed to load conversations',
            style: PulseTextStyles.headlineMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            _error ?? 'Unknown error occurred',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.xl),
          ElevatedButton(
            onPressed: _loadConversations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: PulseColors.onSurfaceVariant,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'No messages yet',
            style: PulseTextStyles.headlineMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Start matching to begin conversations',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PulseSpacing.xl),
          PulseButton(
            text: 'Start Matching',
            onPressed: () {
              context.go('/discovery');
            },
            variant: PulseButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  void _openConversation(ConversationData conversation) {
    // Navigate to chat screen with proper data
    // Use push instead of go to maintain navigation stack
    context.push(
      '/chat/${conversation.id}',
      extra: {
        'otherUserId':
            conversation.id, // Using conversation.id as user ID for now
        'otherUserName': conversation.name,
        'otherUserPhoto': conversation.avatar,
      },
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark all as read'),
              onTap: () {
                Navigator.of(context).pop();
                // Mark all conversations as read
                _markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/settings/chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archived chats'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/messages/archived');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _applyFilters();
      } else {
        _filteredConversations = _allConversations.where((conversation) {
          final matchesQuery =
              conversation.name.toLowerCase().contains(query.toLowerCase()) ||
              conversation.lastMessage.toLowerCase().contains(
                query.toLowerCase(),
              );
          return matchesQuery && _matchesCurrentFilters(conversation);
        }).toList();
        _sortConversations();
      }
    });
  }

  void _applyFilters() {
    _filteredConversations = _allConversations.where((conversation) {
      return _matchesCurrentFilters(conversation);
    }).toList();
    _sortConversations();
  }

  bool _matchesCurrentFilters(ConversationData conversation) {
    // Type filter
    if (_currentFilters.type != MessageFilterType.all &&
        conversation.type != _currentFilters.type) {
      return false;
    }

    // Status filter
    if (_currentFilters.status != MessageStatusFilter.all) {
      switch (_currentFilters.status) {
        case MessageStatusFilter.online:
          if (!conversation.isOnline) return false;
          break;
        case MessageStatusFilter.offline:
          if (conversation.isOnline) return false;
          break;
        case MessageStatusFilter.recentlyActive:
          // In a real app, you'd check last active time
          break;
        case MessageStatusFilter.all:
          break;
      }
    }

    // Quick filters
    if (_currentFilters.showOnlineOnly && !conversation.isOnline) {
      return false;
    }

    if (_currentFilters.showUnreadOnly && conversation.unreadCount == 0) {
      return false;
    }

    return true;
  }

  void _sortConversations() {
    switch (_currentFilters.sortBy) {
      case MessageSortOption.recent:
        // Already sorted by default
        break;
      case MessageSortOption.alphabetical:
        _filteredConversations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case MessageSortOption.unreadFirst:
        _filteredConversations.sort(
          (a, b) => b.unreadCount.compareTo(a.unreadCount),
        );
        break;
      case MessageSortOption.onlineFirst:
        _filteredConversations.sort((a, b) {
          if (a.isOnline && !b.isOnline) return -1;
          if (!a.isOnline && b.isOnline) return 1;
          return 0;
        });
        break;
    }
  }

  bool _hasActiveFilters() {
    return _currentFilters.type != MessageFilterType.all ||
        _currentFilters.status != MessageStatusFilter.all ||
        _currentFilters.timeFilter != MessageTimeFilter.all ||
        _currentFilters.showOnlineOnly ||
        _currentFilters.showUnreadOnly ||
        _currentFilters.sortBy != MessageSortOption.recent;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageFilterBottomSheet(
        currentFilters: _currentFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _currentFilters = filters;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _showFullSearch() {
    final conversationsForSearch = _allConversations
        .map(
          (conv) => {
            'id': conv.id,
            'name': conv.name,
            'avatar': conv.avatar,
            'lastMessage': conv.lastMessage,
            'timestamp': conv.timestamp,
            'unreadCount': conv.unreadCount,
          },
        )
        .toList();

    showSearch(
      context: context,
      delegate: MessageSearchDelegate(
        conversations: conversationsForSearch,
        onSearch: (query) {
          _searchController.text = query;
          _handleSearch(query);
        },
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      _allConversations = _allConversations.map((conversation) {
        return ConversationData(
          id: conversation.id,
          name: conversation.name,
          avatar: conversation.avatar,
          lastMessage: conversation.lastMessage,
          timestamp: conversation.timestamp,
          unreadCount: 0, // Mark as read
          isOnline: conversation.isOnline,
          type: conversation.type,
        );
      }).toList();
      _applyFilters();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All conversations marked as read'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ConversationData {
  const ConversationData({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    this.type = MessageFilterType.all,
  });

  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;
  final MessageFilterType type;
}
