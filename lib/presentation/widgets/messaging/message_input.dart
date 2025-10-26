import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Message input widget with text field and action buttons
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onVoiceMessage,
    this.onAttachment,
    this.placeholder = 'Type a message...',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onVoiceMessage;
  final VoidCallback? onAttachment;
  final String placeholder;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _onSend() {
    if (_hasText) {
      widget.onSend();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          if (widget.onAttachment != null)
            _buildActionButton(
              icon: Icons.add,
              onPressed: widget.onAttachment!,
              backgroundColor: Colors.grey[100]!,
              iconColor: context.onSurfaceVariantColor!,
            ),

          if (widget.onAttachment != null) const SizedBox(width: 8),

          // Text input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? PulseColors.primary
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(color: context.onSurfaceVariantColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _onSend(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button or voice message button
          AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              return _hasText
                  ? ScaleTransition(
                      scale: _sendButtonAnimation,
                      child: _buildActionButton(
                        icon: Icons.send,
                        onPressed: _onSend,
                        backgroundColor: PulseColors.primary,
                        iconColor: Colors.white,
                      ),
                    )
                  : _buildActionButton(
                      icon: Icons.mic,
                      onPressed: widget.onVoiceMessage ?? () {},
                      backgroundColor: Colors.grey[100]!,
                      iconColor: context.onSurfaceVariantColor!,
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
