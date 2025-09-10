import 'package:equatable/equatable.dart';
import '../../../data/models/safety.dart';

enum SafetyStatus { 
  initial, 
  loading, 
  loaded, 
  reporting, 
  reported, 
  blocking,
  blocked,
  alerting,
  alerted,
  error 
}

class SafetyState extends Equatable {
  final SafetyStatus status;
  final List<SafetyReport> userReports;
  final List<BlockedUser> blockedUsers;
  final List<SafetyTip> safetyTips;
  final List<EmergencyContact> emergencyContacts;
  final bool locationSharingEnabled;
  final bool emergencyContactsEnabled;
  final bool incidentReportingEnabled;
  final String? errorMessage;
  final bool isLoading;
  final SafetyReport? lastReport;
  final DateTime? lastLocationShare;
  final bool isEmergencyMode;

  const SafetyState({
    this.status = SafetyStatus.initial,
    this.userReports = const [],
    this.blockedUsers = const [],
    this.safetyTips = const [],
    this.emergencyContacts = const [],
    this.locationSharingEnabled = false,
    this.emergencyContactsEnabled = false,
    this.incidentReportingEnabled = true,
    this.errorMessage,
    this.isLoading = false,
    this.lastReport,
    this.lastLocationShare,
    this.isEmergencyMode = false,
  });

  SafetyState copyWith({
    SafetyStatus? status,
    List<SafetyReport>? userReports,
    List<BlockedUser>? blockedUsers,
    List<SafetyTip>? safetyTips,
    List<EmergencyContact>? emergencyContacts,
    bool? locationSharingEnabled,
    bool? emergencyContactsEnabled,
    bool? incidentReportingEnabled,
    String? errorMessage,
    bool? isLoading,
    SafetyReport? lastReport,
    DateTime? lastLocationShare,
    bool? isEmergencyMode,
  }) {
    return SafetyState(
      status: status ?? this.status,
      userReports: userReports ?? this.userReports,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      safetyTips: safetyTips ?? this.safetyTips,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      emergencyContactsEnabled: emergencyContactsEnabled ?? this.emergencyContactsEnabled,
      incidentReportingEnabled: incidentReportingEnabled ?? this.incidentReportingEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      lastReport: lastReport ?? this.lastReport,
      lastLocationShare: lastLocationShare ?? this.lastLocationShare,
      isEmergencyMode: isEmergencyMode ?? this.isEmergencyMode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        userReports,
        blockedUsers,
        safetyTips,
        emergencyContacts,
        locationSharingEnabled,
        emergencyContactsEnabled,
        incidentReportingEnabled,
        errorMessage,
        isLoading,
        lastReport,
        lastLocationShare,
        isEmergencyMode,
      ];
}
