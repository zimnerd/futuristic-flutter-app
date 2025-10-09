import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/safety/safety_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/permission_service.dart';

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
              backgroundColor: isEmergencyMode ? Colors.red : Colors.red.shade600,
              foregroundColor: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEmergencyMode 
                        ? 'Tap to cancel alert' 
                        : 'Tap for immediate help',
                      style: const TextStyle(
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
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Emergency Alert'),
            ],
          ),
          content: const Text(
            'This will immediately notify your emergency contacts and send your location. '
            'Are you in immediate danger?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _triggerEmergency(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('YES, SEND ALERT'),
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
          title: const Text('Cancel Emergency Alert'),
          content: const Text('Are you sure you want to cancel the emergency alert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Active'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SafetyBloc>().add(const CancelEmergencyAlert());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency alert cancelled'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Cancel Alert'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerEmergency(BuildContext context) async {
    final safetyBloc = context.read<SafetyBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    String location = "Location unavailable";

    try {
      // Request location permission for emergency location sharing
      final permissionService = PermissionService();
      final hasPermission = await permissionService
          .requestLocationWhenInUsePermission(context);

      if (!hasPermission) {
        // For emergency situations, still try to get location but inform user
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Emergency alert sent! Location permission denied - emergency services will use available location data.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Use the location service from service locator
      final position = await ServiceLocator.instance.location.getCurrentLocation();

      if (position != null) {
        location = "Lat: ${position.latitude}, Lng: ${position.longitude}";

        // Try to get a readable address
        final address = await ServiceLocator.instance.location.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
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

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Emergency alert sent! Help is on the way.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
