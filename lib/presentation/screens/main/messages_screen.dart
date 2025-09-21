import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/messaging/message_filters.dart';
import '../../widgets/messaging/message_search.dart';
import '../../widgets/messaging/match_stories_section.dart';
import '../../../data/services/conversation_service.dart';
import '../../blocs/matching/matching_bloc.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/models/match_model.dart';

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
  List<MatchStoryData> _matchStories = [];
  bool _isLoading = true;
  bool _isLoadingMatches = true;
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
    setState(() {
      _isLoadingMatches = true;
    });

    try {
      // Get matches from bloc - for now we'll use dummy data
      // In a real app, this would filter matches that don't have conversations yet
      final sampleMatches = _generateSampleMatches();

      setState(() {
        _matchStories = sampleMatches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMatches = false;
      });
    }
  }

  /// Generate sample match data - replace with real data from MatchingBloc
  List<MatchStoryData> _generateSampleMatches() {
    return [
      MatchStoryData(
        id: '1',
        userId: 'user1',
        name: 'Emma',
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b789?w=150',
        isSuperLike: true,
        matchedTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      MatchStoryData(
        id: '2',
        userId: 'user2',
        name: 'Sophia',
        avatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        isSuperLike: false,
        matchedTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MatchStoryData(
        id: '3',
        userId: 'user3',
        name: 'Olivia',
        avatarUrl:
            'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=150',
        isSuperLike: false,
        matchedTime: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MatchStoryData(
        id: '4',
        userId: 'user4',
        name: 'Isabella',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isSuperLike: true,
        matchedTime: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      MatchStoryData(
        id: '5',
        userId: 'user5',
        name: 'Ava',
        avatarUrl:
            'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=150',
        isSuperLike: false,
        matchedTime: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  /// Handle tapping on a match story to start a conversation
  void _onMatchStoryTap(MatchStoryData match) {
    // Create a conversation and navigate to chat screen
    // For now, navigate directly to chat screen with match data
    context.go(
      '/chat/new',
      extra: {
        'otherUserId': match.userId,
        'otherUserName': match.name,
        'otherUserPhoto': match.avatarUrl,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Match stories section
            if (_matchStories.isNotEmpty && !_isLoadingMatches)
              MatchStoriesSection(
                matches: _matchStories,
                onMatchTap: _onMatchStoryTap,
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
                      ? PulseColors.primaryContainer
                      : PulseColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PulseRadii.md),
                  ),
                ),
              ),
              if (_hasActiveFilters())
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: PulseColors.primary,
                      shape: BoxShape.circle,
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
    context.go(
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
