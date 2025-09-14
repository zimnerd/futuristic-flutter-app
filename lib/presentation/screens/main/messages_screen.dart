import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

/// Enhanced messages screen with conversations list
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data for demo
  List<ConversationData> _conversations = [
    ConversationData(
      id: '1',
      name: 'Emma',
      avatar:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
      lastMessage: 'Hey! How was your day?',
      timestamp: '2m ago',
      unreadCount: 2,
      isOnline: true,
    ),
    ConversationData(
      id: '2',
      name: 'Sarah',
      avatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
      lastMessage: 'Would love to grab coffee sometime ☕️',
      timestamp: '1h ago',
      unreadCount: 0,
      isOnline: false,
    ),
  ];

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

            // Conversations list
            Expanded(
              child: _conversations.isEmpty
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
      child: PulseTextField(
        controller: _searchController,
        hintText: 'Search conversations...',
        prefixIcon: const Icon(Icons.search),
        onChanged: (value) {
          _handleSearch(value);
        },
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
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
    // Navigate to chat screen
    context.go('/chat/${conversation.id}');
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
    // Simple search implementation - filter conversations by name or last message
    setState(() {
      if (query.isEmpty) {
        // Show all conversations
        _conversations = [
          ConversationData(
            id: '1',
            name: 'Emma Wilson',
            avatar: 'https://example.com/avatar1.jpg',
            lastMessage: 'Hey! How was your day?',
            timestamp: '2 min ago',
            unreadCount: 2,
            isOnline: true,
          ),
          ConversationData(
            id: '2',
            name: 'Alex Thompson',
            avatar: 'https://example.com/avatar2.jpg',
            lastMessage: 'That sounds great! When should we meet?',
            timestamp: '5 min ago',
            unreadCount: 0,
            isOnline: false,
          ),
          ConversationData(
            id: '3',
            name: 'Sarah Chen',
            avatar: 'https://example.com/avatar3.jpg',
            lastMessage: 'Looking forward to it 😊',
            timestamp: '1 hour ago',
            unreadCount: 1,
            isOnline: true,
          ),
        ];
      } else {
        // Filter conversations
        final allConversations = [
          ConversationData(
            id: '1',
            name: 'Emma Wilson',
            avatar: 'https://example.com/avatar1.jpg',
            lastMessage: 'Hey! How was your day?',
            timestamp: '2 min ago',
            unreadCount: 2,
            isOnline: true,
          ),
          ConversationData(
            id: '2',
            name: 'Alex Thompson',
            avatar: 'https://example.com/avatar2.jpg',
            lastMessage: 'That sounds great! When should we meet?',
            timestamp: '5 min ago',
            unreadCount: 0,
            isOnline: false,
          ),
          ConversationData(
            id: '3',
            name: 'Sarah Chen',
            avatar: 'https://example.com/avatar3.jpg',
            lastMessage: 'Looking forward to it 😊',
            timestamp: '1 hour ago',
            unreadCount: 1,
            isOnline: true,
          ),
        ];

        _conversations = allConversations.where((conversation) {
          return conversation.name.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              conversation.lastMessage.toLowerCase().contains(
                query.toLowerCase(),
              );
        }).toList();
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _conversations = _conversations.map((conversation) {
        return ConversationData(
          id: conversation.id,
          name: conversation.name,
          avatar: conversation.avatar,
          lastMessage: conversation.lastMessage,
          timestamp: conversation.timestamp,
          unreadCount: 0, // Mark as read
          isOnline: conversation.isOnline,
        );
      }).toList();
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
  });

  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;
}
