import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'dart:io';

import '../../../data/models/ai_companion.dart';
import '../../blocs/ai_companion/ai_companion_bloc.dart';
import '../../blocs/ai_companion/ai_companion_event.dart';
import '../../blocs/ai_companion/ai_companion_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/chat/ai_message_input.dart';
import '../../theme/pulse_colors.dart';

/// Chat screen for AI companion conversations
class AiCompanionChatScreen extends StatefulWidget {
  final AICompanion companion;

  const AiCompanionChatScreen({
    super.key,
    required this.companion,
  });

  @override
  State<AiCompanionChatScreen> createState() => _AiCompanionChatScreenState();
}

class _AiCompanionChatScreenState extends State<AiCompanionChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiCompanionBloc>().add(
      LoadConversationHistory(companionId: widget.companion.id),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.companion.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.companion.avatarUrl)
                  : null,
              backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
              child: widget.companion.avatarUrl.isEmpty
                  ? Text(
                      widget.companion.personality.emoji,
                      style: const TextStyle(fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.companion.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.companion.personality.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showCompanionInfo(),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: BlocBuilder<AiCompanionBloc, AiCompanionState>(
              builder: (context, state) {
                if (state is AiCompanionLoading) {
                  return const Center(child: PulseLoadingWidget());
                }

                if (state is AiCompanionError) {
                  return PulseErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<AiCompanionBloc>().add(
                        LoadConversationHistory(companionId: widget.companion.id),
                      );
                    },
                  );
                }

                if (state is AiCompanionLoaded) {
                  return _buildMessagesList(state.conversationHistory);
                }

                return const Center(child: PulseLoadingWidget());
              },
            ),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<CompanionMessage> messages) {
    if (messages.isEmpty) {
      return _buildEmptyChat();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.companion.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.companion.avatarUrl)
                  : null,
              backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
              child: widget.companion.avatarUrl.isEmpty
                  ? Text(
                      widget.companion.personality.emoji,
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Start chatting with ${widget.companion.name}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.companion.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSuggestedMessages(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedMessages() {
    final suggestions = [
      'Hi! How are you?',
      'I need dating advice',
      'Help me with my profile',
      'Practice conversation',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return GestureDetector(
          onTap: () => _sendMessage(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PulseColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              suggestion,
              style: TextStyle(
                color: PulseColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(CompanionMessage message) {
    final isUser = !message.isFromCompanion;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser 
            ? PulseColors.primary
            : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return BlocBuilder<AiCompanionBloc, AiCompanionState>(
      builder: (context, state) {
        String? lastAiMessage;

        // Get the last AI message for context
        if (state is AiCompanionLoaded &&
            state.conversationHistory.isNotEmpty) {
          final aiMessages = state.conversationHistory
              .where((msg) => msg.isFromCompanion)
              .toList();
          if (aiMessages.isNotEmpty) {
            lastAiMessage = aiMessages.last.content;
          }
        }

        return AiMessageInput(
          controller: _messageController,
          onSend: () {
            final message = _messageController.text.trim();
            if (message.isNotEmpty) {
              _sendMessage(message);
            }
          },
          chatId: 'ai_companion_${widget.companion.id}',
          lastReceivedMessage: lastAiMessage,
          onTyping: () {
            // Handle typing indicator if needed
          },
          onCamera: () async {
            await _handleCameraImage();
          },
          onGallery: () async {
            await _handleGalleryImage();
          },
          onVoice: () async {
            await _handleVoiceMessage();
          },
        );
      },
    );
  }

  void _sendMessage(String message) {
    context.read<AiCompanionBloc>().add(
      SendMessageToCompanion(
        companionId: widget.companion.id,
        message: message,
      ),
    );
    _messageController.clear();
    
    // Scroll to bottom after sending
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

  Future<void> _handleCameraImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        // Send image message to AI companion
        if (mounted) {
          context.read<AiCompanionBloc>().add(
            SendImageMessage(
              companionId: widget.companion.id,
              imageFile: imageFile,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    }
  }

  Future<void> _handleGalleryImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        // Send image message to AI companion
        if (mounted) {
          context.read<AiCompanionBloc>().add(
            SendImageMessage(
              companionId: widget.companion.id,
              imageFile: imageFile,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _handleVoiceMessage() async {
    try {
      final record = AudioRecorder();

      // Check permission
      if (await record.hasPermission()) {
        // Show recording dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Recording Voice Message'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Tap stop when finished'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final path = await record.stop();
                    Navigator.of(dialogContext).pop();

                    if (path != null && mounted) {
                      final File audioFile = File(path);
                      // Send audio message to AI companion
                      context.read<AiCompanionBloc>().add(
                        SendAudioMessage(
                          companionId: widget.companion.id,
                          audioFile: audioFile,
                        ),
                      );
                    }
                  },
                  child: const Text('Stop Recording'),
                ),
              ],
            ),
          );

          // Start recording
          await record.start(
            const RecordConfig(),
            path: '/tmp/voice_message.m4a',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to record audio: $e')));
      }
    }
  }

  void _showCompanionInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.companion.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.companion.avatarUrl)
                  : null,
              backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
              child: widget.companion.avatarUrl.isEmpty
                  ? Text(
                      widget.companion.personality.emoji,
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.companion.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.companion.personality.displayName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.companion.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoStat(
                  'Conversations',
                  widget.companion.conversationCount.toString(),
                  Icons.chat_bubble_outline,
                ),
                _buildInfoStat(
                  'Relationship Level',
                  'Level ${widget.companion.relationshipLevel}',
                  Icons.favorite_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: PulseColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
