import 'package:equatable/equatable.dart';

/// Boost feature states for BLoC pattern
/// 
/// Represents the various states of the profile boost feature:
/// - Initial state before any boost actions
/// - Loading state during API calls
/// - Active boost state with remaining time
/// - Inactive boost state
/// - Error state with error message
abstract class BoostState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state when no boost status has been checked
class BoostInitial extends BoostState {}

/// Loading state during boost activation or status check
class BoostLoading extends BoostState {}

/// Active boost state with boost details
class BoostActive extends BoostState {
  final String boostId;
  final DateTime startTime;
  final DateTime expiresAt;
  final int durationMinutes;
  final int remainingMinutes;

  BoostActive({
    required this.boostId,
    required this.startTime,
    required this.expiresAt,
    required this.durationMinutes,
    required this.remainingMinutes,
  });

  @override
  List<Object?> get props => [
        boostId,
        startTime,
        expiresAt,
        durationMinutes,
        remainingMinutes,
      ];

  /// Get remaining time as duration
  Duration get remainingDuration => Duration(minutes: remainingMinutes);

  /// Check if boost is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    final total = durationMinutes * 60; // Total seconds
    final remaining = remainingMinutes * 60; // Remaining seconds
    return 1.0 - (remaining / total).clamp(0.0, 1.0);
  }
}

/// Inactive boost state (no active boost)
class BoostInactive extends BoostState {}

/// Error state with error message
class BoostError extends BoostState {
  final String message;

  BoostError(this.message);

  @override
  List<Object?> get props => [message];
}
