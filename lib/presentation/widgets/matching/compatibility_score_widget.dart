import 'package:flutter/material.dart';

/// Widget for displaying AI compatibility scores with visual indicators
class CompatibilityScoreWidget extends StatelessWidget {
  final double score;
  final double size;
  final bool showPercentage;
  final bool showLabel;

  const CompatibilityScoreWidget({
    super.key,
    required this.score,
    this.size = 60.0,
    this.showPercentage = true,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = _getScoreColor(score);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              
              // Progress circle
              Center(
                child: SizedBox(
                  width: size - 8,
                  height: size - 8,
                  child: CircularProgressIndicator(
                    value: score,
                    strokeWidth: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              
              // Score text
              if (showPercentage)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: size * 0.25,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Icon(
                        Icons.psychology,
                        size: size * 0.2,
                        color: color.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            _getScoreLabel(score),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green;
    } else if (score >= 0.6) {
      return Colors.orange;
    } else if (score >= 0.4) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getScoreLabel(double score) {
    if (score >= 0.8) {
      return 'Excellent Match';
    } else if (score >= 0.6) {
      return 'Good Match';
    } else if (score >= 0.4) {
      return 'Fair Match';
    } else {
      return 'Low Match';
    }
  }
}

/// Simplified compatibility bar for list items
class CompatibilityBar extends StatelessWidget {
  final double score;
  final bool showIcon;

  const CompatibilityBar({
    super.key,
    required this.score,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = _getScoreColor(score);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Compatibility: $percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (showIcon) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.psychology,
                size: 16,
                color: color,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green;
    } else if (score >= 0.6) {
      return Colors.orange;
    } else if (score >= 0.4) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }
}