import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/services/boost_service.dart';
import 'boost_event.dart';
import 'boost_state.dart';

/// BLoC for managing profile boost functionality
/// 
/// Handles:
/// - Activating boosts
/// - Checking boost status
/// - Managing boost timer
/// - Handling boost expiration
class BoostBloc extends Bloc<BoostEvent, BoostState> {
  final BoostService _boostService;
  final Logger _logger = Logger();
  Timer? _statusCheckTimer;

  BoostBloc(this._boostService) : super(BoostInitial()) {
    on<ActivateBoost>(_onActivateBoost);
    on<CheckBoostStatus>(_onCheckBoostStatus);
    on<CancelBoost>(_onCancelBoost);
    on<BoostExpired>(_onBoostExpired);
  }

  /// Handle boost activation
  Future<void> _onActivateBoost(
    ActivateBoost event,
    Emitter<BoostState> emit,
  ) async {
    try {
      emit(BoostLoading());
      _logger.d('Activating profile boost...');

      final result = await _boostService.activateBoost();

      if (result['success'] == true) {
        final boostData = result;
        final startTime = DateTime.parse(boostData['startTime'] as String);
        final expiresAt = DateTime.parse(boostData['expiresAt'] as String);
        final durationMinutes = boostData['durationMinutes'] as int;

        // Calculate remaining minutes
        final now = DateTime.now();
        final remainingMinutes =
            expiresAt.difference(now).inMinutes.clamp(0, durationMinutes);

        emit(BoostActive(
          boostId: boostData['boostId'] as String,
          startTime: startTime,
          expiresAt: expiresAt,
          durationMinutes: durationMinutes,
          remainingMinutes: remainingMinutes,
        ));

        _logger.i('Boost activated successfully! Duration: $durationMinutes minutes');
        
        // Start periodic status checks
        _startStatusCheckTimer();
      } else {
        final message = result['message'] as String? ?? 'Failed to activate boost';
        _logger.e('Boost activation failed: $message');
        emit(BoostError(message));
      }
    } catch (e) {
      _logger.e('Error activating boost: $e');
      String errorMessage = 'Failed to activate boost';
      
      if (e.toString().contains('subscription')) {
        errorMessage = 'Active premium subscription required for boost';
      } else if (e.toString().contains('already')) {
        errorMessage = 'You already have an active boost running';
      }
      
      emit(BoostError(errorMessage));
    }
  }

  /// Handle boost status check
  Future<void> _onCheckBoostStatus(
    CheckBoostStatus event,
    Emitter<BoostState> emit,
  ) async {
    try {
      // Don't show loading if already have a state
      if (state is BoostInitial) {
        emit(BoostLoading());
      }

      _logger.d('Checking boost status...');
      final result = await _boostService.getBoostStatus();

      if (result == null) {
        _logger.d('No active boost found');
        emit(BoostInactive());
        _cancelStatusCheckTimer();
      } else {
        final startTime = DateTime.parse(result['startTime'] as String);
        final expiresAt = DateTime.parse(result['expiresAt'] as String);
        final durationMinutes = result['durationMinutes'] as int;
        final remainingMinutes = result['remainingMinutes'] as int;

        // Check if expired
        if (remainingMinutes <= 0 || DateTime.now().isAfter(expiresAt)) {
          _logger.d('Boost has expired');
          emit(BoostInactive());
          _cancelStatusCheckTimer();
        } else {
          _logger.d('Active boost found: $remainingMinutes minutes remaining');
          emit(BoostActive(
            boostId: result['boostId'] as String,
            startTime: startTime,
            expiresAt: expiresAt,
            durationMinutes: durationMinutes,
            remainingMinutes: remainingMinutes,
          ));
          
          // Ensure timer is running
          if (_statusCheckTimer == null || !_statusCheckTimer!.isActive) {
            _startStatusCheckTimer();
          }
        }
      }
    } catch (e) {
      _logger.e('Error checking boost status: $e');
      emit(BoostError('Failed to check boost status'));
    }
  }

  /// Handle boost cancellation
  Future<void> _onCancelBoost(
    CancelBoost event,
    Emitter<BoostState> emit,
  ) async {
    try {
      emit(BoostLoading());
      _logger.d('Canceling boost...');

      // For now, just set to inactive
      // TODO: Implement backend endpoint for cancellation if needed
      emit(BoostInactive());
      _cancelStatusCheckTimer();
      _logger.i('Boost canceled successfully');
    } catch (e) {
      _logger.e('Error canceling boost: $e');
      emit(BoostError('Failed to cancel boost'));
    }
  }

  /// Handle boost expiration
  Future<void> _onBoostExpired(
    BoostExpired event,
    Emitter<BoostState> emit,
  ) async {
    _logger.i('Boost expired');
    emit(BoostInactive());
    _cancelStatusCheckTimer();
  }

  /// Start periodic status checks (every minute)
  void _startStatusCheckTimer() {
    _cancelStatusCheckTimer();
    
    _statusCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        add(CheckBoostStatus());
      },
    );
    
    _logger.d('Boost status check timer started');
  }

  /// Cancel status check timer
  void _cancelStatusCheckTimer() {
    if (_statusCheckTimer != null) {
      _statusCheckTimer!.cancel();
      _statusCheckTimer = null;
      _logger.d('Boost status check timer canceled');
    }
  }

  @override
  Future<void> close() {
    _cancelStatusCheckTimer();
    return super.close();
  }
}
