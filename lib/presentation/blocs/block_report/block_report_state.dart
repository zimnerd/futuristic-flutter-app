part of 'block_report_bloc.dart';

/// Base class for block/report states
abstract class BlockReportState {}

/// Initial state
class BlockReportInitial extends BlockReportState {}

/// Loading state
class BlockReportLoading extends BlockReportState {}

/// State when user has been blocked successfully
class UserBlocked extends BlockReportState {
  final String blockedUserId;

  UserBlocked({required this.blockedUserId});
}

/// State when user has been unblocked successfully
class UserUnblocked extends BlockReportState {
  final String unblockedUserId;

  UserUnblocked({required this.unblockedUserId});
}

/// State when blocked users list has been loaded
class BlockedUsersLoaded extends BlockReportState {
  final List<String> blockedUserIds;

  BlockedUsersLoaded({required this.blockedUserIds});
}

/// State when user has been reported successfully
class UserReported extends BlockReportState {
  final String reportedUserId;

  UserReported({required this.reportedUserId});
}

/// Error state
class BlockReportError extends BlockReportState {
  final String message;

  BlockReportError({required this.message});
}
