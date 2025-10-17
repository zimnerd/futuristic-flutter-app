import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/chat_bloc.dart';
import '../../data/models/conversation_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/common/robust_network_image.dart';

/// Bottom sheet for selecting conversations to forward a message to
class ConversationPickerSheet extends StatefulWidget {
  final String messageId;
  final String? currentConversationId; // Don't allow forwarding to same conversation

  const ConversationPickerSheet({
    super.key,
    required this.messageId,
    this.currentConversationId,
  });

  @override
  State<ConversationPickerSheet> createState() =>
      _ConversationPickerSheetState();
}

class _ConversationPickerSheetState extends State<ConversationPickerSheet> {
  final Set<String> _selectedConversationIds = {};
  List<ConversationModel> _allConversations = [];
  List<ConversationModel> _filteredConversations = [];
  String _searchQuery = '';
  bool _isForwarding = false;

  @override
  void initState() {
    super.initState();
    // Load conversations when sheet opens
    context.read<ChatBloc>().add(const LoadConversations());
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as "Jan 15" or "Dec 25"
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  void _selectAll() {
    setState(() {
      _selectedConversationIds.clear();
      _selectedConversationIds.addAll(_filteredConversations.map((c) => c.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedConversationIds.clear();
    });
  }

  void _filterConversations(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredConversations = _allConversations;
      } else {
        _filteredConversations = _allConversations.where((conversation) {
          final name = conversation.otherUserName.toLowerCase();
          return name.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _toggleConversationSelection(String conversationId) {
    setState(() {
      if (_selectedConversationIds.contains(conversationId)) {
        _selectedConversationIds.remove(conversationId);
      } else {
        _selectedConversationIds.add(conversationId);
      }
    });
  }

  Future<void> _handleForward() async {
    if (_selectedConversationIds.isEmpty) return;

    setState(() {
      _isForwarding = true;
    });

    // Dispatch ForwardMessage event - BlocListener will handle success/error
    context.read<ChatBloc>().add(
          ForwardMessage(
            messageId: widget.messageId,
            targetConversationIds: _selectedConversationIds.toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is MessageForwarded) {
          // Close the sheet on success
          if (mounted) {
            Navigator.of(context).pop();
            
            // Show success snackbar with conversation names
            final selectedNames = _allConversations
                .where((c) => _selectedConversationIds.contains(c.id))
                .map((c) => c.otherUserName)
                .take(3)
                .toList();

            String successMessage;
            if (selectedNames.length == 1) {
              successMessage = 'Message forwarded to ${selectedNames[0]}';
            } else if (selectedNames.length == 2) {
              successMessage =
                  'Message forwarded to ${selectedNames[0]} and ${selectedNames[1]}';
            } else if (selectedNames.length == 3 &&
                _selectedConversationIds.length == 3) {
              successMessage =
                  'Message forwarded to ${selectedNames[0]}, ${selectedNames[1]}, and ${selectedNames[2]}';
            } else {
              successMessage =
                  'Message forwarded to ${selectedNames[0]}, ${selectedNames[1]}, and ${_selectedConversationIds.length - 2} others';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                duration: const Duration(seconds: 3),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } else if (state is ChatError) {
          // Show error dialog on failure
          setState(() {
            _isForwarding = false;
          });

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Forward Failed'),
                content: const Text(
                  'Failed to forward message. Please try again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleForward();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                // Title
                const Expanded(
                  child: Text(
                    'Forward to...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Select All / Deselect All button
                if (_filteredConversations.isNotEmpty)
                  TextButton(
                    onPressed:
                        _selectedConversationIds.length ==
                            _filteredConversations.length
                        ? _deselectAll
                        : _selectAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      _selectedConversationIds.length ==
                              _filteredConversations.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                // Forward button
                TextButton(
                  onPressed: _selectedConversationIds.isEmpty || _isForwarding
                      ? null
                      : _handleForward,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _isForwarding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : Text(
                          _selectedConversationIds.isEmpty
                              ? 'Forward'
                              : 'Forward (${_selectedConversationIds.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _filterConversations('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterConversations,
            ),
          ),

          // Conversation list
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                if (state is ConversationsLoaded) {
                  // Filter out current conversation
                  _allConversations = state.conversations
                      .where((conv) => conv.id != widget.currentConversationId)
                      .toList();

                  // Apply search filter if needed
                  if (_searchQuery.isEmpty) {
                    _filteredConversations = _allConversations;
                  } else {
                    _filteredConversations = _allConversations.where((conversation) {
                      final name = conversation.otherUserName.toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }

                  if (_filteredConversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.chat_bubble_outline
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No conversations yet'
                                : 'No conversations found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _filteredConversations.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final conversation = _filteredConversations[index];
                      final isSelected = _selectedConversationIds.contains(conversation.id);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleConversationSelection(conversation.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Avatar
                                ProfileNetworkImage(
                                  imageUrl: conversation.otherUserAvatar,
                                  size: 48,
                                ),
                                const SizedBox(width: 12),
                                // Name, last message, and timestamp
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              conversation.otherUserName.isEmpty
                                                  ? 'Unknown'
                                                  : conversation.otherUserName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatRelativeTime(
                                              conversation.lastMessageTime,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (conversation.lastMessage.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          conversation.lastMessage,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load conversations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(const LoadConversations());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
