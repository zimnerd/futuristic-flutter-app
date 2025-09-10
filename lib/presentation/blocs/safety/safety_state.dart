part of 'safety_bloc.dart';

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
  final SafetySettings? safetySettings;
  final double? safetyScore;
  final Map<String, dynamic>? userSafetyCheck;
  final bool locationSharingEnabled;
  final bool emergencyContactsEnabled;
  final bool incidentReportingEnabled;
  final String? errorMessage;
  final bool isLoading;
  final SafetyReport? lastReport;
  final DateTime? lastLocationShare;
  final bool isEmergencyMode;
  final bool photoVerificationSubmitted;
  final bool idVerificationSubmitted;

  const SafetyState({
    this.status = SafetyStatus.initial,
    this.userReports = const [],
    this.blockedUsers = const [],
    this.safetyTips = const [],
    this.safetySettings,
    this.safetyScore,
    this.userSafetyCheck,
    this.locationSharingEnabled = false,
    this.emergencyContactsEnabled = false,
    this.incidentReportingEnabled = true,
    this.errorMessage,
    this.isLoading = false,
    this.lastReport,
    this.lastLocationShare,
    this.isEmergencyMode = false,
    this.photoVerificationSubmitted = false,
    this.idVerificationSubmitted = false,
  });

  SafetyState copyWith({
    SafetyStatus? status,
    List<SafetyReport>? userReports,
    List<BlockedUser>? blockedUsers,
    List<SafetyTip>? safetyTips,
    SafetySettings? safetySettings,
    double? safetyScore,
    Map<String, dynamic>? userSafetyCheck,
    bool? locationSharingEnabled,
    bool? emergencyContactsEnabled,
    bool? incidentReportingEnabled,
    String? errorMessage,
    bool? isLoading,
    SafetyReport? lastReport,
    DateTime? lastLocationShare,
    bool? isEmergencyMode,
    bool? photoVerificationSubmitted,
    bool? idVerificationSubmitted,
  }) {
    return SafetyState(
      status: status ?? this.status,
      userReports: userReports ?? this.userReports,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      safetyTips: safetyTips ?? this.safetyTips,
      safetySettings: safetySettings ?? this.safetySettings,
      safetyScore: safetyScore ?? this.safetyScore,
      userSafetyCheck: userSafetyCheck ?? this.userSafetyCheck,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      emergencyContactsEnabled: emergencyContactsEnabled ?? this.emergencyContactsEnabled,
      incidentReportingEnabled: incidentReportingEnabled ?? this.incidentReportingEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      lastReport: lastReport ?? this.lastReport,
      lastLocationShare: lastLocationShare ?? this.lastLocationShare,
      isEmergencyMode: isEmergencyMode ?? this.isEmergencyMode,
      photoVerificationSubmitted:
          photoVerificationSubmitted ?? this.photoVerificationSubmitted,
      idVerificationSubmitted:
          idVerificationSubmitted ?? this.idVerificationSubmitted,
    );
  }

  @override
  List<Object?> get props => [
        status,
        userReports,
        blockedUsers,
        safetyTips,
    safetySettings,
    safetyScore,
    userSafetyCheck,
        locationSharingEnabled,
        emergencyContactsEnabled,
        incidentReportingEnabled,
        errorMessage,
        isLoading,
        lastReport,
        lastLocationShare,
        isEmergencyMode,
    photoVerificationSubmitted,
    idVerificationSubmitted,
      ];
}
