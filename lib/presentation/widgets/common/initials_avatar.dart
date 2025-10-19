import 'package:flutter/material.dart';
import 'dart:math';

/// Generates a consistent color from a string (e.g., group name)
Color _generateColorFromString(String text) {
  final hash = text.hashCode;
  final random = Random(hash);

  // Generate pleasant colors with good contrast
  final hue = random.nextDouble() * 360;
  return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
}

/// Extracts initials from a string (e.g., "Marketing Team" -> "MT")
String _generateInitials(String name) {
  if (name.isEmpty) return '??';

  final words = name.trim().split(RegExp(r'\s+'));

  if (words.length >= 2) {
    // Take first letter of first two words
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  } else if (words.length == 1 && words[0].length >= 2) {
    // Take first two letters of single word
    return words[0].substring(0, 2).toUpperCase();
  } else if (words.length == 1 && words[0].length == 1) {
    // Single letter - duplicate it
    return words[0][0].toUpperCase() * 2;
  }

  return '??';
}

/// A circular avatar widget that displays initials when no image is provided.
/// Generates a consistent color based on the name for visual distinction.
///
/// Example usage:
/// ```dart
/// InitialsAvatar(
///   name: 'Marketing Team',
///   imageUrl: group.imageUrl,
///   radius: 20,
/// )
/// ```
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Widget? child;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.textStyle,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // If image URL is provided, use NetworkImage
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: backgroundColor ?? _generateColorFromString(name),
        onBackgroundImageError: (_, _) {
          // Fallback to initials if image fails to load
        },
        child: child,
      );
    }

    // Otherwise, display initials with generated color
    final initials = _generateInitials(name);
    final color = backgroundColor ?? _generateColorFromString(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child:
          child ??
          Text(
            initials,
            style:
                textStyle ??
                TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.6, // Scale font size with radius
                  fontWeight: FontWeight.bold,
                ),
          ),
    );
  }
}
