import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../theme/pulse_colors.dart';

/// Enhanced message composer with voice, attachments, and rich features
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.conversationId,
    required this.senderId,
    this.replyToMessage,
    this.onCancelReply,
  });

  final String conversationId;
  final String senderId;
  final Message? replyToMessage;
  final VoidCallback? onCancelReply;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _sendButtonController;
  late AnimationController _attachmentController;
  late Animation<double> _sendButtonScale;
  late Animation<double> _attachmentRotation;
  
  bool _isComposing = false;
  bool _isRecording = false;
  bool _showAttachments = false;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sendButtonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );
    
    _attachmentRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _attachmentController, curve: Curves.easeInOut),
    );
    
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _textController.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      
      if (isComposing) {
        _sendButtonController.forward();
        context.read<MessagingBloc>().add(
          StartTyping(conversationId: widget.conversationId),
        );
      } else {
        _sendButtonController.reverse();
        context.read<MessagingBloc>().add(
          StopTyping(conversationId: widget.conversationId),
        );
      }
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showAttachments) {
      _hideAttachments();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<MessagingBloc>().add(
      SendMessage(
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        content: text,
        type: MessageType.text,
        replyToMessageId: widget.replyToMessage?.id,
      ),
    );

    _textController.clear();
    _focusNode.unfocus();
    
    if (widget.replyToMessage != null) {
      widget.onCancelReply?.call();
    }
  }

  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
    
    if (_showAttachments) {
      _attachmentController.forward();
      _focusNode.unfocus();
    } else {
      _attachmentController.reverse();
    }
  }

  void _hideAttachments() {
    if (_showAttachments) {
      setState(() {
        _showAttachments = false;
      });
      _attachmentController.reverse();
    }
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    _hideAttachments();
    // TODO: Implement voice recording logic
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Implement voice recording stop and send logic
  }

  void _cancelVoiceRecording() {
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    // TODO: Implement voice recording cancellation
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Reply preview
            if (widget.replyToMessage != null)
              _buildReplyPreview(),
            
            // Main composer
            Padding(
              padding: const EdgeInsets.all(12),
              child: _isRecording 
                  ? _buildVoiceRecorder()
                  : _buildTextComposer(),
            ),
            
            // Attachments panel
            if (_showAttachments)
              _buildAttachmentsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final message = widget.replyToMessage!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.05),
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: const BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                'Replying to message',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PulseColors.primary,
                ),
              ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onCancelReply,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attachment button
        AnimatedBuilder(
          animation: _attachmentRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _attachmentRotation.value * 2 * 3.14159,
              child: IconButton(
                icon: Icon(
                  _showAttachments ? Icons.close : Icons.add,
                  color: _showAttachments ? PulseColors.primary : Colors.grey[600],
                ),
                onPressed: _toggleAttachments,
              ),
            );
          },
        ),
        
        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Send/Voice button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isComposing
              ? ScaleTransition(
                  scale: _sendButtonScale,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: PulseColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                )
              : GestureDetector(
                  onTapDown: (_) => _startVoiceRecording(),
                  onTapUp: (_) => _stopVoiceRecording(),
                  onTapCancel: _cancelVoiceRecording,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVoiceRecorder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Recording duration
          Text(
            _formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          
          const Spacer(),
          
          // Cancel button
          GestureDetector(
            onTap: _cancelVoiceRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send button
          GestureDetector(
            onTap: _stopVoiceRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () {
                  // TODO: Implement camera
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.green,
                onTap: () {
                  // TODO: Implement gallery
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () {
                  // TODO: Implement video
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.location_on,
                label: 'Location',
                color: Colors.purple,
                onTap: () {
                  // TODO: Implement location
                  _hideAttachments();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: Colors.orange,
                onTap: () {
                  // TODO: Implement document
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.music_note,
                label: 'Audio',
                color: Colors.teal,
                onTap: () {
                  // TODO: Implement audio
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.person,
                label: 'Contact',
                color: Colors.indigo,
                onTap: () {
                  // TODO: Implement contact
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.gif,
                label: 'GIF',
                color: Colors.pink,
                onTap: () {
                  // TODO: Implement GIF picker
                  _hideAttachments();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
