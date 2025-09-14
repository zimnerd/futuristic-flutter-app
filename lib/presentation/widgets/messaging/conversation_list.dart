import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/conversation.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import 'chat_interface.dart';

/// Enhanced conversation list with search and filtering
class ConversationList extends StatefulWidget {
  const ConversationList({super.key});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    // Load conversations when widget initializes
    context.read<MessagingBloc>().add(const LoadConversations());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<MessagingBloc>().state;
      if (!state.hasReachedMaxConversations && 
          state.conversationsStatus != MessagingStatus.loading) {
        context.read<MessagingBloc>().add(const LoadConversations());
      }
    }
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    
    return conversations.where((conv) {
      return conv.otherUserName.toLowerCase().contains(_searchQuery) ||
          conv.lastMessage.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<Conversation> _getFilteredConversations(List<Conversation> conversations, int tabIndex) {
    final filtered = _filterConversations(conversations);
    
    switch (tabIndex) {
      case 0: // All
        return filtered;
      case 1: // Unread
        return filtered.where((conv) => conv.unreadCount > 0).toList();
      case 2: // Matches
        return filtered.where((conv) => conv.isNewMatch).toList();
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: PulseColors.surface,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: PulseColors.primary,
                labelColor: PulseColors.primary,
                unselectedLabelColor: Colors.grey[600],
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('All'),
                        const SizedBox(width: 4),
                        BlocBuilder<MessagingBloc, MessagingState>(
                          builder: (context, state) {
                            if (state.conversations.isNotEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${state.conversations.length}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unread'),
                        const SizedBox(width: 4),
                        BlocBuilder<MessagingBloc, MessagingState>(
                          builder: (context, state) {
                            final unreadCount = state.totalUnreadCount;
                            if (unreadCount > 0) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Tab(text: 'Matches'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationTab(0),
          _buildConversationTab(1),
          _buildConversationTab(2),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          // Navigate to discovery to find new matches
          context.go('/discovery');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConversationTab(int tabIndex) {
    return BlocBuilder<MessagingBloc, MessagingState>(
      builder: (context, state) {
        if (state.conversationsStatus == MessagingStatus.loading && 
            state.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: PulseColors.primary),
          );
        }

        if (state.conversationsStatus == MessagingStatus.error && 
            state.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error ?? 'Unknown error occurred',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PulseButton(
                  text: 'Retry',
                  onPressed: () {
                    context.read<MessagingBloc>().add(
                      const LoadConversations(refresh: true),
                    );
                  },
                ),
              ],
            ),
          );
        }

        final filteredConversations = _getFilteredConversations(
          state.conversations, 
          tabIndex,
        );

        if (filteredConversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _getEmptyStateTitle(tabIndex),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateSubtitle(tabIndex),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: PulseColors.primary,
          onRefresh: () async {
            context.read<MessagingBloc>().add(
              const LoadConversations(refresh: true),
            );
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredConversations.length + 
                (state.hasReachedMaxConversations ? 0 : 1),
            itemBuilder: (context, index) {
              if (index >= filteredConversations.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: PulseColors.primary,
                    ),
                  ),
                );
              }

              final conversation = filteredConversations[index];
              return ConversationTile(
                conversation: conversation,
                onTap: () => _openChat(conversation),
                onLongPress: () => _showConversationOptions(conversation),
              );
            },
          ),
        );
      },
    );
  }

  String _getEmptyStateTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'No conversations yet';
      case 1:
        return 'No unread messages';
      case 2:
        return 'No new matches';
      default:
        return 'No conversations';
    }
  }

  String _getEmptyStateSubtitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Start matching with people to begin conversations!';
      case 1:
        return 'All caught up! No unread messages.';
      case 2:
        return 'Keep swiping to find new matches!';
      default:
        return 'Start matching to begin conversations.';
    }
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatInterface(conversation: conversation),
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                conversation.otherUserName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildOptionTile(
                icon: conversation.isMuted ? Icons.volume_up : Icons.volume_off,
                title: conversation.isMuted ? 'Unmute' : 'Mute',
                onTap: () {
                  Navigator.pop(context);
                  _toggleMute(conversation);
                },
              ),
              
              _buildOptionTile(
                icon: conversation.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                title: conversation.isPinned ? 'Unpin' : 'Pin',
                onTap: () {
                  Navigator.pop(context);
                  _togglePin(conversation);
                },
              ),
              
              _buildOptionTile(
                icon: Icons.block,
                title: 'Block User',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(conversation);
                },
              ),
              
              _buildOptionTile(
                icon: Icons.delete,
                title: 'Delete Conversation',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(conversation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.black87),
      ),
      onTap: onTap,
    );
  }

  void _showBlockConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Block ${conversation.otherUserName}? They won\'t be able to message you anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessagingBloc>().add(
                BlockUser(userId: conversation.otherUserId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessagingBloc>().add(
                DeleteConversation(conversationId: conversation.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleMute(Conversation conversation) {
    // Simple UI feedback for now - in a real app this would update the backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !conversation.isMuted 
            ? 'Conversation muted' 
            : 'Conversation unmuted'
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _togglePin(Conversation conversation) {
    // Simple UI feedback for now - in a real app this would update the backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !conversation.isPinned 
            ? 'Conversation pinned' 
            : 'Conversation unpinned'
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Individual conversation tile widget
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0 
              ? PulseColors.primary.withValues(alpha: 0.05)
              : null,
          border: const Border(
            bottom: BorderSide(color: Colors.grey, width: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: conversation.otherUserAvatar.isNotEmpty
                      ? NetworkImage(conversation.otherUserAvatar)
                      : null,
                  child: conversation.otherUserAvatar.isEmpty
                      ? Text(
                          conversation.otherUserName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                if (conversation.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and timestamp
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              conversation.otherUserName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: conversation.unreadCount > 0 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                              ),
                            ),
                            if (conversation.isNewMatch) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: PulseColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (conversation.isPinned) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.push_pin,
                                size: 14,
                                color: PulseColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: conversation.unreadCount > 0 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Last message and unread count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: conversation.unreadCount > 0 
                                ? Colors.black87 
                                : Colors.grey[600],
                            fontWeight: conversation.unreadCount > 0 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: PulseColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadCount > 99 
                                ? '99+' 
                                : '${conversation.unreadCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (conversation.isMuted) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.volume_off,
                          size: 16,
                          color: Colors.grey[600],
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
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[timestamp.weekday - 1];
      } else {
        return '${timestamp.day}/${timestamp.month}';
      }
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
