import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Service to check Google Play Services availability on Android
/// 
/// Required by Firebase Messaging for proper FCM token generation.
/// Official Firebase docs: https://firebase.google.com/docs/cloud-messaging/flutter/client
class PlayServicesChecker {
  static const MethodChannel _channel = MethodChannel(
    'co.za.pulsetek.pulselink/play_services',
  );

  /// Check if Google Play Services is available on this device
  /// 
  /// Returns:
  /// - `true` if Play Services is available and up to date
  /// - `false` if Play Services is missing, outdated, or needs updating
  /// 
  /// Note: This check is Android-specific and always returns true on iOS
  static Future<bool> checkAvailability() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't use Play Services
    }

    try {
      final bool? isAvailable = await _channel.invokeMethod('checkPlayServices');
      if (isAvailable == true) {
        AppLogger.info('✅ Google Play Services is available');
        return true;
      } else {
        AppLogger.warning('⚠️ Google Play Services is not available or outdated');
        return false;
      }
    } on PlatformException catch (e) {
      AppLogger.error('❌ Failed to check Play Services: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.error('❌ Unexpected error checking Play Services: $e');
      return false;
    }
  }

  /// Prompt user to update Google Play Services if needed
  /// 
  /// This will show the system dialog to update Play Services
  static Future<void> promptUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('promptPlayServicesUpdate');
      AppLogger.info('🔄 Prompted user to update Play Services');
    } on PlatformException catch (e) {
      AppLogger.error('❌ Failed to prompt Play Services update: ${e.message}');
    }
  }
}
