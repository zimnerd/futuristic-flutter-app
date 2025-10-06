import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';

/// Proactive permission management service for iOS and Android
/// 
/// This service handles:
/// - Checking permission status before requesting
/// - Showing explanatory dialogs before permission prompts
/// - Handling denied and permanently denied states
/// - Opening app settings when needed
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final Logger _logger = Logger();

  /// Request camera permission with user-friendly prompts
  Future<bool> requestCameraPermission(BuildContext context) async {
    return await _requestPermissionWithDialog(
      context: context,
      permission: Permission.camera,
      title: '📸 Camera Access Required',
      message: 'Pulse needs access to your camera to make video calls and take photos.',
      settingsMessage: 'Camera access is required for video calls.\n\nPlease enable it in Settings > Pulse > Camera',
    );
  }

  /// Request microphone permission with user-friendly prompts
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    return await _requestPermissionWithDialog(
      context: context,
      permission: Permission.microphone,
      title: '🎤 Microphone Access Required',
      message: 'Pulse needs access to your microphone to make voice and video calls.',
      settingsMessage: 'Microphone access is required for calls.\n\nPlease enable it in Settings > Pulse > Microphone',
    );
  }

  /// Request both camera and microphone permissions for video calls
  Future<bool> requestVideoCallPermissions(BuildContext context) async {
    // Check current status first
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    // If both are already granted, no need for dialog
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    // Show explanation dialog
    final shouldRequest = await _showPermissionExplanationDialog(
      context: context,
      title: '📹 Video Call Permissions',
      message: 'To make video calls, Pulse needs access to:\n\n• 📸 Camera - to show your video\n• 🎤 Microphone - to transmit your voice\n\nYou\'ll be asked to grant these permissions next.',
    );

    if (!shouldRequest) {
      return false;
    }

    // Request camera permission
    bool cameraGranted = cameraStatus.isGranted;
    if (!cameraGranted) {
      if (cameraStatus.isPermanentlyDenied) {
        await _showSettingsDialog(
          context: context,
          title: '📸 Camera Access Denied',
          message: 'Camera access was previously denied.\n\nPlease enable it in Settings > Pulse > Camera',
        );
        return false;
      }
      
      final status = await Permission.camera.request();
      cameraGranted = status.isGranted;
      
      if (!cameraGranted) {
        if (status.isPermanentlyDenied) {
          await _showSettingsDialog(
            context: context,
            title: '📸 Camera Access Denied',
            message: 'Camera access is required for video calls.\n\nPlease enable it in Settings > Pulse > Camera',
          );
        }
        return false;
      }
    }

    // Request microphone permission
    bool micGranted = microphoneStatus.isGranted;
    if (!micGranted) {
      if (microphoneStatus.isPermanentlyDenied) {
        await _showSettingsDialog(
          context: context,
          title: '🎤 Microphone Access Denied',
          message: 'Microphone access was previously denied.\n\nPlease enable it in Settings > Pulse > Microphone',
        );
        return false;
      }
      
      final status = await Permission.microphone.request();
      micGranted = status.isGranted;
      
      if (!micGranted) {
        if (status.isPermanentlyDenied) {
          await _showSettingsDialog(
            context: context,
            title: '🎤 Microphone Access Denied',
            message: 'Microphone access is required for video calls.\n\nPlease enable it in Settings > Pulse > Microphone',
          );
        }
        return false;
      }
    }

    return cameraGranted && micGranted;
  }

  /// Request microphone permission for audio calls
  Future<bool> requestAudioCallPermissions(BuildContext context) async {
    return await _requestPermissionWithDialog(
      context: context,
      permission: Permission.microphone,
      title: '🎤 Microphone Access Required',
      message: 'To make voice calls, Pulse needs access to your microphone.',
      settingsMessage: 'Microphone access is required for calls.\n\nPlease enable it in Settings > Pulse > Microphone',
    );
  }

  /// Request photo library permission
  Future<bool> requestPhotoLibraryPermission(BuildContext context) async {
    return await _requestPermissionWithDialog(
      context: context,
      permission: Permission.photos,
      title: '📷 Photo Library Access',
      message: 'Pulse needs access to your photo library to upload photos to your profile.',
      settingsMessage: 'Photo library access is required.\n\nPlease enable it in Settings > Pulse > Photos',
    );
  }

  /// Generic permission request with dialog flow
  Future<bool> _requestPermissionWithDialog({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String message,
    required String settingsMessage,
  }) async {
    // Check current status
    final status = await permission.status;

    // If already granted, return true
    if (status.isGranted) {
      return true;
    }

    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context: context,
        title: title,
        message: settingsMessage,
      );
      return false;
    }

    // Show explanation dialog before requesting
    final shouldRequest = await _showPermissionExplanationDialog(
      context: context,
      title: title,
      message: message,
    );

    if (!shouldRequest) {
      return false;
    }

    // Request the permission
    final newStatus = await permission.request();

    if (newStatus.isGranted) {
      _logger.i('Permission granted: $permission');
      return true;
    }

    // Handle denial
    if (newStatus.isPermanentlyDenied) {
      await _showSettingsDialog(
        context: context,
        title: title,
        message: settingsMessage,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Permission denied. You can grant it later in settings.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }

    _logger.w('Permission denied: $permission - $newStatus');
    return false;
  }

  /// Show explanation dialog before requesting permission
  Future<bool> _showPermissionExplanationDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E3BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show settings dialog when permission is permanently denied
  Future<void> _showSettingsDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E3BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check if both camera and microphone permissions are granted
  Future<bool> areVideoCallPermissionsGranted() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }
}
