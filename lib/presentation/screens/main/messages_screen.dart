import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/robust_network_image.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/messaging/message_filters.dart';
import '../../widgets/messaging/message_search.dart';
import '../../widgets/messaging/match_stories_section.dart';
import '../../widgets/common/sync_status_indicator.dart';
import '../../../data/services/conversation_service.dart';
import '../../../data/models/user.dart';
import '../../../domain/entities/message.dart' show MessageType;
import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_event.dart';
import '../../blocs/match/match_state.dart';
import '../../../blocs/chat_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../features/group_chat/presentation/screens/group_list_screen.dart';
import '../../blocs/group_chat/group_chat_bloc.dart';
import '../../../features/group_chat/data/group_chat_service.dart';
import '../../../features/group_chat/data/group_chat_websocket_service.dart';
import '../../../core/network/api_client.dart';
import 'settings_screen.dart';

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

  /// Load all conversations from the backend
  /// Also refreshes matches when force reload is needed
  Future<void> _loadConversations({bool includeMatches = false}) async {
    AppLogger.debug(
      '🔄 Loading conversations... (includeMatches: $includeMatches)',
    );
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Reload matches if requested (e.g., on pull-to-refresh)
      if (includeMatches) {
        _loadMatchStories();
      }

      AppLogger.debug('📞 Calling getUserConversations API...');
      final conversations = await _conversationService.getUserConversations();
      AppLogger.debug(
        '✅ Received ${conversations.length} conversations from API',
      );

      // Filter out group conversations - they should only appear in Group Chat tab
      final directConversations = conversations
          .where((conv) => !conv.isGroup)
          .toList();
      AppLogger.debug(
        '🔍 Filtered to ${directConversations.length} direct conversations (excluded ${conversations.length - directConversations.length} group chats)',
      );

      if (!mounted || !context.mounted) return;

      // Get current user ID
      final authState = context.read<AuthBloc>().state;
      String? currentUserId;
      if (authState is AuthAuthenticated) {
        currentUserId = authState.user.id;
      }

      // Convert backend Conversation models to UI ConversationData
      final conversationDataList = directConversations.map((conversation) {
        // Get the other participant (assuming 1-on-1 conversations)
        final otherParticipant = conversation.participants.firstWhere(
          (participant) =>
              participant.id != currentUserId, // Compare with current user ID
          orElse: () => conversation.participants.isNotEmpty
              ? conversation.participants.first
              : User(
                  id: 'unknown',
                  email: 'unknown@example.com',
                  username: 'Unknown User',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
        );

        final avatarUrl = otherParticipant.profileImageUrl ?? '';
        final avatarBlurhash = otherParticipant
            .avatarBlurhash; // ✅ Get blurhash from other participant
        AppLogger.debug(
          '🐛 Avatar URL for ${otherParticipant.name}: "$avatarUrl"',
        );

        // Debug last message data
        AppLogger.debug(
          '🐛 Last message for ${otherParticipant.name}: ${conversation.lastMessage}',
        );
        AppLogger.debug(
          '🐛 Last message content: "${conversation.lastMessage?.content ?? 'NULL'}"',
        );
        AppLogger.debug(
          '🐛 Last message type: "${conversation.lastMessage?.type ?? 'NULL'}"',
        );
        AppLogger.debug(
          '🐛 Last message metadata: ${conversation.lastMessage?.metadata}',
        );

        // Determine enhanced last message preview with type detection
        String lastMessagePreview = _formatMessagePreview(
          conversation.lastMessage,
        );

        final lastMessageDateTime =
            conversation.lastActivity ?? conversation.updatedAt;

        return ConversationData(
          id: conversation.id,
          name: otherParticipant
              .name, // Use computed name getter (displayName || fullName || fallback)
          avatar: avatarUrl,
          avatarBlurhash:
              avatarBlurhash, // ✅ Pass blurhash from other participant
          lastMessage: lastMessagePreview,
          timestamp: _formatTimestamp(lastMessageDateTime),
          lastMessageTime: lastMessageDateTime,
          unreadCount: conversation.unreadCount,
          isOnline: false, // We'd need real-time status for this
          otherUserId: otherParticipant.id,
          type: MessageFilterType.all, // Default type, could be enhanced
        );
      }).toList();

      // FILTER: Only include conversations that have actual messages
      // Exclude conversations with "No messages yet" or empty lastMessage
      final conversationsWithMessages = conversationDataList.where((conv) {
        return conv.lastMessage.isNotEmpty &&
            conv.lastMessage != 'No messages yet';
      }).toList();

      AppLogger.debug(
        '🔍 Filtered conversations: ${conversationDataList.length} total → ${conversationsWithMessages.length} with messages',
      );

      // Deduplicate conversations by otherUserId to prevent duplicate entries
      final Map<String, ConversationData> uniqueConversations = {};
      for (final conv in conversationsWithMessages) {
        if (!uniqueConversations.containsKey(conv.otherUserId) ||
            uniqueConversations[conv.otherUserId]!.lastMessageTime.isBefore(
              conv.lastMessageTime,
            )) {
          uniqueConversations[conv.otherUserId] = conv;
        }
      }
      final deduplicatedList = uniqueConversations.values.toList();

      // Sort conversations by most recent activity first (DateTime descending)
      deduplicatedList.sort(
        (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
      );

      AppLogger.debug(
        '🗋️ After deduplication: ${deduplicatedList.length} conversations',
      );

      setState(() {
        _allConversations = deduplicatedList;
        _isLoading = false;
      });

      AppLogger.debug(
        '🎯 Set _allConversations to ${_allConversations.length} items',
      );
      _applyFilters();
      AppLogger.debug(
        '✅ After filters: ${_filteredConversations.length} conversations',
      );
    } catch (e) {
      AppLogger.error('❌ Error loading conversations: $e');
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

  /// Enhanced message preview with type detection and formatting
  String _formatMessagePreview(dynamic message) {
    if (message == null) {
      return 'No messages yet';
    }

    // Extract content and type from message object
    final content = (message.content ?? '').trim();
    final type = message.type;
    final metadata = message.metadata as Map<String, dynamic>?;

    // Prioritize type detection for media messages
    // Check for MessageType enum directly (type is MessageType enum, not string)
    if (type == MessageType.image ||
        type?.toString() == 'MessageType.image' ||
        type == 'image') {
      return '📷 Photo';
    } else if (type == MessageType.video ||
        type?.toString() == 'MessageType.video' ||
        type == 'video') {
      return '🎥 Video';
    } else if (type == MessageType.audio ||
        type?.toString() == 'MessageType.audio' ||
        type == 'audio' ||
        type == 'voice') {
      return '🎵 Voice message';
    } else if (type == MessageType.file ||
        type?.toString() == 'MessageType.file' ||
        type == 'file') {
      return '📄 Attachment';
    }

    // Check metadata for media type hints
    if (metadata != null) {
      final mediaType = metadata['mediaType'] as String?;
      if (mediaType == 'image') return '📷 Photo';
      if (mediaType == 'video') return '🎥 Video';
      if (mediaType == 'audio') return '🎵 Voice message';
    }

    // If no content, return appropriate message
    if (content.isEmpty) {
      return 'No messages yet';
    }

    // Check if content is an image URL (fallback detection)
    if (content.startsWith('http') &&
        (content.contains('/uploads/') || content.contains('/media/')) &&
        (content.endsWith('.jpg') ||
            content.endsWith('.jpeg') ||
            content.endsWith('.png') ||
            content.endsWith('.gif') ||
            content.endsWith('.webp') ||
            content.contains('.jpg?') ||
            content.contains('.jpeg?') ||
            content.contains('.png?'))) {
      return '📷 Photo';
    }

    // Check if content is a video URL
    if (content.startsWith('http') &&
        (content.endsWith('.mp4') ||
            content.endsWith('.mov') ||
            content.endsWith('.avi') ||
            content.contains('.mp4?'))) {
      return '🎥 Video';
    }

    // Handle different message types with appropriate icons (when content contains keywords)
    if (content.toLowerCase().contains('location') ||
        content.startsWith('geo:')) {
      return '📍 Location shared';
    }

    // Regular text message - truncate if too long
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  /// Load match stories for users that haven't been chatted with yet
  Future<void> _loadMatchStories() async {
    // Use MatchBloc to load real matches without existing conversations
    context.read<MatchBloc>().add(
      const LoadMatches(
        status: 'accepted', // Load accepted matches (mutual matches)
        limit: 20,
        offset: 0,
        excludeWithConversations:
            true, // Exclude matches with existing conversations
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
          excludeWithConversations:
              true, // Exclude matches with existing conversations
        ),
      );
    }
  }

  void _onMatchStoryTap(MatchStoryData match) {
    AppLogger.debug(
      'Match tapped: ${match.name} (${match.userId}) - ConversationId: ${match.conversationId}',
    );

    // If conversation already exists, navigate directly to chat
    if (match.conversationId != null && match.conversationId!.isNotEmpty) {
      AppLogger.debug(
        '🚀 Using existing conversation: ${match.conversationId}',
      );
      context.push(
        '/chat/${match.conversationId}',
        extra: {
          'otherUserId': match.userId,
          'otherUserName': match.name,
          'otherUserPhoto': match.avatarUrl,
        },
      );
      return;
    }

    // Fallback: Create conversation if ID is missing (shouldn't happen normally)
    AppLogger.debug('⚠️ No conversation ID found, creating new conversation');
    context.read<ChatBloc>().add(
      CreateConversation(participantId: match.userId),
    );

    // Store match data for navigation after conversation is created
    _pendingMatchNavigation = {
      'matchId': match.id,
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
          context.read<MatchBloc>().add(
            const LoadMatches(
              status: 'accepted',
              excludeWithConversations: true,
            ),
          );
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
          context.read<MatchBloc>().add(
            const LoadMatches(
              status: 'accepted',
              excludeWithConversations: true,
            ),
          );
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
                  AppLogger.debug(
                    '🐛 MatchBloc state: ${matchState.runtimeType}',
                  );
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

                      // Use parsed userProfile from MatchModel which contains firstName + lastName
                      final userName =
                          match.userProfile?.name ??
                          'Match ${match.id.substring(0, 8)}';
                      final avatarUrl =
                          match.userProfile?.photos.isNotEmpty == true
                          ? match.userProfile!.photos.first.url
                          : '';

                      final matchStory = MatchStoryData(
                        id: match.id,
                        userId: otherUserId,
                        name:
                            userName, // Use real user name from parsed userProfile (firstName + lastName)
                        avatarUrl:
                            avatarUrl, // Use real photo from parsed userProfile
                        isSuperLike: false, // MatchModel doesn't have this info
                        matchedTime: match.matchedAt,
                        conversationId: match
                            .conversationId, // Include existing conversation ID
                      );

                      // Cache for future use
                      _enrichedMatches[match.id] = matchStory;
                      return matchStory;
                    }).toList();

                    // Filter: Only show matches that don't have messages yet
                    // Check if their conversationId exists in _allConversations and has no lastMessage
                    final matchesWithoutMessages = matchStories.where((match) {
                      if (match.conversationId == null) {
                        // No conversation created yet = definitely show in New Matches
                        return true;
                      }

                      // Check if conversation exists and has messages
                      final conversation = _allConversations.firstWhere(
                        (conv) => conv.id == match.conversationId,
                        orElse: () => ConversationData(
                          id: '',
                          name: '',
                          avatar: '',
                          avatarBlurhash:
                              null, // No blurhash for empty conversation
                          lastMessage: '',
                          timestamp: '',
                          lastMessageTime: DateTime.now(),
                          unreadCount: 0,
                          isOnline: false,
                          otherUserId: '',
                          type: MessageFilterType.all,
                        ),
                      );

                      // Only show in New Matches if conversation has no messages
                      return conversation.id.isEmpty ||
                          conversation.lastMessage.isEmpty ||
                          conversation.lastMessage == 'No messages yet';
                    }).toList();

                    AppLogger.debug(
                      '📊 Filtered matches: ${matchStories.length} total → ${matchesWithoutMessages.length} without messages',
                    );

                    if (matchesWithoutMessages.isNotEmpty) {
                      return MatchStoriesSection(
                        matches: matchesWithoutMessages,
                        onMatchTap: _onMatchStoryTap,
                        hasMore: matchState.hasMore,
                        onLoadMore: _loadMoreMatches,
                      );
                    }
                  }

                  if (matchState is MatchLoading) {
                    AppLogger.debug('🐛 MatchLoading state');
                    return Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SkeletonLoader(
                            width: 80,
                            height: 100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }

                  if (matchState is MatchError) {
                    AppLogger.debug('🐛 MatchError: ${matchState.message}');
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

                  // If no specific state, show empty but log it
                  AppLogger.debug(
                    '🐛 Unknown match state: ${matchState.runtimeType}',
                  );
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
                    ? RefreshIndicator(
                        onRefresh: () =>
                            _loadConversations(includeMatches: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _buildEmptyState(),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            _loadConversations(includeMatches: true),
                        child: _buildConversationsList(),
                      ),
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
          const SizedBox(width: 12),
          const SyncStatusIndicator(),
          const Spacer(),
          // Group Chat button
          IconButton(
            onPressed: () {
              // Create GroupChatBloc with required services
              final apiClient = ApiClient.instance;
              final authToken = apiClient.authToken ?? '';

              final groupChatService = GroupChatService();
              final wsService = GroupChatWebSocketService(
                baseUrl: ApiConstants.websocketUrl,
                accessToken: authToken,
              );

              final bloc = GroupChatBloc(
                service: groupChatService,
                wsService: wsService,
              );

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: GroupListScreen(bloc: bloc),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.groups),
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
                      border: Border.all(color: PulseColors.primary, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: PulseSpacing.sm),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            color: Theme.of(context).cardColor,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'mark_read',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.mark_chat_read,
                      color: PulseColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Mark all as read',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'group_chats',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.groups, color: PulseColors.primary),
                  ),
                  title: const Text(
                    'Group chats',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.settings, color: PulseColors.primary),
                  ),
                  title: const Text(
                    'Messaging settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  _markAllAsRead();
                  break;
                case 'group_chats':
                  if (!mounted) return;

                  final apiClient = ApiClient.instance;
                  final authToken = apiClient.authToken ?? '';

                  final groupChatService = GroupChatService();
                  final wsService = GroupChatWebSocketService(
                    baseUrl: ApiConstants.websocketUrl,
                    accessToken: authToken,
                  );

                  final bloc = GroupChatBloc(
                    service: groupChatService,
                    wsService: wsService,
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: GroupListScreen(bloc: bloc),
                      ),
                    ),
                  );
                  break;
                case 'settings':
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
              }
            },
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
                        child: conversation.avatar.isNotEmpty
                            ? RobustNetworkImage(
                                imageUrl: conversation.avatar,
                                blurhash: conversation
                                    .avatarBlurhash, // ✅ Progressive loading
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                              )
                            : Container(
                                color: PulseColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Center(
                                  child: Text(
                                    conversation.name.isNotEmpty
                                        ? conversation.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: PulseColors.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                          Expanded(
                            child: Text(
                              conversation.name,
                              style: PulseTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: PulseColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: PulseSpacing.xs),
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
    return const SkeletonList(
      skeletonItem: MessageCardSkeleton(),
      itemCount: 8,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: PulseColors.error),
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
    return EmptyStates.noMessages(onExplore: () => context.go('/matches'));
  }

  void _openConversation(ConversationData conversation) {
    // Navigate to chat screen with proper data
    // Use push instead of go to maintain navigation stack
    context.push(
      '/chat/${conversation.id}',
      extra: {
        'otherUserId':
            conversation.otherUserId, // Now using the correct other user ID
        'otherUserName': conversation.name,
        'otherUserPhoto': conversation.avatar,
      },
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
    // NOTE: Removed "No messages yet" filter - conversations should show even without messages
    // This allows users to see all their conversations, including newly created ones

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
          avatarBlurhash: conversation.avatarBlurhash, // ✅ Preserve blurhash
          lastMessage: conversation.lastMessage,
          timestamp: conversation.timestamp,
          lastMessageTime: conversation.lastMessageTime,
          unreadCount: 0, // Mark as read
          isOnline: conversation.isOnline,
          otherUserId: conversation.otherUserId,
          type: conversation.type,
        );
      }).toList();
      _applyFilters();
    });

    PulseToast.success(
      context,
      message: 'All conversations marked as read',
      duration: const Duration(seconds: 2),
    );
  }
}

class ConversationData {
  const ConversationData({
    required this.id,
    required this.name,
    required this.avatar,
    this.avatarBlurhash, // ✅ Add blurhash for progressive loading
    required this.lastMessage,
    required this.timestamp,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    required this.otherUserId,
    this.type = MessageFilterType.all,
  });

  final String id;
  final String name;
  final String avatar;
  final String? avatarBlurhash; // ✅ Add blurhash field
  final String lastMessage;
  final String timestamp;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String otherUserId;
  final MessageFilterType type;
}
