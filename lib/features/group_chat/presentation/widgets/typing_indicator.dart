import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Map<String, String> typingUsers; // userId -> username

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    final usernames = widget.typingUsers.values.toList();
    final typingText = _getTypingText(usernames);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _AnimatedDots(controller: _controller),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              typingText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypingText(List<String> usernames) {
    if (usernames.isEmpty) return '';
    if (usernames.length == 1) return '${usernames[0]} is typing...';
    if (usernames.length == 2) {
      return '${usernames[0]} and ${usernames[1]} are typing...';
    }
    return '${usernames[0]} and ${usernames.length - 1} others are typing...';
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (controller.value - delay).clamp(0.0, 1.0);
            final scale = (value < 0.5)
                ? 1.0 + (value * 2) * 0.5
                : 1.5 - ((value - 0.5) * 2) * 0.5;

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
