import 'package:flutter/material.dart';
import '../../presentation/theme/pulse_colors.dart';

class ContextualActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;

  const ContextualActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? PulseColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? PulseColors.primary,
                    ),
                  ),
                )
              else
                Icon(icon, size: 14, color: textColor ?? PulseColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? PulseColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Predefined contextual action buttons for common AI actions
class AIContextualActions {
  static Widget askQuestion(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Ask Question',
      icon: Icons.help_outline,
      onPressed: onPressed,
    );
  }

  static Widget getAdvice(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Get Advice',
      icon: Icons.lightbulb_outline,
      onPressed: onPressed,
    );
  }

  static Widget explainMore(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Explain More',
      icon: Icons.info_outline,
      onPressed: onPressed,
    );
  }

  static Widget startGame(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Play Game',
      icon: Icons.games_outlined,
      onPressed: onPressed,
      backgroundColor: PulseColors.secondary.withValues(alpha: 0.1),
      textColor: PulseColors.secondary,
    );
  }

  static Widget suggestActivity(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Suggest Activity',
      icon: Icons.local_activity_outlined,
      onPressed: onPressed,
      backgroundColor: PulseColors.success.withValues(alpha: 0.1),
      textColor: PulseColors.success,
    );
  }

  static Widget compliment(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Compliment',
      icon: Icons.favorite_outline,
      onPressed: onPressed,
      backgroundColor: Colors.pink.withValues(alpha: 0.1),
      textColor: Colors.pink,
    );
  }

  static Widget joke(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Tell Joke',
      icon: Icons.sentiment_very_satisfied,
      onPressed: onPressed,
      backgroundColor: PulseColors.warning.withValues(alpha: 0.1),
      textColor: PulseColors.warning,
    );
  }

  static Widget changeSubject(VoidCallback onPressed) {
    return ContextualActionButton(
      label: 'Change Topic',
      icon: Icons.refresh,
      onPressed: onPressed,
    );
  }
}
