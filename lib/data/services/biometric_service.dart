import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

/// Service for handling biometric authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Logger _logger = Logger();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      return isAvailable && isDeviceSupported;
    } catch (e) {
      _logger.e('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your account',
    bool biometricOnly = false,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _logger.w('Biometric authentication not available');
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );

      _logger.i('Biometric authentication result: $result');
      return result;
    } catch (e) {
      _logger.e('Biometric authentication error: $e');
      return false;
    }
  }

  /// Check if user has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking enrolled biometrics: $e');
      return false;
    }
  }

  /// Get a user-friendly description of available biometric types
  Future<String> getBiometricTypeDescription() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return 'No biometric authentication available';
      }

      final types = <String>[];
      
      for (final type in availableBiometrics) {
        switch (type) {
          case BiometricType.face:
            types.add('Face ID');
            break;
          case BiometricType.fingerprint:
            types.add('Fingerprint');
            break;
          case BiometricType.iris:
            types.add('Iris');
            break;
          case BiometricType.weak:
            types.add('Weak biometric');
            break;
          case BiometricType.strong:
            types.add('Strong biometric');
            break;
        }
      }

      return types.join(', ');
    } catch (e) {
      _logger.e('Error getting biometric type description: $e');
      return 'Unknown biometric type';
    }
  }
}
