import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/safety/safety_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/permission_service.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Emergency button widget for quick access to safety features
class EmergencyButtonWidget extends StatelessWidget {
  const EmergencyButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      child: BlocBuilder<SafetyBloc, SafetyState>(
        builder: (context, state) {
          final isEmergencyMode = state.isEmergencyMode;

          return ElevatedButton(
            onPressed: () => _handleEmergencyPress(context, isEmergencyMode),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEmergencyMode
                  ? Colors.red
                  : Colors.red.shade600,
              foregroundColor: context.onSurfaceColor,
              elevation: isEmergencyMode ? 12 : 6,
              shadowColor: Colors.red.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEmergencyMode ? Icons.emergency : Icons.warning,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmergencyMode ? 'EMERGENCY ACTIVE' : 'EMERGENCY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEmergencyMode
                          ? 'Tap to cancel alert'
                          : 'Tap for immediate help',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleEmergencyPress(BuildContext context, bool isCurrentlyActive) {
    if (isCurrentlyActive) {
      // Cancel emergency mode
      _showCancelEmergencyDialog(context);
    } else {
      // Trigger emergency mode
      _showEmergencyDialog(context);
    }
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Row(
            children: [
              Icon(Icons.warning, color: context.errorColor),
              const SizedBox(width: 8),
              Text(
                'Emergency Alert',
                style: TextStyle(
                  color: context.outlineColor.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'This will immediately notify your emergency contacts and send your location. '
            'Are you in immediate danger?',
            style: TextStyle(
              color: context.outlineColor.shade800,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.outlineColor.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _triggerEmergency(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: context.onSurfaceColor,
              ),
              child: Text('YES, SEND ALERT'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Text(
            'Cancel Emergency Alert',
            style: TextStyle(
              color: context.outlineColor.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel the emergency alert?',
            style: TextStyle(
              color: context.outlineColor.shade800,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Active',
                style: TextStyle(
                  color: context.outlineColor.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SafetyBloc>().add(const CancelEmergencyAlert());
                PulseToast.success(
                  context,
                  message: 'Emergency alert cancelled',
                );
              },
              child: Text('Cancel Alert'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerEmergency(BuildContext context) async {
    final safetyBloc = context.read<SafetyBloc>();

    String location = "Location unavailable";

    try {
      // Request location permission for emergency location sharing
      final permissionService = PermissionService();
      final hasPermission = await permissionService
          .requestLocationWhenInUsePermission(context);

      if (!hasPermission) {
        // For emergency situations, still try to get location but inform user
        if (context.mounted) {
          PulseToast.error(
            context,
            message:
                'Emergency alert sent! Location permission denied - emergency services will use available location data.',
          );
        }
      }

      // Use the location service from service locator
      final position = await ServiceLocator.instance.location
          .getCurrentLocation();

      if (position != null) {
        location = "Lat: ${position.latitude}, Lng: ${position.longitude}";

        // Try to get a readable address
        final address = await ServiceLocator.instance.location
            .getAddressFromCoordinates(position.latitude, position.longitude);
        if (address != null) {
          location = "$address (${position.latitude}, ${position.longitude})";
        }
      } else {
        location = "Unable to get location - please check permissions";
      }
    } catch (e) {
      location = "Location error: $e";
    }

    safetyBloc.add(
      TriggerEmergencyContact(
        location: location,
        additionalInfo: 'Emergency alert triggered from app',
      ),
    );

    if (context.mounted) {
      PulseToast.error(
        context,
        message: 'Emergency alert sent! Help is on the way.',
      );
    }
  }
}
