import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/boost/boost_bloc.dart';
import '../../blocs/boost/boost_event.dart';
import '../../blocs/boost/boost_state.dart';
import '../../theme/pulse_colors.dart';

/// Banner widget that displays active boost status with countdown timer
///
/// Shows:
/// - Boost active indicator
/// - Remaining time countdown (updates every second)
/// - Progress bar
/// - Boost benefits (profile views)
/// - Pulse animation on boost icon
///
/// QUICK WIN Feature 3: Enhanced with:
/// - Real-time countdown timer
/// - Poll status every 30 seconds
/// - Pulse animation
class BoostBannerWidget extends StatefulWidget {
  const BoostBannerWidget({super.key});

  @override
  State<BoostBannerWidget> createState() => _BoostBannerWidgetState();
}

class _BoostBannerWidgetState extends State<BoostBannerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Timer? _pollTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  DateTime? _lastPollTime;
  final ValueNotifier<int> _tickNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _pulseController.dispose();
    _tickNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoostBloc, BoostState>(
      builder: (context, state) {
        if (state is! BoostActive) {
          // Stop timers when boost is not active
          _countdownTimer?.cancel();
          _pollTimer?.cancel();
          return const SizedBox.shrink();
        }

        // Start countdown timer to update UI every second
        _startCountdownTimer();

        // Start poll timer to check boost status every 30 seconds
        _startPollTimer(context);

        // Use ValueListenableBuilder to rebuild only time display
        return ValueListenableBuilder<int>(
          valueListenable: _tickNotifier,
          builder: (context, tick, child) {
            // Calculate real-time remaining time
            final now = DateTime.now();
            final remainingDuration = state.expiresAt.difference(now);
            final remainingMinutes = remainingDuration.inMinutes.clamp(
              0,
              state.durationMinutes,
            );
            final remainingSeconds = remainingDuration.inSeconds % 60;

            // Calculate progress
            final elapsed = now.difference(state.startTime);
            final totalDuration = state.expiresAt.difference(state.startTime);
            final progress = (elapsed.inSeconds / totalDuration.inSeconds)
                .clamp(0.0, 1.0);

            final isExpiringSoon = remainingMinutes <= 5;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpiringSoon
                      ? [PulseColors.warning, PulseColors.warningDark]
                      : [PulseColors.primary, PulseColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isExpiringSoon
                                ? PulseColors.warning
                                : PulseColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with icon and time
                  Row(
                    children: [
                      // Boost icon with pulse animation
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Boost active text
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Boost Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'You\'re getting 10x more visibility!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Remaining time with seconds
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatRemainingTimeWithSeconds(
                                remainingMinutes,
                                remainingSeconds,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                    ),
                  ),

                  if (isExpiringSoon) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Boost ending soon!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Start countdown timer to update remaining time display every second
  void _startCountdownTimer() {
    if (_countdownTimer?.isActive == true) return;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Increment tick to trigger ValueListenableBuilder rebuild
        _tickNotifier.value++;
      } else {
        timer.cancel();
      }
    });
  }

  /// Start poll timer to check boost status every 30 seconds
  void _startPollTimer(BuildContext context) {
    final now = DateTime.now();

    // Only poll if we haven't polled in the last 25 seconds
    if (_lastPollTime != null &&
        now.difference(_lastPollTime!).inSeconds < 25) {
      return;
    }

    // Cancel existing timer
    _pollTimer?.cancel();

    // Poll immediately if this is the first time
    if (_lastPollTime == null) {
      context.read<BoostBloc>().add(CheckBoostStatus());
      _lastPollTime = now;
    }

    // Setup periodic polling every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        context.read<BoostBloc>().add(CheckBoostStatus());
        _lastPollTime = DateTime.now();
      } else {
        timer.cancel();
      }
    });
  }

  /// Format remaining time with seconds: "23:45" or "5:30"
  String _formatRemainingTimeWithSeconds(int minutes, int seconds) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    } else {
      final formattedSeconds = seconds.toString().padLeft(2, '0');
      return '$minutes:$formattedSeconds';
    }
  }
}
