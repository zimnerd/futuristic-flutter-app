import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';

/// Safety score widget showing user's safety rating
class SafetyScoreWidget extends StatelessWidget {
  final double score;

  const SafetyScoreWidget({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getScoreDescription(score),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PulseColors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: PulseColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          _buildScoreBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildScoreItem(
          context,
          icon: Icons.verified_user,
          label: 'Verified',
          value: score > 0.7,
        ),
        _buildScoreItem(
          context,
          icon: Icons.phone,
          label: 'Phone',
          value: score > 0.5,
        ),
        _buildScoreItem(
          context,
          icon: Icons.email,
          label: 'Email',
          value: score > 0.3,
        ),
        _buildScoreItem(
          context,
          icon: Icons.photo_camera,
          label: 'Photo',
          value: score > 0.6,
        ),
      ],
    );
  }

  Widget _buildScoreItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
  }) {
    final color = value ? Colors.green : PulseColors.onSurface.withValues(alpha: 0.4);
    
    return Column(
      children: [
        Icon(
          value ? Icons.check_circle : icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.orange.shade700;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 0.8) return 'Excellent safety rating';
    if (score >= 0.6) return 'Good safety rating';
    if (score >= 0.4) return 'Fair safety rating';
    return 'Improve your safety rating';
  }
}
