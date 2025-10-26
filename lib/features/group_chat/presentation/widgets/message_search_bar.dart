import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

class MessageSearchBar extends StatefulWidget {
  final Function(String query) onSearch;
  final VoidCallback onClose;
  final int? resultCount;

  const MessageSearchBar({
    super.key,
    required this.onSearch,
    required this.onClose,
    this.resultCount,
  });

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Colors.black.a * 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _controller.clear();
              widget.onClose();
            },
          ),

          // Search input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                border: InputBorder.none,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearch('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                widget.onSearch(value);
                setState(() {});
              },
            ),
          ),

          // Result count
          if (widget.resultCount != null && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${widget.resultCount} results',
                style: TextStyle(
                  fontSize: 12,
                  color: context.onSurfaceVariantColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
