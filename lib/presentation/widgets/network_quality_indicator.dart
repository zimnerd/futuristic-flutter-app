import 'package:flutter/material.dart';
import '../../core/services/network_quality_service.dart';

/// Network quality indicator widget
///
/// Visual indicator showing real-time network quality during calls.
/// Features:
/// - Color-coded quality levels (🟢 Green, 🟡 Yellow, 🟠 Orange, 🔴 Red)
/// - Animated icon based on quality
/// - Tap to show detailed NetworkStatsOverlay modal
/// - Auto-hides when quality is excellent (optional)
/// - Real-time updates via metricsStream
class NetworkQualityIndicator extends StatefulWidget {
  /// Whether to auto-hide when quality is excellent
  final bool autoHide;

  /// Custom size for the indicator
  final double size;

  /// Callback when tapped
  final VoidCallback? onTap;

  const NetworkQualityIndicator({
    super.key,
    this.autoHide = false,
    this.size = 36.0,
    this.onTap,
  });

  @override
  State<NetworkQualityIndicator> createState() =>
      _NetworkQualityIndicatorState();
}

class _NetworkQualityIndicatorState extends State<NetworkQualityIndicator>
    with SingleTickerProviderStateMixin {
  final NetworkQualityService _networkQualityService = NetworkQualityService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for poor quality
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.yellow.shade700;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.unknown:
        return Colors.grey;
    }
  }

  IconData _getQualityIcon(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Icons.signal_cellular_alt;
      case NetworkQuality.good:
        return Icons.signal_cellular_alt_2_bar;
      case NetworkQuality.fair:
        return Icons.signal_cellular_alt_1_bar;
      case NetworkQuality.poor:
        return Icons.signal_cellular_no_sim;
      case NetworkQuality.unknown:
        return Icons.signal_cellular_connected_no_internet_0_bar;
    }
  }

  bool _shouldAnimate(NetworkQuality quality) {
    return quality == NetworkQuality.poor || quality == NetworkQuality.fair;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkQualityMetrics>(
      stream: _networkQualityService.metricsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final metrics = snapshot.data!;
        final quality = metrics.overallQuality;

        // Auto-hide when quality is excellent
        if (widget.autoHide && quality == NetworkQuality.excellent) {
          return const SizedBox.shrink();
        }

        final color = _getQualityColor(quality);
        final icon = _getQualityIcon(quality);
        final shouldAnimate = _shouldAnimate(quality);

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.0),
            ),
            child: Center(
              child: shouldAnimate
                  ? AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            icon,
                            color: color,
                            size: widget.size * 0.5,
                          ),
                        );
                      },
                    )
                  : Icon(icon, color: color, size: widget.size * 0.5),
            ),
          ),
        );
      },
    );
  }
}

/// Compact network quality indicator for minimal space usage
///
/// Shows only the quality icon without background, suitable for
/// tight spaces or when you want a minimal indicator.
class CompactNetworkQualityIndicator extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const CompactNetworkQualityIndicator({
    super.key,
    this.size = 24.0,
    this.onTap,
  });

  Color _getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.yellow.shade700;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.unknown:
        return Colors.grey;
    }
  }

  IconData _getQualityIcon(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Icons.signal_cellular_alt;
      case NetworkQuality.good:
        return Icons.signal_cellular_alt_2_bar;
      case NetworkQuality.fair:
        return Icons.signal_cellular_alt_1_bar;
      case NetworkQuality.poor:
        return Icons.signal_cellular_no_sim;
      case NetworkQuality.unknown:
        return Icons.signal_cellular_connected_no_internet_0_bar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkQualityService = NetworkQualityService();

    return StreamBuilder<NetworkQualityMetrics>(
      stream: networkQualityService.metricsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Icon(
            Icons.signal_cellular_connected_no_internet_0_bar,
            color: Colors.grey,
            size: size,
          );
        }

        final metrics = snapshot.data!;
        final quality = metrics.overallQuality;
        final color = _getQualityColor(quality);
        final icon = _getQualityIcon(quality);

        return GestureDetector(
          onTap: onTap,
          child: Icon(icon, color: color, size: size),
        );
      },
    );
  }
}

/// Network quality badge with text label
///
/// Shows quality level with colored badge and text description.
/// Useful for settings screens or detailed status displays.
class NetworkQualityBadge extends StatelessWidget {
  final bool showScore;
  final VoidCallback? onTap;

  const NetworkQualityBadge({super.key, this.showScore = false, this.onTap});

  Color _getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.yellow.shade700;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.unknown:
        return Colors.grey;
    }
  }

  String _getQualityText(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkQualityService = NetworkQualityService();

    return StreamBuilder<NetworkQualityMetrics>(
      stream: networkQualityService.metricsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Chip(
            label: Text('Unknown'),
            backgroundColor: Colors.grey,
          );
        }

        final metrics = snapshot.data!;
        final quality = metrics.overallQuality;
        final color = _getQualityColor(quality);
        final text = _getQualityText(quality);

        return GestureDetector(
          onTap: onTap,
          child: Chip(
            label: Text(
              showScore ? '$text (${metrics.qualityScore})' : text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
        );
      },
    );
  }
}
