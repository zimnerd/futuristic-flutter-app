import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Mixin to add permission checking capabilities to widgets
/// Use this in call screens and other screens that need camera/microphone access
mixin PermissionRequiredMixin<T extends StatefulWidget> on State<T> {
  final PermissionService _permissionService = PermissionService();

  /// Request video call permissions before starting/accepting a call
  /// Returns true if permissions are granted, false otherwise
  Future<bool> ensureVideoCallPermissions() async {
    return await _permissionService.requestVideoCallPermissions(context);
  }

  /// Request audio call permissions before starting/accepting a call
  /// Returns true if permissions are granted, false otherwise
  Future<bool> ensureAudioCallPermissions() async {
    return await _permissionService.requestAudioCallPermissions(context);
  }

  /// Request camera permission (for photo upload, AR features, etc.)
  /// Returns true if permission is granted, false otherwise
  Future<bool> ensureCameraPermission() async {
    return await _permissionService.requestCameraPermission(context);
  }

  /// Request microphone permission
  /// Returns true if permission is granted, false otherwise
  Future<bool> ensureMicrophonePermission() async {
    return await _permissionService.requestMicrophonePermission(context);
  }

  /// Request photo library permission (for uploading profile photos)
  /// Returns true if permission is granted, false otherwise
  Future<bool> ensurePhotoLibraryPermission() async {
    return await _permissionService.requestPhotoLibraryPermission(context);
  }

  /// Check if video call permissions are already granted (without requesting)
  Future<bool> checkVideoCallPermissions() async {
    return await _permissionService.areVideoCallPermissionsGranted();
  }

  /// Check if camera permission is already granted (without requesting)
  Future<bool> checkCameraPermission() async {
    return await _permissionService.isCameraPermissionGranted();
  }

  /// Check if microphone permission is already granted (without requesting)
  Future<bool> checkMicrophonePermission() async {
    return await _permissionService.isMicrophonePermissionGranted();
  }
}
