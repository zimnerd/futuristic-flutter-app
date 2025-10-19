part of 'block_report_bloc.dart';

/// Base class for block/report events
abstract class BlockReportEvent {}

/// Event to block a user
class BlockUser extends BlockReportEvent {
  final String blockedUserId;
  final String? reason;

  BlockUser({required this.blockedUserId, this.reason});
}

/// Event to unblock a user
class UnblockUser extends BlockReportEvent {
  final String blockedUserId;

  UnblockUser({required this.blockedUserId});
}

/// Event to load blocked users list
class LoadBlockedUsers extends BlockReportEvent {}

/// Event to report a user
class ReportUser extends BlockReportEvent {
  final String reportedUserId;
  final String reason;
  final String? description;
  final String? type;

  ReportUser({
    required this.reportedUserId,
    required this.reason,
    this.description,
    this.type = 'profile',
  });
}
