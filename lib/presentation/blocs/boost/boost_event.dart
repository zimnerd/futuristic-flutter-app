/// Boost feature events for BLoC pattern
/// 
/// Handles events related to profile boost functionality:
/// - Activating a boost
/// - Checking boost status
/// - Canceling an active boost
abstract class BoostEvent {}

/// Event to activate a profile boost (premium feature)
class ActivateBoost extends BoostEvent {}

/// Event to check current boost status
class CheckBoostStatus extends BoostEvent {}

/// Event to cancel an active boost (if supported)
class CancelBoost extends BoostEvent {}

/// Event to handle boost expiration
class BoostExpired extends BoostEvent {}
