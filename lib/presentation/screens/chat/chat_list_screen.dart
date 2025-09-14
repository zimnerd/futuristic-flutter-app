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

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      appBar: AppBar(
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
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment, color: Colors.black87),
            onPressed: () {
              _showNewConversationDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
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
                      context.read<ChatBloc>().add(const LoadConversations());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ConversationsLoaded) {
            // Filter conversations based on search query
            final filteredConversations = _searchQuery.isEmpty
                ? state.conversations
                : state.conversations.where((conversation) {
                    // For now, filter by conversation name if available
                    // TODO: In a real app, we'd need to resolve participant names from IDs
                    if (conversation.name != null) {
                      return conversation.name!.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }
                    // For direct messages, we could use participant IDs as fallback
                    return conversation.participantIds.any(
                      (id) =>
                          id.toLowerCase().contains(_searchQuery.toLowerCase()),
                    );
                  }).toList();

            if (filteredConversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchQuery.isEmpty
                          ? Icons.chat_bubble_outline
                          : Icons.search_off,
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
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
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
    );
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

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Conversations'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by name or message...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Filter conversations based on search query
              // Implementation would filter the conversation list
            },
            child: const Text('Search'),
          ),
        ],
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