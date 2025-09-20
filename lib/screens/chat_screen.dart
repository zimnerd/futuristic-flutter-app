import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../data/models/chat_model.dart';
import '../data/models/message.dart'; // Import for MessageType that matches chat_bloc
import '../data/services/auth_service.dart';
import '../core/constants/app_constants.dart';
import '../widgets/chat/enhanced_message_bubble.dart';
import '../widgets/chat/reply_input_widget.dart';
import '../widgets/chat/contextual_action_button.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String participantName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  MessageModel? _replyToMessage;
  bool _isTyping = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _getCurrentUser();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(LoadMessages(
      conversationId: widget.conversationId,
    ));
  }

  void _getCurrentUser() async {
    try {
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      // Handle error - use fallback or show error
      debugPrint('Error getting current user: $e');
    }
  }

  void _onTextChanged() {
    final isTyping = _textController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      
      context.read<ChatBloc>().add(UpdateTypingStatus(
        conversationId: widget.conversationId,
        isTyping: isTyping,
      ));
    }
  }

  void _onScrollChanged() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels == 0) {
      // Load more messages
      final state = context.read<ChatBloc>().state;
      if (state is MessagesLoaded && state.hasMoreMessages) {
        // Calculate next page
        final currentPage = (state.messages.length / 50).ceil();
        context.read<ChatBloc>().add(LoadMessages(
          conversationId: widget.conversationId,
          page: currentPage + 1,
        ));
      }
    }
  }

  void _sendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      type: MessageType.text, // Using the correct MessageType from entities
      content: content,
      replyToMessageId: _replyToMessage?.id,
    ));

    _textController.clear();
    _cancelReply();
    _scrollToBottom();
  }

  void _setReplyToMessage(MessageModel message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _scrollToMessage(String messageId) {
    // Find message index and scroll to it
    final state = context.read<ChatBloc>().state;
    if (state is MessagesLoaded) {
      final index = state.messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _scrollController.animateTo(
          index * 100.0, // Approximate message height
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _performContextualAction(String actionId, String actionType, Map<String, dynamic> actionData) {
    context.read<ChatBloc>().add(PerformContextualAction(
      actionId: actionId,
      actionType: actionType,
      actionData: actionData,
    ));
  }

  void _editMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => _EditMessageDialog(
        message: message,
        onSave: (newContent) {
          context.read<ChatBloc>().add(EditMessage(
            messageId: message.id,
            newContent: newContent,
          ));
        },
      ),
    );
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(DeleteMessage(messageId: message.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyMessage(MessageModel message) {
    context.read<ChatBloc>().add(CopyMessage(messageId: message.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _showChatSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatSettingsBottomSheet(
        conversationId: widget.conversationId,
        participantName: widget.participantName,
      ),
    );
  }

  void _initiateVideoCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Video Call'),
        content: Text('Start a video call with ${widget.participantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to video call screen
              _navigateToCall(isVideo: true);
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _initiateVoiceCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Voice Call'),
        content: Text('Start a voice call with ${widget.participantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to voice call screen
              _navigateToCall(isVideo: false);
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _navigateToCall({required bool isVideo}) {
    final callType = isVideo ? 'video' : 'voice';
    
    // Show loading state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting $callType call with ${widget.participantName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Navigate to call screen (this would be a real call screen in production)
    Navigator.pushNamed(
      context,
      '/call',
      arguments: {
        'conversationId': widget.conversationId,
        'participantName': widget.participantName,
        'participantId': widget.conversationId, // In real app, this would be actual participant ID
        'isVideoCall': isVideo,
        'isOutgoing': true,
      },
    ).catchError((error) {
      // If route doesn't exist, show temporary message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isVideo ? 'Video' : 'Voice'} call feature will be available soon!\n'
              'This would normally open the WebRTC call screen.',
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              },
            ),
          ),
        );
      }
      return null; // Return null for error case
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.participantName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _initiateVideoCall();
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              _initiateVoiceCall();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessageSent) {
                  _scrollToBottom();
                } else if (state is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MessagesLoaded) {
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[state.messages.length - 1 - index];
                      final isCurrentUser =
                          _currentUserId != null &&
                          message.senderId == _currentUserId;

                      return EnhancedMessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        onReply: () => _setReplyToMessage(message),
                        onEdit: () => _editMessage(message),
                        onCopy: () => _copyMessage(message),
                        onDelete: () => _deleteMessage(message),
                        onTapReply: _scrollToMessage,
                        contextualActions: _buildContextualActions(message),
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('Start a conversation!'),
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final isLoading = state is ChatLoading;
              
              return ReplyInputWidget(
                replyToMessage: _replyToMessage,
                textController: _textController,
                onSend: _sendMessage,
                onCancelReply: _cancelReply,
                isLoading: isLoading,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContextualActions(MessageModel message) {
    // Only show contextual actions for AI messages
    if (message.senderId == AppConstants.aiCompanionId) {
      return [
        AIContextualActions.askQuestion(() {
          _performContextualAction(
            'ask_question_${DateTime.now().millisecondsSinceEpoch}',
            'ask_question',
            {'originalMessageId': message.id},
          );
        }),
        AIContextualActions.explainMore(() {
          _performContextualAction(
            'explain_more_${DateTime.now().millisecondsSinceEpoch}',
            'explain_more',
            {'originalMessageId': message.id},
          );
        }),
        AIContextualActions.getAdvice(() {
          _performContextualAction(
            'get_advice_${DateTime.now().millisecondsSinceEpoch}',
            'get_advice',
            {'originalMessageId': message.id},
          );
        }),
      ];
    }
    return [];
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              Navigator.pop(context);
              _performSearch(query.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _performSearch(query);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // For now, implement local search through loaded messages
    final state = context.read<ChatBloc>().state;
    if (state is MessagesLoaded) {
      final results = state.messages.where((message) {
        return message.content?.toLowerCase().contains(query.toLowerCase()) ?? false;
      }).toList();
      
      _showSearchResults(query, results);
    }
  }

  void _showSearchResults(String query, List<MessageModel> results) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF6E3BFF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search results for "$query"',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try different search terms',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final message = results[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF6E3BFF).withValues(alpha: 0.1),
                              child: Icon(
                                message.senderId == _currentUserId
                                    ? Icons.person
                                    : Icons.smart_toy,
                                color: const Color(0xFF6E3BFF),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              message.content ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatMessageTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _scrollToMessage(message.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _EditMessageDialog extends StatefulWidget {
  final MessageModel message;
  final ValueChanged<String> onSave;

  const _EditMessageDialog({
    required this.message,
    required this.onSave,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Message'),
      content: TextField(
        controller: _controller,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          hintText: 'Enter your message...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newContent = _controller.text.trim();
            if (newContent.isNotEmpty && newContent != widget.message.content) {
              widget.onSave(newContent);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ChatSettingsBottomSheet extends StatelessWidget {
  final String conversationId;
  final String participantName;

  const _ChatSettingsBottomSheet({
    required this.conversationId,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat with $participantName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingItem(
                  icon: Icons.search,
                  title: 'Search Messages',
                  subtitle: 'Find messages in this conversation',
                  onTap: () {
                    Navigator.pop(context);
                    // Call the search method from the parent widget
                    if (context.mounted) {
                      final chatScreenState = context.findAncestorStateOfType<_ChatScreenState>();
                      chatScreenState?._showSearchDialog(context);
                    }
                  },
                ),
                _buildSettingItem(
                  icon: Icons.photo_library,
                  title: 'Media & Files',
                  subtitle: 'View shared photos, videos, and files',
                  onTap: () {
                    Navigator.pop(context);
                    _showMediaGallery(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.bookmark,
                  title: 'Bookmarked Messages',
                  subtitle: 'View your saved messages',
                  onTap: () {
                    Navigator.pop(context);
                    _showBookmarkedMessages(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage conversation notifications',
                  onTap: () {
                    Navigator.pop(context);
                    _showNotificationSettings(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.palette,
                  title: 'Chat Theme',
                  subtitle: 'Customize chat appearance',
                  onTap: () {
                    Navigator.pop(context);
                    _showThemeSettings(context);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.security,
                  title: 'Privacy & Safety',
                  subtitle: 'Block, report, or restrict user',
                  onTap: () {
                    Navigator.pop(context);
                    _showPrivacySettings(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6E3BFF)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  void _showMediaGallery(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Media gallery coming soon!')));
  }

  void _showBookmarkedMessages(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmarked messages coming soon!')),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _NotificationSettingsDialog(
        conversationId: conversationId,
        participantName: participantName,
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    showDialog(context: context, builder: (context) => _ChatThemeDialog());
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PrivacyControlsDialog(
        conversationId: conversationId,
        participantName: participantName,
      ),
    );
  }

}

class _ChatThemeDialog extends StatefulWidget {
  @override
  State<_ChatThemeDialog> createState() => _ChatThemeDialogState();
}

class _ChatThemeDialogState extends State<_ChatThemeDialog> {
  String _selectedTheme = 'default';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              _selectedTheme == 'default'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedTheme == 'default'
                  ? const Color(0xFF6E3BFF)
                  : Colors.grey,
            ),
            title: const Text('Default'),
            onTap: () {
              setState(() {
                _selectedTheme = 'default';
              });
            },
          ),
          ListTile(
            leading: Icon(
              _selectedTheme == 'dark'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedTheme == 'dark'
                  ? const Color(0xFF6E3BFF)
                  : Colors.grey,
            ),
            title: const Text('Dark'),
            onTap: () {
              setState(() {
                _selectedTheme = 'dark';
              });
            },
          ),
          ListTile(
            leading: Icon(
              _selectedTheme == 'gradient'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedTheme == 'gradient'
                  ? const Color(0xFF6E3BFF)
                  : Colors.grey,
            ),
            title: const Text('Gradient'),
            onTap: () {
              setState(() {
                _selectedTheme = 'gradient';
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Apply theme change
            Navigator.pop(context);
            _applyThemeChange(_selectedTheme);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  void _applyThemeChange(String theme) {
    // In a real app, this would update shared preferences and theme provider
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme changed to $theme'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Undo theme change
          },
        ),
      ),
    );
  }
}

class _NotificationSettingsDialog extends StatefulWidget {
  final String conversationId;
  final String participantName;

  const _NotificationSettingsDialog({
    required this.conversationId,
    required this.participantName,
  });

  @override
  State<_NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<_NotificationSettingsDialog> {
  bool _messageNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // In a real app, load from shared preferences or user settings
    // For now, use default values
  }

  void _saveNotificationSettings() {
    // In a real app, save to shared preferences or send to backend
    // For now, just show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Notifications for ${widget.participantName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Message Notifications'),
            subtitle: const Text('Get notified of new messages'),
            value: _messageNotifications,
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
              _saveNotificationSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound for notifications'),
            value: _soundEnabled,
            onChanged: _messageNotifications ? (value) {
              setState(() {
                _soundEnabled = value;
              });
              _saveNotificationSettings();
            } : null,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate for notifications'),
            value: _vibrationEnabled,
            onChanged: _messageNotifications ? (value) {
              setState(() {
                _vibrationEnabled = value;
              });
              _saveNotificationSettings();
            } : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PrivacyControlsDialog extends StatelessWidget {
  final String conversationId;
  final String participantName;

  const _PrivacyControlsDialog({
    required this.conversationId,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Privacy & Safety'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.orange),
            title: const Text('Block User'),
            subtitle: Text('Block $participantName from messaging you'),
            onTap: () {
              Navigator.pop(context);
              _showBlockDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text('Report User'),
            subtitle: Text('Report $participantName for inappropriate behavior'),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off, color: Colors.grey),
            title: const Text('Restrict User'),
            subtitle: Text('Limit $participantName\'s interaction with you'),
            onTap: () {
              Navigator.pop(context);
              _showRestrictDialog(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block $participantName? You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final reasons = [
      'Harassment',
      'Spam',
      'Inappropriate content',
      'Fake profile',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why are you reporting $participantName?'),
              const SizedBox(height: 16),
              ...reasons.map(
                (reason) => GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedReason = reason;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedReason == reason 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: selectedReason == reason
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedReason != null
                  ? () {
                      Navigator.pop(context);
                      _reportUser(context, selectedReason!);
                    }
                  : null,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestrictDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restrict User'),
        content: Text(
          'Restricting $participantName will limit their ability to see when you\'re active and read receipts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restrictUser(context);
            },
            child: const Text('Restrict'),
          ),
        ],
      ),
    );
  }

  void _blockUser(BuildContext context) {
    // In a real app, this would call backend API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$participantName has been blocked'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Unblock user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$participantName has been unblocked')),
            );
          },
        ),
      ),
    );
  }

  void _reportUser(BuildContext context, String reason) {
    // In a real app, this would send report to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$participantName has been reported for $reason'),
        action: SnackBarAction(
          label: 'Support',
          onPressed: () {
            // Navigate to support/help
          },
        ),
      ),
    );
  }

  void _restrictUser(BuildContext context) {
    // In a real app, this would call backend API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$participantName has been restricted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Unrestrict user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$participantName restrictions removed')),
            );
          },
        ),
      ),
    );
  }
}
