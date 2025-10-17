import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Animated typing indicator with three pulsing dots
/// Displays typing status for one or multiple users
class AnimatedTypingIndicator extends StatefulWidget {
  /// List of user names currently typing
  final List<String> typingUsers;
  
  /// Optional custom color for the dots
  final Color? dotColor;
  
  /// Optional custom text color
  final Color? textColor;
  
  const AnimatedTypingIndicator({
    super.key,
    required this.typingUsers,
    this.dotColor,
    this.textColor,
  });

  @override
  State<AnimatedTypingIndicator> createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller with 1.2 second duration
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(); // Repeat indefinitely

    // Create staggered animations for each dot (0ms, 400ms, 800ms delays)
    _dotAnimations = List.generate(3, (index) {
      // Each dot starts at a different point in the cycle
      final begin = (index * 0.33).clamp(0.0, 1.0);
      
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          begin,
          (begin + 0.66).clamp(0.0, 1.0),
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get display text based on number of typing users
  String _getTypingText() {
    if (widget.typingUsers.isEmpty) return '';
    
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} is typing';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0]} and ${widget.typingUsers[1]} are typing';
    } else {
      return '${widget.typingUsers[0]} and ${widget.typingUsers.length - 1} others are typing';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Three animated dots
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _dotAnimations[index],
              builder: (context, child) {
                // Scale animation from 0.5 to 1.0
                final scale = 0.5 + (_dotAnimations[index].value * 0.5);
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < 2 ? 4 : 8, // Space between dots and text
                    ),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.dotColor ?? PulseColors.onSurfaceVariant.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
          
          // Typing text
          Flexible(
            child: Text(
              _getTypingText(),
              style: TextStyle(
                fontSize: 13,
                color: widget.textColor ?? PulseColors.onSurfaceVariant.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
