import '../models/verification_status.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';

/// Repository for managing user verification operations
/// Handles all API communication for verification-related requests
class VerificationRepository {
  final ApiClient _apiClient;

  /// Initialize with optional ApiClient (defaults to singleton instance)
  VerificationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Get current user's verification status
  /// Returns detailed breakdown of email and phone verification
  Future<VerificationStatus> getVerificationStatus() async {
    try {
      AppLogger.info('Fetching verification status...');

      final response = await _apiClient.get('/users/me/verification-status');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        
        AppLogger.debug('Verification status received: ${data['email']}/${data['phone']}');
        
        return VerificationStatus.fromJson(data);
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to load verification status'
        );
      }
    } catch (e) {
      AppLogger.error('Failed to fetch verification status: $e');
      rethrow;
    }
  }

  /// Send verification OTP to authenticated user
  /// Uses JWT token to identify user and send OTP to their stored email/phone
  ///
  /// [preferredMethod] can be:
  /// - 'email': Send OTP to user's email
  /// - 'whatsapp': Send OTP to user's WhatsApp
  /// - 'both': Send OTP to both email and WhatsApp
  ///
  /// Returns a map with:
  /// - sessionId: OTP session identifier for verification
  /// - deliveryMethods: Status of delivery attempts (email/whatsapp)
  /// - expiresAt: When the OTP expires
  Future<Map<String, dynamic>> sendVerificationOTP(
    String preferredMethod,
  ) async {
    try {
      AppLogger.info('Sending verification OTP via $preferredMethod...');

      final response = await _apiClient.post(
        '/users/me/verification/send-otp',
        data: {'preferredMethod': preferredMethod},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>;

        AppLogger.info(
          'Verification OTP sent successfully: ${data['sessionId']}',
        );

        return data;
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to send verification OTP',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to send verification OTP: $e');
      rethrow;
    }
  }

  /// Request email verification
  /// Sends OTP to user's email address
  Future<void> requestEmailVerification() async {
    try {
      AppLogger.info('Requesting email verification...');

      final response = await _apiClient.post(
        '/users/verify/email/request',
        data: {},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          response.data?['message'] ?? 'Failed to request email verification'
        );
      }

      AppLogger.info('Email verification requested successfully');
    } catch (e) {
      AppLogger.error('Failed to request email verification: $e');
      rethrow;
    }
  }

  /// Confirm email verification with OTP
  /// Should be called after user receives and enters OTP
  Future<VerificationStatus> confirmEmailVerification(String otp) async {
    try {
      AppLogger.info('Confirming email verification with OTP...');

      final response = await _apiClient.post(
        '/users/verify/email/confirm',
        data: {'otp': otp},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        AppLogger.info('Email verified successfully');
        return VerificationStatus.fromJson(data);
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to confirm email verification'
        );
      }
    } catch (e) {
      AppLogger.error('Failed to confirm email verification: $e');
      rethrow;
    }
  }

  /// Request phone verification
  /// Sends OTP to user's phone number via SMS
  Future<void> requestPhoneVerification() async {
    try {
      AppLogger.info('Requesting phone verification...');

      final response = await _apiClient.post(
        '/users/verify/phone/request',
        data: {},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          response.data?['message'] ?? 'Failed to request phone verification'
        );
      }

      AppLogger.info('Phone verification requested successfully');
    } catch (e) {
      AppLogger.error('Failed to request phone verification: $e');
      rethrow;
    }
  }

  /// Confirm phone verification with OTP
  /// Should be called after user receives and enters OTP
  Future<VerificationStatus> confirmPhoneVerification(String otp) async {
    try {
      AppLogger.info('Confirming phone verification with OTP...');

      final response = await _apiClient.post(
        '/users/verify/phone/confirm',
        data: {'otp': otp},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        AppLogger.info('Phone verified successfully');
        return VerificationStatus.fromJson(data);
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to confirm phone verification'
        );
      }
    } catch (e) {
      AppLogger.error('Failed to confirm phone verification: $e');
      rethrow;
    }
  }

  /// Check if user is fully verified (both email and phone)
  Future<bool> isFullyVerified() async {
    try {
      final status = await getVerificationStatus();
      return status.emailVerified && status.phoneVerified;
    } catch (e) {
      AppLogger.error('Failed to check if user is fully verified: $e');
      return false;
    }
  }

  /// Get list of verification methods that still need completion
  Future<List<String>> getPendingVerifications() async {
    try {
      final status = await getVerificationStatus();
      return status.pendingVerifications;
    } catch (e) {
      AppLogger.error('Failed to get pending verifications: $e');
      return [];
    }
  }

  /// Get list of completed verification methods
  Future<List<String>> getCompletedVerifications() async {
    try {
      final status = await getVerificationStatus();
      return status.completedVerifications;
    } catch (e) {
      AppLogger.error('Failed to get completed verifications: $e');
      return [];
    }
  }
}
