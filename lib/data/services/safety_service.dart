import 'package:logger/logger.dart';
import '../models/safety.dart';
import '../../core/network/api_client.dart';
import 'package:dio/dio.dart'; // Ensure Dio is imported for FormData

/// Service for handling safety and reporting features
class SafetyService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  SafetyService(this._apiClient);

  /// Report a user for inappropriate behavior
  Future<SafetyReport?> reportUser({
    required String reportedUserId,
    required SafetyReportType reportType,
    required String description,
    List<String>? evidenceUrls,
    String? incidentLocation,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/safety/report-user',
        data: {
          'reportedUserId': reportedUserId,
          'reportType': reportType.name,
          'description': description,
          'evidenceUrls': evidenceUrls ?? [],
          'incidentLocation': incidentLocation,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final report = SafetyReport.fromJson(response.data!);
        _logger.d('User report submitted successfully: ${report.id}');
        return report;
      } else {
        _logger.e('Failed to submit user report: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error submitting user report: $e');
      return null;
    }
  }

  /// Report inappropriate content (message, photo, etc.)
  Future<SafetyReport?> reportContent({
    required String contentId,
    required String contentType, // 'message', 'photo', 'profile'
    required SafetyReportType reportType,
    required String description,
    String? reportedUserId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/safety/report-content',
        data: {
          'contentId': contentId,
          'contentType': contentType,
          'reportType': reportType.name,
          'description': description,
          'reportedUserId': reportedUserId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final report = SafetyReport.fromJson(response.data!);
        _logger.d('Content report submitted successfully: ${report.id}');
        return report;
      } else {
        _logger.e('Failed to submit content report: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error submitting content report: $e');
      return null;
    }
  }

  /// Block a user
  Future<bool> blockUser(String userId) async {
    try {
      final response = await _apiClient.post(
        '/api/safety/block-user',
        data: {'userId': userId},
      );

      if (response.statusCode == 200) {
        _logger.d('User blocked successfully: $userId');
        return true;
      } else {
        _logger.e('Failed to block user: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    try {
      final response = await _apiClient.delete(
        '/api/safety/block-user/$userId',
      );

      if (response.statusCode == 200) {
        _logger.d('User unblocked successfully: $userId');
        return true;
      } else {
        _logger.e('Failed to unblock user: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error unblocking user: $e');
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final response = await _apiClient.get('/api/safety/blocked-users');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['blockedUsers'] ?? [];
        final blockedUsers = data.map((json) => BlockedUser.fromJson(json)).toList();
        
        _logger.d('Retrieved ${blockedUsers.length} blocked users');
        return blockedUsers;
      } else {
        _logger.e('Failed to get blocked users: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting blocked users: $e');
      return [];
    }
  }

  /// Get safety settings for the current user
  Future<SafetySettings?> getSafetySettings() async {
    try {
      final response = await _apiClient.get('/api/safety/settings');

      if (response.statusCode == 200 && response.data != null) {
        final settings = SafetySettings.fromJson(response.data!);
        _logger.d('Retrieved safety settings');
        return settings;
      } else {
        _logger.e('Failed to get safety settings: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting safety settings: $e');
      return null;
    }
  }

  /// Update safety settings
  Future<bool> updateSafetySettings(SafetySettings settings) async {
    try {
      final response = await _apiClient.put(
        '/api/safety/settings',
        data: settings.toJson(),
      );

      if (response.statusCode == 200) {
        _logger.d('Safety settings updated successfully');
        return true;
      } else {
        _logger.e('Failed to update safety settings: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating safety settings: $e');
      return false;
    }
  }

  /// Get user's safety score and verification status
  Future<Map<String, dynamic>?> getSafetyScore() async {
    try {
      final response = await _apiClient.get('/api/safety/score');

      if (response.statusCode == 200 && response.data != null) {
        final safetyData = {
          'safetyScore': response.data['safetyScore'] ?? 0.0,
          'verificationLevel': response.data['verificationLevel'] ?? 'none',
          'isPhoneVerified': response.data['isPhoneVerified'] ?? false,
          'isEmailVerified': response.data['isEmailVerified'] ?? false,
          'isPhotoVerified': response.data['isPhotoVerified'] ?? false,
          'hasValidId': response.data['hasValidId'] ?? false,
          'reportCount': response.data['reportCount'] ?? 0,
          'trustLevel': response.data['trustLevel'] ?? 'basic',
        };
        
        _logger.d('Retrieved safety score and verification status');
        return safetyData;
      } else {
        _logger.e('Failed to get safety score: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting safety score: $e');
      return null;
    }
  }

  /// Submit photo verification
  Future<bool> submitPhotoVerification(String photoPath) async {
    try {
      final response = await _apiClient.post(
        '/api/safety/verify-photo',
        data: FormData.fromMap({
          'photo': await MultipartFile.fromFile(photoPath),
        }),
      );

      if (response.statusCode == 200) {
        _logger.d('Photo verification submitted successfully');
        return true;
      } else {
        _logger.e('Failed to submit photo verification: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error submitting photo verification: $e');
      return false;
    }
  }

  /// Submit ID verification
  Future<bool> submitIdVerification({
    required String frontPhotoPath,
    required String backPhotoPath,
    required String idType, // 'passport', 'license', 'id_card'
  }) async {
    try {
      // Upload front photo
      final frontResponse = await _apiClient.post(
        '/api/safety/verify-id/front',
        data: FormData.fromMap({
          'idType': idType,
          'frontPhoto': await MultipartFile.fromFile(frontPhotoPath),
        }),
      );

      if (frontResponse.statusCode != 200) {
        _logger.e('Failed to upload ID front photo');
        return false;
      }

      // Upload back photo
      final backResponse = await _apiClient.post(
        '/api/safety/verify-id/back',
        data: FormData.fromMap({
          'idType': idType,
          'backPhoto': await MultipartFile.fromFile(backPhotoPath),
        }),
      );

      if (backResponse.statusCode == 200) {
        _logger.d('ID verification submitted successfully');
        return true;
      } else {
        _logger.e('Failed to upload ID back photo');
        return false;
      }
    } catch (e) {
      _logger.e('Error submitting ID verification: $e');
      return false;
    }
  }

  /// Get safety tips and guidelines
  Future<List<SafetyTip>> getSafetyTips() async {
    try {
      final response = await _apiClient.get('/api/safety/tips');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['tips'] ?? [];
        final tips = data.map((json) => SafetyTip.fromJson(json)).toList();
        
        _logger.d('Retrieved ${tips.length} safety tips');
        return tips;
      } else {
        _logger.e('Failed to get safety tips: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting safety tips: $e');
      return [];
    }
  }

  /// Report a safety concern during a date
  Future<SafetyReport?> reportDateSafetyConcern({
    required String dateId,
    required String concern,
    required String location,
    bool requiresImmediateHelp = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/safety/report-date-concern',
        data: {
          'dateId': dateId,
          'concern': concern,
          'location': location,
          'requiresImmediateHelp': requiresImmediateHelp,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final report = SafetyReport.fromJson(response.data!);
        _logger.d('Date safety concern reported: ${report.id}');
        return report;
      } else {
        _logger.e('Failed to report date safety concern: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error reporting date safety concern: $e');
      return null;
    }
  }

  /// Trigger emergency contact notification
  Future<bool> triggerEmergencyContact({
    required String location,
    String? additionalInfo,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/safety/emergency-contact',
        data: {
          'location': location,
          'additionalInfo': additionalInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Emergency contact notification triggered');
        return true;
      } else {
        _logger.e('Failed to trigger emergency contact: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error triggering emergency contact: $e');
      return false;
    }
  }

  /// Check if a user is safe to interact with
  Future<Map<String, dynamic>?> checkUserSafety(String userId) async {
    try {
      final response = await _apiClient.get('/api/safety/check-user/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final safetyCheck = {
          'isSafe': response.data['isSafe'] ?? true,
          'warningLevel': response.data['warningLevel'] ?? 'none', // none, low, medium, high
          'verificationStatus': response.data['verificationStatus'] ?? 'unverified',
          'riskFactors': response.data['riskFactors'] ?? [],
          'safetyScore': response.data['safetyScore'] ?? 0.0,
          'recommendations': response.data['recommendations'] ?? [],
        };
        
        _logger.d('User safety check completed for: $userId');
        return safetyCheck;
      } else {
        _logger.e('Failed to check user safety: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error checking user safety: $e');
      return null;
    }
  }

  /// Get my safety reports history
  Future<List<SafetyReport>> getMySafetyReports() async {
    try {
      final response = await _apiClient.get('/api/safety/my-reports');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['reports'] ?? [];
        final reports = data.map((json) => SafetyReport.fromJson(json)).toList();
        
        _logger.d('Retrieved ${reports.length} safety reports');
        return reports;
      } else {
        _logger.e('Failed to get safety reports: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting safety reports: $e');
      return [];
    }
  }
}
