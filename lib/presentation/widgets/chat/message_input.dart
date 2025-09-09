import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onVoice;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onTyping,
    this.onCamera,
    this.onGallery,
    this.onVoice,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _isComposing = false;
  bool _showAttachments = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          if (_showAttachments) _buildAttachmentOptions(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAttachmentButton(),
              const SizedBox(width: 8),
              Expanded(child: _buildTextInput()),
              const SizedBox(width: 8),
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return IconButton(
      icon: Icon(
        _showAttachments ? Icons.close : Icons.add,
        color: Colors.grey[600],
      ),
      onPressed: () {
        setState(() {
          _showAttachments = !_showAttachments;
        });
      },
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Type a message...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: (_) => _onSendPressed(),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _isComposing ? PulseColors.primary : Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isComposing ? Icons.send : Icons.mic,
          color: Colors.white,
          size: 20,
        ),
        onPressed: _isComposing ? _onSendPressed : widget.onVoice,
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            color: Colors.blue,
            onTap: widget.onCamera,
          ),
          const SizedBox(width: 16),
          _buildAttachmentOption(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.green,
            onTap: widget.onGallery,
          ),
          const SizedBox(width: 16),
          _buildAttachmentOption(
            icon: Icons.location_on,
            label: 'Location',
            color: Colors.orange,
            onTap: () {
              // TODO: Implement location sharing
            },
          ),
        ],
      ),
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
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
