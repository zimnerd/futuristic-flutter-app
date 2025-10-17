import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../core/utils/logger.dart';

part 'block_report_event.dart';
part 'block_report_state.dart';

/// BLoC for handling block and report functionality
class BlockReportBloc extends Bloc<BlockReportEvent, BlockReportState> {
  final UserRepository userRepository;
  final String currentUserId;

  BlockReportBloc({
    required this.userRepository,
    required this.currentUserId,
  }) : super(BlockReportInitial()) {
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<LoadBlockedUsers>(_onLoadBlockedUsers);
    on<ReportUser>(_onReportUser);
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<BlockReportState> emit,
  ) async {
    emit(BlockReportLoading());

    try {
      await userRepository.blockUser(currentUserId, event.blockedUserId);
      AppLogger.info('User blocked successfully: ${event.blockedUserId}');
      emit(UserBlocked(blockedUserId: event.blockedUserId));
    } catch (e) {
      AppLogger.error('Failed to block user: $e');
      emit(BlockReportError(message: 'Failed to block user. Please try again.'));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<BlockReportState> emit,
  ) async {
    emit(BlockReportLoading());

    try {
      await userRepository.unblockUser(currentUserId, event.blockedUserId);
      AppLogger.info('User unblocked successfully: ${event.blockedUserId}');
      emit(UserUnblocked(unblockedUserId: event.blockedUserId));
      
      // Reload blocked users list
      add(LoadBlockedUsers());
    } catch (e) {
      AppLogger.error('Failed to unblock user: $e');
      emit(BlockReportError(message: 'Failed to unblock user. Please try again.'));
    }
  }

  Future<void> _onLoadBlockedUsers(
    LoadBlockedUsers event,
    Emitter<BlockReportState> emit,
  ) async {
    emit(BlockReportLoading());

    try {
      final blockedUserIds = await userRepository.getBlockedUsers(currentUserId);
      AppLogger.info('Loaded ${blockedUserIds.length} blocked users');
      emit(BlockedUsersLoaded(blockedUserIds: blockedUserIds));
    } catch (e) {
      AppLogger.error('Failed to load blocked users: $e');
      emit(BlockReportError(message: 'Failed to load blocked users.'));
    }
  }

  Future<void> _onReportUser(
    ReportUser event,
    Emitter<BlockReportState> emit,
  ) async {
    emit(BlockReportLoading());

    try {
      await userRepository.reportUser(
        currentUserId,
        event.reportedUserId,
        event.reason,
      );
      AppLogger.info('User reported successfully: ${event.reportedUserId}');
      emit(UserReported(reportedUserId: event.reportedUserId));
    } catch (e) {
      AppLogger.error('Failed to report user: $e');
      emit(BlockReportError(message: 'Failed to report user. Please try again.'));
    }
  }
}
