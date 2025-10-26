import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Countdown timer widget for speed dating events
class EventCountdownTimer extends StatefulWidget {
  final DateTime eventStartTime;
  final bool isCompact;

  const EventCountdownTimer({
    super.key,
    required this.eventStartTime,
    this.isCompact = false,
  });

  @override
  State<EventCountdownTimer> createState() => _EventCountdownTimerState();
}

class _EventCountdownTimerState extends State<EventCountdownTimer> {
  late Timer _timer;
  Duration _timeUntilEvent = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        _timeUntilEvent = widget.eventStartTime.difference(now);
      });
    }
  }

  String _formatTimeRemaining() {
    if (_timeUntilEvent.isNegative) {
      return 'Event started';
    }

    final days = _timeUntilEvent.inDays;
    final hours = _timeUntilEvent.inHours % 24;
    final minutes = _timeUntilEvent.inMinutes % 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} ${hours}h';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} ${minutes}m';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  Color _getTimerColor() {
    if (_timeUntilEvent.isNegative) {
      return context.outlineColor;
    }
    
    final hoursRemaining = _timeUntilEvent.inHours;
    if (hoursRemaining < 1) {
      return Colors.red;
    } else if (hoursRemaining < 24) {
      return Colors.orange;
    } else {
      return PulseColors.primary;
    }
  }

  IconData _getTimerIcon() {
    if (_timeUntilEvent.isNegative) {
      return Icons.event_busy;
    }
    
    final hoursRemaining = _timeUntilEvent.inHours;
    if (hoursRemaining < 1) {
      return Icons.timer;
    } else if (hoursRemaining < 24) {
      return Icons.schedule;
    } else {
      return Icons.event_available;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactTimer();
    }
    return _buildFullTimer();
  }

  Widget _buildCompactTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getTimerColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTimerColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTimerIcon(),
            size: 14,
            color: _getTimerColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _formatTimeRemaining(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getTimerColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTimer() {
    final color = _getTimerColor();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTimerIcon(),
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timeUntilEvent.isNegative
                      ? 'Event has started'
                      : 'Starts in',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurfaceVariantColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeRemaining(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (!_timeUntilEvent.isNegative && _timeUntilEvent.inHours < 24)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _timeUntilEvent.inHours < 1 ? 'URGENT' : 'SOON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
