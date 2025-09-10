import 'package:equatable/equatable.dart';
import '../../../data/models/safety.dart';

// Simple enums for safety events
enum SafetyLevel { low, medium, high, critical }
enum IncidentType { harassment, threat, emergency, other }

abstract class SafetyEvent extends Equatable {
  const SafetyEvent();

  @override
  List<Object?> get props => [];
}

class ReportUser extends SafetyEvent {
  final String reportedUserId;
  final SafetyReportType reportType;
  final String description;
  final List<String>? evidence;

  const ReportUser({
    required this.reportedUserId,
    required this.reportType,
    required this.description,
    this.evidence,
  });

  @override
  List<Object?> get props => [reportedUserId, reportType, description, evidence];
}

class BlockUser extends SafetyEvent {
  final String userId;
  final String? reason;

  const BlockUser({
    required this.userId,
    this.reason,
  });

  @override
  List<Object?> get props => [userId, reason];
}

class UnblockUser extends SafetyEvent {
  final String userId;

  const UnblockUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadBlockedUsers extends SafetyEvent {
  const LoadBlockedUsers();
}

class LoadSafetyTips extends SafetyEvent {
  final SafetyLevel? level;
  final String? category;

  const LoadSafetyTips({
    this.level,
    this.category,
  });

  @override
  List<Object?> get props => [level, category];
}

class LoadUserReports extends SafetyEvent {
  final int page;
  final int limit;

  const LoadUserReports({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

class UpdateSafetySettings extends SafetyEvent {
  final bool locationSharing;
  final bool emergencyContacts;
  final bool incidentReporting;
  final List<String>? emergencyContactIds;

  const UpdateSafetySettings({
    required this.locationSharing,
    required this.emergencyContacts,
    required this.incidentReporting,
    this.emergencyContactIds,
  });

  @override
  List<Object?> get props => [
        locationSharing,
        emergencyContacts,
        incidentReporting,
        emergencyContactIds,
      ];
}

class ShareLocationWithEmergencyContacts extends SafetyEvent {
  final double latitude;
  final double longitude;
  final String? message;

  const ShareLocationWithEmergencyContacts({
    required this.latitude,
    required this.longitude,
    this.message,
  });

  @override
  List<Object?> get props => [latitude, longitude, message];
}

class TriggerEmergencyAlert extends SafetyEvent {
  final IncidentType incidentType;
  final String? description;
  final double? latitude;
  final double? longitude;

  const TriggerEmergencyAlert({
    required this.incidentType,
    this.description,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [incidentType, description, latitude, longitude];
}

class LoadSafetyResources extends SafetyEvent {
  const LoadSafetyResources();
}

class MarkTipAsRead extends SafetyEvent {
  final String tipId;

  const MarkTipAsRead({required this.tipId});

  @override
  List<Object?> get props => [tipId];
}

class RefreshSafetyData extends SafetyEvent {
  const RefreshSafetyData();
}
