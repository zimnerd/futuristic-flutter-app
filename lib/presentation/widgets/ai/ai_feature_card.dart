import 'package:flutter/material.dart';

/// Reusable AI feature card widget with futuristic design
class AiFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient iconGradient;
  final bool enabled;
  final VoidCallback onTap;
  final List<String> features;

  const AiFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconGradient,
    required this.enabled,
    required this.onTap,
    this.features = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: enabled ? null : Colors.grey.shade900.withValues(alpha: 0.3),
          border: Border.all(
            color: enabled 
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon with gradient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: enabled ? iconGradient : null,
                    color: enabled ? null : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: enabled ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: enabled 
                              ? Colors.white70 
                              : Colors.grey.shade500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: enabled ? Colors.white60 : Colors.grey.shade600,
                  size: 24,
                ),
              ],
            ),
            
            // Features list
            if (features.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((feature) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: enabled 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: enabled 
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: enabled ? Colors.white70 : Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
            ],
            
            // Status indicator
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  enabled ? 'Active' : 'Disabled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: enabled ? Colors.green : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}