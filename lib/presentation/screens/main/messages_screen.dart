import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
  final List<ConversationData> _conversations = [
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
              // TODO: Show message options
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
          // TODO: Implement search
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
              // TODO: Navigate to discover
            },
            variant: PulseButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  void _openConversation(ConversationData conversation) {
    // TODO: Navigate to chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${conversation.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
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
