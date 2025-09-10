import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/services/safety_service.dart';
import '../../../data/models/safety.dart';
import 'safety_event.dart';
import 'safety_state.dart';

class SafetyBloc extends Bloc<SafetyEvent, SafetyState> {
  final SafetyService _safetyService;
  final Logger _logger = Logger();

  SafetyBloc(this._safetyService) : super(const SafetyState()) {
    on<ReportUser>(_onReportUser);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<LoadBlockedUsers>(_onLoadBlockedUsers);
    on<LoadSafetyTips>(_onLoadSafetyTips);
    on<LoadUserReports>(_onLoadUserReports);
    on<UpdateSafetySettings>(_onUpdateSafetySettings);
    on<ShareLocationWithEmergencyContacts>(_onShareLocationWithEmergencyContacts);
    on<TriggerEmergencyAlert>(_onTriggerEmergencyAlert);
    on<LoadSafetyResources>(_onLoadSafetyResources);
    on<MarkTipAsRead>(_onMarkTipAsRead);
    on<RefreshSafetyData>(_onRefreshSafetyData);
  }

  Future<void> _onReportUser(
    ReportUser event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SafetyStatus.reporting));

      final report = await _safetyService.reportUser(
        reportedUserId: event.reportedUserId,
        reportType: event.reportType,
        description: event.description,
        evidenceUrls: event.evidence,
      );

      if (report != null) {
        final updatedReports = [report, ...state.userReports];
        
        emit(state.copyWith(
          status: SafetyStatus.reported,
          userReports: updatedReports,
          lastReport: report,
        ));

        _logger.d('User reported successfully: ${report.id}');
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          errorMessage: 'Failed to submit report',
        ));
      }
    } catch (e) {
      _logger.e('Error reporting user: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        errorMessage: 'Failed to report user: $e',
      ));
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SafetyStatus.blocking));

      final success = await _safetyService.blockUser(event.userId);

      if (success) {
        // Reload blocked users to get the updated list
        add(const LoadBlockedUsers());
        
        emit(state.copyWith(status: SafetyStatus.blocked));
        _logger.d('User blocked successfully: ${event.userId}');
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          errorMessage: 'Failed to block user',
        ));
      }
    } catch (e) {
      _logger.e('Error blocking user: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        errorMessage: 'Failed to block user: $e',
      ));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final success = await _safetyService.unblockUser(event.userId);

      if (success) {
        // Remove the user from the blocked users list
        final updatedBlockedUsers = state.blockedUsers
            .where((user) => user.blockedUserId != event.userId)
            .toList();

        emit(state.copyWith(
          blockedUsers: updatedBlockedUsers,
          isLoading: false,
        ));

        _logger.d('User unblocked successfully: ${event.userId}');
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to unblock user',
        ));
      }
    } catch (e) {
      _logger.e('Error unblocking user: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to unblock user: $e',
      ));
    }
  }

  Future<void> _onLoadBlockedUsers(
    LoadBlockedUsers event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final blockedUsers = await _safetyService.getBlockedUsers();

      emit(state.copyWith(
        blockedUsers: blockedUsers,
        isLoading: false,
      ));

      _logger.d('Loaded ${blockedUsers.length} blocked users');
    } catch (e) {
      _logger.e('Error loading blocked users: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load blocked users: $e',
      ));
    }
  }

  Future<void> _onLoadSafetyTips(
    LoadSafetyTips event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final tips = await _safetyService.getSafetyTips();

      emit(state.copyWith(
        safetyTips: tips,
        isLoading: false,
      ));

      _logger.d('Loaded ${tips.length} safety tips');
    } catch (e) {
      _logger.e('Error loading safety tips: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load safety tips: $e',
      ));
    }
  }

  Future<void> _onLoadUserReports(
    LoadUserReports event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final reports = await _safetyService.getUserReports(
        page: event.page,
        limit: event.limit,
      );

      // If this is page 1, replace the list; otherwise, append
      final updatedReports = event.page == 1 
          ? reports 
          : [...state.userReports, ...reports];

      emit(state.copyWith(
        userReports: updatedReports,
        isLoading: false,
      ));

      _logger.d('Loaded ${reports.length} user reports');
    } catch (e) {
      _logger.e('Error loading user reports: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user reports: $e',
      ));
    }
  }

  Future<void> _onUpdateSafetySettings(
    UpdateSafetySettings event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final success = await _safetyService.updateSafetySettings(
        locationSharing: event.locationSharing,
        emergencyContacts: event.emergencyContacts,
        incidentReporting: event.incidentReporting,
      );

      if (success) {
        emit(state.copyWith(
          locationSharingEnabled: event.locationSharing,
          emergencyContactsEnabled: event.emergencyContacts,
          incidentReportingEnabled: event.incidentReporting,
          isLoading: false,
        ));

        _logger.d('Safety settings updated successfully');
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update safety settings',
        ));
      }
    } catch (e) {
      _logger.e('Error updating safety settings: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update safety settings: $e',
      ));
    }
  }

  Future<void> _onShareLocationWithEmergencyContacts(
    ShareLocationWithEmergencyContacts event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      if (!state.locationSharingEnabled) {
        emit(state.copyWith(
          errorMessage: 'Location sharing is disabled',
        ));
        return;
      }

      emit(state.copyWith(isLoading: true));

      final success = await _safetyService.shareLocationWithEmergencyContacts(
        latitude: event.latitude,
        longitude: event.longitude,
        message: event.message,
      );

      if (success) {
        emit(state.copyWith(
          lastLocationShare: DateTime.now(),
          isLoading: false,
        ));

        _logger.d('Location shared with emergency contacts');
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to share location',
        ));
      }
    } catch (e) {
      _logger.e('Error sharing location: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to share location: $e',
      ));
    }
  }

  Future<void> _onTriggerEmergencyAlert(
    TriggerEmergencyAlert event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: SafetyStatus.alerting,
        isEmergencyMode: true,
      ));

      final success = await _safetyService.triggerEmergencyAlert(
        incidentType: event.incidentType.name,
        description: event.description,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      if (success) {
        emit(state.copyWith(
          status: SafetyStatus.alerted,
          lastLocationShare: DateTime.now(),
        ));

        _logger.d('Emergency alert triggered successfully');
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          errorMessage: 'Failed to trigger emergency alert',
          isEmergencyMode: false,
        ));
      }
    } catch (e) {
      _logger.e('Error triggering emergency alert: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        errorMessage: 'Failed to trigger emergency alert: $e',
        isEmergencyMode: false,
      ));
    }
  }

  Future<void> _onLoadSafetyResources(
    LoadSafetyResources event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      // Load all safety-related data
      final [tips, blockedUsers, emergencyContacts] = await Future.wait([
        _safetyService.getSafetyTips(),
        _safetyService.getBlockedUsers(),
        _safetyService.getEmergencyContacts(),
      ]);

      emit(state.copyWith(
        safetyTips: tips as List<SafetyTip>,
        blockedUsers: blockedUsers as List<BlockedUser>,
        emergencyContacts: emergencyContacts as List<EmergencyContact>,
        isLoading: false,
      ));

      _logger.d('Loaded all safety resources');
    } catch (e) {
      _logger.e('Error loading safety resources: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load safety resources: $e',
      ));
    }
  }

  Future<void> _onMarkTipAsRead(
    MarkTipAsRead event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      final success = await _safetyService.markTipAsRead(event.tipId);
      
      if (success) {
        _logger.d('Safety tip marked as read: ${event.tipId}');
      } else {
        emit(state.copyWith(
          errorMessage: 'Failed to mark tip as read',
        ));
      }
    } catch (e) {
      _logger.e('Error marking tip as read: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to mark tip as read: $e',
      ));
    }
  }

  Future<void> _onRefreshSafetyData(
    RefreshSafetyData event,
    Emitter<SafetyState> emit,
  ) async {
    try {
      // Refresh all safety data
      add(const LoadSafetyResources());
      add(const LoadUserReports());
    } catch (e) {
      _logger.e('Error refreshing safety data: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to refresh safety data: $e',
      ));
    }
  }
}
