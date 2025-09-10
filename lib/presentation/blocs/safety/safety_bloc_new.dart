import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../../../data/models/safety.dart';
import '../../../data/services/safety_service.dart';

part 'safety_event.dart';
part 'safety_state.dart';

class SafetyBloc extends Bloc<SafetyEvent, SafetyState> {
  final SafetyService _safetyService;
  final Logger _logger = Logger();

  SafetyBloc({required SafetyService safetyService})
      : _safetyService = safetyService,
        super(const SafetyState()) {
    on<LoadSafetyData>(_onLoadSafetyData);
    on<ReportUser>(_onReportUser);
    on<ReportContent>(_onReportContent);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<LoadBlockedUsers>(_onLoadBlockedUsers);
    on<LoadSafetySettings>(_onLoadSafetySettings);
    on<UpdateSafetySettings>(_onUpdateSafetySettings);
    on<LoadSafetyScore>(_onLoadSafetyScore);
    on<LoadSafetyReports>(_onLoadSafetyReports);
    on<TriggerEmergencyContact>(_onTriggerEmergencyContact);
    on<LoadSafetyTips>(_onLoadSafetyTips);
    on<SubmitPhotoVerification>(_onSubmitPhotoVerification);
    on<SubmitIdVerification>(_onSubmitIdVerification);
    on<ReportDateSafetyConcern>(_onReportDateSafetyConcern);
    on<CheckUserSafety>(_onCheckUserSafety);
  }

  Future<void> _onLoadSafetyData(LoadSafetyData event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true, status: SafetyStatus.loading));
    
    try {
      // Load all safety data
      final futures = await Future.wait([
        _safetyService.getBlockedUsers(),
        _safetyService.getSafetyTips(),
        _safetyService.getMySafetyReports(),
        _safetyService.getSafetySettings(),
        _safetyService.getSafetyScore(),
      ]);

      final blockedUsers = futures[0] as List<BlockedUser>;
      final safetyTips = futures[1] as List<SafetyTip>;
      final reports = futures[2] as List<SafetyReport>;
      final settings = futures[3] as SafetySettings?;
      final score = futures[4] as double?;

      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        blockedUsers: blockedUsers,
        safetyTips: safetyTips,
        userReports: reports,
        safetySettings: settings,
        safetyScore: score,
      ));
    } catch (e) {
      _logger.e('Error loading safety data: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReportUser(ReportUser event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(status: SafetyStatus.reporting, isLoading: true));
    
    try {
      final report = await _safetyService.reportUser(
        reportedUserId: event.reportedUserId,
        reportType: event.reportType,
        description: event.description,
        evidence: event.evidence,
      );

      if (report != null) {
        final updatedReports = List<SafetyReport>.from(state.userReports)..add(report);
        emit(state.copyWith(
          status: SafetyStatus.reported,
          isLoading: false,
          userReports: updatedReports,
          lastReport: report,
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to report user',
        ));
      }
    } catch (e) {
      _logger.e('Error reporting user: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReportContent(ReportContent event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(status: SafetyStatus.reporting, isLoading: true));
    
    try {
      final report = await _safetyService.reportContent(
        contentId: event.contentId,
        reportType: event.reportType,
        description: event.description,
      );

      if (report != null) {
        final updatedReports = List<SafetyReport>.from(state.userReports)..add(report);
        emit(state.copyWith(
          status: SafetyStatus.reported,
          isLoading: false,
          userReports: updatedReports,
          lastReport: report,
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to report content',
        ));
      }
    } catch (e) {
      _logger.e('Error reporting content: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onBlockUser(BlockUser event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(status: SafetyStatus.blocking, isLoading: true));
    
    try {
      final success = await _safetyService.blockUser(
        userId: event.userId,
        reason: event.reason,
      );

      if (success) {
        // Refresh blocked users list
        final blockedUsers = await _safetyService.getBlockedUsers();
        emit(state.copyWith(
          status: SafetyStatus.blocked,
          isLoading: false,
          blockedUsers: blockedUsers,
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to block user',
        ));
      }
    } catch (e) {
      _logger.e('Error blocking user: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUnblockUser(UnblockUser event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final success = await _safetyService.unblockUser(event.userId);

      if (success) {
        // Refresh blocked users list
        final blockedUsers = await _safetyService.getBlockedUsers();
        emit(state.copyWith(
          status: SafetyStatus.loaded,
          isLoading: false,
          blockedUsers: blockedUsers,
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to unblock user',
        ));
      }
    } catch (e) {
      _logger.e('Error unblocking user: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadBlockedUsers(LoadBlockedUsers event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final blockedUsers = await _safetyService.getBlockedUsers();
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        blockedUsers: blockedUsers,
      ));
    } catch (e) {
      _logger.e('Error loading blocked users: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSafetySettings(LoadSafetySettings event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final settings = await _safetyService.getSafetySettings();
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        safetySettings: settings,
      ));
    } catch (e) {
      _logger.e('Error loading safety settings: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSafetySettings(UpdateSafetySettings event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // Create SafetySettings object from event data
      final newSettings = SafetySettings(
        id: state.safetySettings?.id ?? '',
        userId: state.safetySettings?.userId ?? '',
        locationSharing: event.locationSharing,
        emergencyContacts: event.emergencyContacts,
        incidentReporting: event.incidentReporting,
        createdAt: state.safetySettings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _safetyService.updateSafetySettings(newSettings);
      
      if (success) {
        emit(state.copyWith(
          status: SafetyStatus.loaded,
          isLoading: false,
          safetySettings: newSettings,
          locationSharingEnabled: event.locationSharing,
          emergencyContactsEnabled: event.emergencyContacts,
          incidentReportingEnabled: event.incidentReporting,
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to update safety settings',
        ));
      }
    } catch (e) {
      _logger.e('Error updating safety settings: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSafetyScore(LoadSafetyScore event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final score = await _safetyService.getSafetyScore();
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        safetyScore: score,
      ));
    } catch (e) {
      _logger.e('Error loading safety score: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSafetyReports(LoadSafetyReports event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final reports = await _safetyService.getMySafetyReports();
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        userReports: reports,
      ));
    } catch (e) {
      _logger.e('Error loading safety reports: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTriggerEmergencyContact(TriggerEmergencyContact event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(status: SafetyStatus.alerting, isLoading: true));
    
    try {
      final success = await _safetyService.triggerEmergencyContact(
        location: event.location,
        additionalInfo: event.additionalInfo,
      );

      if (success) {
        emit(state.copyWith(
          status: SafetyStatus.alerted,
          isLoading: false,
          isEmergencyMode: true,
          lastLocationShare: DateTime.now(),
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to trigger emergency contact',
        ));
      }
    } catch (e) {
      _logger.e('Error triggering emergency contact: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSafetyTips(LoadSafetyTips event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final tips = await _safetyService.getSafetyTips();
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        safetyTips: tips,
      ));
    } catch (e) {
      _logger.e('Error loading safety tips: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitPhotoVerification(SubmitPhotoVerification event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final success = await _safetyService.submitPhotoVerification(event.photoPath);
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        photoVerificationSubmitted: success,
        errorMessage: success ? null : 'Failed to submit photo verification',
      ));
    } catch (e) {
      _logger.e('Error submitting photo verification: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitIdVerification(SubmitIdVerification event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final success = await _safetyService.submitIdVerification(
        frontPhotoPath: event.frontPhotoPath,
        backPhotoPath: event.backPhotoPath,
        idType: event.idType,
      );
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        idVerificationSubmitted: success,
        errorMessage: success ? null : 'Failed to submit ID verification',
      ));
    } catch (e) {
      _logger.e('Error submitting ID verification: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReportDateSafetyConcern(ReportDateSafetyConcern event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(status: SafetyStatus.reporting, isLoading: true));
    
    try {
      final report = await _safetyService.reportDateSafetyConcern(
        dateId: event.dateId,
        concern: event.concern,
        location: event.location,
        requiresImmediateHelp: event.requiresImmediateHelp,
      );

      if (report != null) {
        final updatedReports = List<SafetyReport>.from(state.userReports)..add(report);
        emit(state.copyWith(
          status: SafetyStatus.reported,
          isLoading: false,
          userReports: updatedReports,
          lastReport: report,
          isEmergencyMode: event.requiresImmediateHelp,
        ));
      } else {
        emit(state.copyWith(
          status: SafetyStatus.error,
          isLoading: false,
          errorMessage: 'Failed to report date safety concern',
        ));
      }
    } catch (e) {
      _logger.e('Error reporting date safety concern: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckUserSafety(CheckUserSafety event, Emitter<SafetyState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final safetyCheck = await _safetyService.checkUserSafety(event.userId);
      emit(state.copyWith(
        status: SafetyStatus.loaded,
        isLoading: false,
        userSafetyCheck: safetyCheck,
      ));
    } catch (e) {
      _logger.e('Error checking user safety: $e');
      emit(state.copyWith(
        status: SafetyStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
