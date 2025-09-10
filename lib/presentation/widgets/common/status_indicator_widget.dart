import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Real-time status indicators for online presence, typing, etc.
class StatusIndicatorWidget extends StatefulWidget {
  const StatusIndicatorWidget({
    super.key,
    required this.status,
    this.size = StatusIndicatorSize.medium,
    this.showLabel = false,
    this.customLabel,
    this.isAnimated = true,
  });

  final UserStatus status;
  final StatusIndicatorSize size;
  final bool showLabel;
  final String? customLabel;
  final bool isAnimated;

  @override
  State<StatusIndicatorWidget> createState() => _StatusIndicatorWidgetState();
}

class _StatusIndicatorWidgetState extends State<StatusIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _typingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
    
    _startAnimations();
  }

  @override
  void didUpdateWidget(StatusIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _pulseController.stop();
    _typingController.stop();
    
    if (!widget.isAnimated) return;
    
    switch (widget.status) {
      case UserStatus.online:
        _pulseController.repeat(reverse: true);
        break;
      case UserStatus.typing:
        _typingController.repeat();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();
    
    if (widget.showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(config),
          const SizedBox(width: 8),
          Text(
            widget.customLabel ?? config.label,
            style: TextStyle(
              fontSize: _getFontSize(),
              color: config.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    return _buildIndicator(config);
  }

  Widget _buildIndicator(StatusConfig config) {
    final size = _getIndicatorSize();
    
    switch (widget.status) {
      case UserStatus.online:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.color,
                boxShadow: widget.isAnimated
                    ? [
                        BoxShadow(
                          color: config.color.withValues(alpha: 0.3 * _pulseAnimation.value),
                          blurRadius: 8 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value,
                        ),
                      ]
                    : null,
              ),
            );
          },
        );
        
      case UserStatus.typing:
        return AnimatedBuilder(
          animation: _typingAnimation,
          builder: (context, child) {
            return Container(
              width: size * 1.5,
              height: size,
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(size / 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_typingAnimation.value + delay) % 1.0;
                  final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: size * 0.2,
                        height: size * 0.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: config.color,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
        
      case UserStatus.away:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: config.color,
          ),
          child: Icon(
            Icons.schedule,
            color: Colors.white,
            size: size * 0.6,
          ),
        );
        
      case UserStatus.busy:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: config.color,
          ),
          child: Icon(
            Icons.do_not_disturb,
            color: Colors.white,
            size: size * 0.6,
          ),
        );
        
      case UserStatus.offline:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        );
        
      case UserStatus.recently_active:
        return Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.color,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.schedule,
                  color: config.color,
                  size: size * 0.25,
                ),
              ),
            ),
          ],
        );
        
      case UserStatus.in_call:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: config.color,
          ),
          child: Icon(
            Icons.call,
            color: Colors.white,
            size: size * 0.6,
          ),
        );
    }
  }

  StatusConfig _getStatusConfig() {
    switch (widget.status) {
      case UserStatus.online:
        return StatusConfig(
          color: Colors.green,
          label: 'Online',
        );
      case UserStatus.typing:
        return StatusConfig(
          color: PulseColors.primary,
          label: 'Typing...',
        );
      case UserStatus.away:
        return StatusConfig(
          color: Colors.orange,
          label: 'Away',
        );
      case UserStatus.busy:
        return StatusConfig(
          color: Colors.red,
          label: 'Busy',
        );
      case UserStatus.offline:
        return StatusConfig(
          color: Colors.grey,
          label: 'Offline',
        );
      case UserStatus.recently_active:
        return StatusConfig(
          color: Colors.green.shade300,
          label: 'Recently active',
        );
      case UserStatus.in_call:
        return StatusConfig(
          color: Colors.blue,
          label: 'In call',
        );
    }
  }

  double _getIndicatorSize() {
    switch (widget.size) {
      case StatusIndicatorSize.small:
        return 8.0;
      case StatusIndicatorSize.medium:
        return 12.0;
      case StatusIndicatorSize.large:
        return 16.0;
      case StatusIndicatorSize.extraLarge:
        return 20.0;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case StatusIndicatorSize.small:
        return 10.0;
      case StatusIndicatorSize.medium:
        return 12.0;
      case StatusIndicatorSize.large:
        return 14.0;
      case StatusIndicatorSize.extraLarge:
        return 16.0;
    }
  }
}

/// Multi-status indicator for showing multiple states
class MultiStatusIndicator extends StatelessWidget {
  const MultiStatusIndicator({
    super.key,
    required this.statuses,
    this.spacing = 4.0,
    this.size = StatusIndicatorSize.small,
  });

  final List<UserStatus> statuses;
  final double spacing;
  final StatusIndicatorSize size;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statuses
          .map((status) => StatusIndicatorWidget(
                status: status,
                size: size,
                isAnimated: false,
              ))
          .expand((widget) => [widget, SizedBox(width: spacing)])
          .take(statuses.length * 2 - 1)
          .toList(),
    );
  }
}

/// User status with profile integration
class UserStatusIndicator extends StatelessWidget {
  const UserStatusIndicator({
    super.key,
    required this.status,
    required this.profileImageUrl,
    this.size = 50.0,
    this.showBorder = true,
  });

  final UserStatus status;
  final String profileImageUrl;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile image
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(
                    color: Colors.white,
                    width: 2,
                  )
                : null,
          ),
          child: ClipOval(
            child: Image.network(
              profileImageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: size,
                  height: size,
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: size * 0.6,
                  ),
                );
              },
            ),
          ),
        ),
        
        // Status indicator
        if (status != UserStatus.offline)
          Positioned(
            bottom: 0,
            right: 0,
            child: StatusIndicatorWidget(
              status: status,
              size: size < 40
                  ? StatusIndicatorSize.small
                  : size < 60
                      ? StatusIndicatorSize.medium
                      : StatusIndicatorSize.large,
            ),
          ),
      ],
    );
  }
}

enum UserStatus {
  online,
  typing,
  away,
  busy,
  offline,
  recently_active,
  in_call,
}

enum StatusIndicatorSize {
  small,
  medium,
  large,
  extraLarge,
}

class StatusConfig {
  final Color color;
  final String label;

  StatusConfig({
    required this.color,
    required this.label,
  });
}
