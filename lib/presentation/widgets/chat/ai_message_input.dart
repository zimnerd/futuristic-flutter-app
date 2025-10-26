import 'package:flutter/material.dart';

import '../../../data/models/chat_model.dart';
import '../../theme/pulse_colors.dart';
import 'rich_ai_chat_assistant_modal.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

class AiMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onVideoCamera;
  final VoidCallback? onVideoGallery;
  final VoidCallback? onVoice;
  final String? lastReceivedMessage;
  final String chatId;
  final String? currentUserId;
  final String? matchUserId;
  final MessageModel? replyToMessage;
  final VoidCallback? onCancelReply;

  const AiMessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.chatId,
    this.onTyping,
    this.onCamera,
    this.onGallery,
    this.onVideoCamera,
    this.onVideoGallery,
    this.onVoice,
    this.lastReceivedMessage,
    this.currentUserId,
    this.matchUserId,
    this.replyToMessage,
    this.onCancelReply,
  });

  @override
  State<AiMessageInput> createState() => _AiMessageInputState();
}

class _AiMessageInputState extends State<AiMessageInput>
    with TickerProviderStateMixin {
  bool _isComposing = false;
  bool _showAttachments = false;
  bool _showAiSuggestions = false;
  final bool _isLoadingSuggestions = false;

  final List<String> _suggestions = [];

  late AnimationController _aiGlowController;
  late AnimationController _suggestionController;
  late Animation<double> _aiGlowAnimation;
  late Animation<double> _suggestionAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);

    // Initialize animations for futuristic effects
    _aiGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _suggestionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _aiGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _aiGlowController, curve: Curves.easeInOut),
    );
    _suggestionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _suggestionController, curve: Curves.easeOutBack),
    );

    _aiGlowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _aiGlowController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = widget.controller.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
    widget.onTyping?.call();
  }

  void _onSendPressed() {
    if (_isComposing) {
      widget.onSend();
      setState(() {
        _showAiSuggestions = false;
        _suggestions.clear();
      });
    }
  }

  void _useSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    setState(() {
      _isComposing = true;
    });
  }

  void _showAiCustomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RichAiChatAssistantModal(
        conversationId: widget.chatId,
        currentUserId: widget.currentUserId,
        matchUserId: widget.matchUserId,
        specificMessage: widget.controller.text.isNotEmpty
            ? widget.controller.text
            : null,
        onClose: () => Navigator.of(context).pop(),
        onApplyToChat: (message) {
          widget.controller.text = message;
          setState(() {
            _isComposing = message.isNotEmpty;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get keyboard height for proper padding on iOS
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        keyboardPadding > 0 ? keyboardPadding + 8 : 8,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
      ),
      child: Column(
        children: [
          if (widget.replyToMessage != null) _buildReplyPreview(),
          if (_showAiSuggestions) _buildAiSuggestions(),
          if (_showAttachments) _buildAttachmentOptions(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAttachmentButton(),
              const SizedBox(width: 12),
              Expanded(child: _buildTextInput()),
              const SizedBox(width: 12),
              if (!_isComposing) ...[
                _buildAiButton(),
                const SizedBox(width: 8),
              ],
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiButton() {
    return AnimatedBuilder(
      animation: _aiGlowAnimation,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PulseColors.primary.withValues(
                  alpha: 0.7 + 0.3 * _aiGlowAnimation.value,
                ),
                PulseColors.secondary.withValues(
                  alpha: 0.7 + 0.3 * _aiGlowAnimation.value,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PulseColors.primary.withValues(
                  alpha: 0.3 * _aiGlowAnimation.value,
                ),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isLoadingSuggestions ? Icons.auto_awesome : Icons.psychology,
              color: context.onSurfaceColor,
              size: 20,
            ),
            onPressed: _isLoadingSuggestions
                ? null
                : () {
                    // Always show the modal directly for better UX
                    _showAiCustomModal();
                  },
          ),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    final message = widget.replyToMessage!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: PulseColors.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: PulseColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderUsername}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content?.isNotEmpty == true
                      ? (message.content!.length > 50
                            ? '${message.content!.substring(0, 50)}...'
                            : message.content!)
                      : 'Media message',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurfaceVariantColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onCancelReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.outlineColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: context.onSurfaceVariantColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestions() {
    return AnimatedBuilder(
      animation: _suggestionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _suggestionAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PulseColors.primary.withValues(alpha: 0.1),
                  PulseColors.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PulseColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: PulseColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Suggestions',
                      style: TextStyle(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _showAiSuggestions = false;
                          _suggestions.clear();
                        });
                        _suggestionController.reverse();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoadingSuggestions)
                  _buildLoadingIndicator()
                else
                  _buildSuggestionsList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 60,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is thinking...',
              style: TextStyle(
                color: PulseColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      children: _suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _useSuggestion(suggestion),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.outlineColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: context.outlineColor.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _showAttachments
            ? PulseColors.primary.withValues(alpha: 0.1)
            : Colors.grey[100],
        shape: BoxShape.circle,
        border: _showAttachments
            ? Border.all(
                color: PulseColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: IconButton(
        icon: AnimatedRotation(
          turns: _showAttachments ? 0.125 : 0, // 45 degree rotation
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _showAttachments ? Icons.close_rounded : Icons.add_rounded,
            color: _showAttachments
                ? PulseColors.primary
                : context.onSurfaceVariantColor,
            size: 20,
          ),
        ),
        onPressed: () {
          setState(() {
            _showAttachments = !_showAttachments;
          });
        },
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isComposing
              ? PulseColors.primary.withValues(alpha: 0.3)
              : context.outlineColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: context.onSurfaceColor,
        ),
        decoration: InputDecoration(
          hintText: 'Type a message...',
          hintStyle: TextStyle(color: context.onSurfaceVariantColor, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          suffixIcon: _isComposing
              ? GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    setState(() {
                      _isComposing = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.outlineColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: context.outlineColor,
                    ),
                  ),
                )
              : null,
        ),
        onSubmitted: (_) => _onSendPressed(),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: _isComposing
            ? LinearGradient(
                colors: [
                  PulseColors.primary,
                  PulseColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isComposing
            ? null
            : context.outlineColor.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        boxShadow: _isComposing
            ? [
                BoxShadow(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isComposing ? Icons.send_rounded : Icons.mic_rounded,
            key: ValueKey(_isComposing),
            color: _isComposing ? Colors.white : context.onSurfaceVariantColor,
            size: 22,
          ),
        ),
        onPressed: _isComposing ? _onSendPressed : widget.onVoice,
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _showAttachments ? 72 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: _showAttachments
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Photo',
                    color: Colors.blue,
                    onTap: widget.onCamera,
                  ),
                  const SizedBox(width: 16),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.green,
                    onTap: widget.onGallery,
                  ),
                  const SizedBox(width: 16),
                  _buildAttachmentOption(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: context.errorColor,
                    onTap: widget.onVideoCamera,
                  ),
                  const SizedBox(width: 16),
                  _buildAttachmentOption(
                    icon: Icons.video_library_rounded,
                    label: 'Videos',
                    color: Colors.purple,
                    onTap: widget.onVideoGallery,
                  ),
                  const SizedBox(width: 16),
                  _buildAttachmentOption(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    color: Colors.orange,
                    onTap: () {
                      setState(() {
                        _showAttachments = false;
                      });
                      PulseToast.info(
                        context,
                        message: 'Sharing current location...',
                      );
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: context.onSurfaceColor, size: 24),
      ),
    );
  }
}
