import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../blocs/chat_bloc.dart';
import '../../../presentation/blocs/auth/auth_bloc.dart';
import '../../../presentation/blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

/// Enhanced filtering options for DMs
enum DmFilterBy { all, recent, unread, online, nearby }

/// Enhanced sorting options for DMs
enum DmSortBy { recent, name, distance, unreadCount }

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Enhanced filtering and sorting
  DmFilterBy _currentFilter = DmFilterBy.all;
  DmSortBy _currentSort = DmSortBy.recent;
  bool _isSearchActive = false;
  bool _showFilters = false;

  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // Load conversations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const LoadConversations());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isSearchActive ? _buildSearchAppBar() : _buildMainAppBar(),
      body: Column(
        children: [
          // Filter bar
          if (_showFilters) _buildFilterBar(),

          // Main content
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        PulseColors.primary,
                      ),
                    ),
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(
                              const LoadConversations(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ConversationsLoaded) {
                  final conversations = state.conversations;

                  // Apply filtering and search
                  final filteredConversations = _applyFiltersAndSearch(
                    conversations,
                  );

                  if (filteredConversations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      return _buildConversationTile(context, conversation);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildMainAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Messages',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            color: _showFilters ? PulseColors.primary : Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () {
            setState(() {
              _isSearchActive = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.add_comment, color: Colors.black87),
          onPressed: () {
            _showNewConversationDialog(context);
          },
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () {
          setState(() {
            _isSearchActive = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search conversations...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 18),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.black87),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          const Text(
            'Filter by:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: DmFilterBy.values.map((filter) {
              return FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: _currentFilter == filter,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
                selectedColor: PulseColors.primary.withValues(alpha: 0.2),
                checkmarkColor: PulseColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sort options
          const Text(
            'Sort by:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: DmSortBy.values.map((sort) {
              return ChoiceChip(
                label: Text(_getSortLabel(sort)),
                selected: _currentSort == sort,
                onSelected: (selected) {
                  setState(() {
                    _currentSort = sort;
                  });
                },
                selectedColor: PulseColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<dynamic> _applyFiltersAndSearch(List<dynamic> conversations) {
    var filtered = conversations.where((conversation) {
      // Apply filter
      switch (_currentFilter) {
        case DmFilterBy.recent:
          return conversation.lastMessage?.createdAt != null &&
              DateTime.now()
                      .difference(conversation.lastMessage!.createdAt)
                      .inDays <
                  7;
        case DmFilterBy.unread:
          return conversation.unreadCount > 0;
        case DmFilterBy.online:
          // In a real app, check user online status
          return true;
        case DmFilterBy.nearby:
          // In a real app, check user distance
          return true;
        case DmFilterBy.all:
          return true;
      }
    }).toList();

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conversation) {
        // Search in conversation name
        if (conversation.name != null) {
          return conversation.name!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }
        // Search in last message content
        if (conversation.lastMessage?.content != null) {
          return conversation.lastMessage!.content.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }
        // Search in participant IDs as fallback
        return conversation.participantIds.any(
          (id) => id.toLowerCase().contains(_searchQuery.toLowerCase()),
        );
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_currentSort) {
        case DmSortBy.recent:
          final aTime = a.lastMessage?.createdAt ?? DateTime(1970);
          final bTime = b.lastMessage?.createdAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        case DmSortBy.name:
          final aName = a.name ?? 'Unknown';
          final bName = b.name ?? 'Unknown';
          return aName.compareTo(bName);
        case DmSortBy.unreadCount:
          return b.unreadCount.compareTo(a.unreadCount);
        case DmSortBy.distance:
          // In a real app, sort by actual distance
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No conversations yet'
                : 'No conversations found',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start matching with people to begin chatting!'
                : 'Try searching with a different name',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(DmFilterBy filter) {
    switch (filter) {
      case DmFilterBy.all:
        return 'All';
      case DmFilterBy.recent:
        return 'Recent';
      case DmFilterBy.unread:
        return 'Unread';
      case DmFilterBy.online:
        return 'Online';
      case DmFilterBy.nearby:
        return 'Nearby';
    }
  }

  String _getSortLabel(DmSortBy sort) {
    switch (sort) {
      case DmSortBy.recent:
        return 'Recent';
      case DmSortBy.name:
        return 'Name';
      case DmSortBy.distance:
        return 'Distance';
      case DmSortBy.unreadCount:
        return 'Unread';
    }
  }

  Widget _buildConversationTile(BuildContext context, conversation) {
    // Get the other participant (not current user)
    final currentUserId =
        _currentUserId ?? 'current_user_id'; // Fallback for safety
    final otherParticipant = conversation.participants?.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => null,
    );

    final otherUserName = otherParticipant?.name ?? 'Unknown User';
    final otherUserPhoto = otherParticipant?.profilePicture;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: otherUserPhoto != null
              ? CachedNetworkImageProvider(otherUserPhoto)
              : null,
          backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
          child: otherUserPhoto == null
              ? Text(
                  otherUserName[0].toUpperCase(),
                  style: const TextStyle(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          otherUserName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              conversation.lastMessage?.content ?? 'No messages yet',
              style: TextStyle(
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
            const SizedBox(height: 4),
            Text(
              conversation.lastMessage?.createdAt != null
                  ? DateFormat('MMM d, h:mm a').format(conversation.lastMessage!.createdAt)
                  : '',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: conversation.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: PulseColors.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation.id,
                otherUserId: otherParticipant?.id ?? '',
                otherUserName: otherUserName,
                otherUserPhoto: otherUserPhoto,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Conversation'),
        content: const Text(
          'This feature will allow you to start a new conversation with your matches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to user selection screen or matches screen
            },
            child: const Text('Browse Matches'),
          ),
        ],
      ),
    );
  }
}