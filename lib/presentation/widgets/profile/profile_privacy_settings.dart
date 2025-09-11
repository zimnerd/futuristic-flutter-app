import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Widget for managing profile privacy settings
class ProfilePrivacySettings extends StatefulWidget {
  final Map<String, bool> privacySettings;
  final Function(Map<String, bool>) onSettingsChanged;

  const ProfilePrivacySettings({
    super.key,
    required this.privacySettings,
    required this.onSettingsChanged,
  });

  @override
  State<ProfilePrivacySettings> createState() => _ProfilePrivacySettingsState();
}

class _ProfilePrivacySettingsState extends State<ProfilePrivacySettings> {
  late Map<String, bool> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.privacySettings);
  }

  void _updateSetting(String key, bool value) {
    setState(() {
      _settings[key] = value;
    });
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.privacy_tip,
                    color: PulseColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Control who can see your information',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.grey[200], height: 1),
          
          _buildPrivacyOption(
            'Show Distance',
            'Display your distance to other users',
            Icons.location_on,
            'showDistance',
            subtitle: 'Others can see how far away you are',
          ),
          
          _buildPrivacyOption(
            'Show Age',
            'Display your age on your profile',
            Icons.cake,
            'showAge',
            subtitle: 'Your age will be visible to others',
          ),
          
          _buildPrivacyOption(
            'Show Last Active',
            'Display when you were last online',
            Icons.access_time,
            'showLastActive',
            subtitle: 'Others can see when you were last active',
          ),
          
          _buildPrivacyOption(
            'Show Online Status',
            'Display when you are currently online',
            Icons.circle,
            'showOnlineStatus',
            subtitle: 'Show a green dot when you\'re online',
          ),
          
          _buildPrivacyOption(
            'Discovery Mode',
            'Appear in discovery for other users',
            Icons.visibility,
            'discoverable',
            subtitle: 'Turn off to stop appearing in swipe deck',
            isWarning: true,
          ),
          
          _buildPrivacyOption(
            'Read Receipts',
            'Show when you\'ve read messages',
            Icons.done_all,
            'readReceipts',
            subtitle: 'Others can see if you\'ve read their messages',
          ),
          
          _buildPrivacyOption(
            'Profile Verification',
            'Show verification badge on profile',
            Icons.verified,
            'showVerification',
            subtitle: 'Display verification status if verified',
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    String title,
    String description,
    IconData icon,
    String settingKey, {
    String? subtitle,
    bool isWarning = false,
  }) {
    final isEnabled = _settings[settingKey] ?? true;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWarning 
                ? Colors.orange.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isWarning ? Colors.orange : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (value) => _updateSetting(settingKey, value),
            activeColor: PulseColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// Data class for default privacy settings
class DefaultPrivacySettings {
  static const Map<String, bool> defaults = {
    'showDistance': true,
    'showAge': true,
    'showLastActive': true,
    'showOnlineStatus': true,
    'discoverable': true,
    'readReceipts': true,
    'showVerification': true,
  };

  static const Map<String, String> descriptions = {
    'showDistance': 'Controls whether your distance is visible to other users',
    'showAge': 'Controls whether your age appears on your profile',
    'showLastActive': 'Controls whether others can see when you were last online',
    'showOnlineStatus': 'Controls whether others can see if you\'re currently online',
    'discoverable': 'Controls whether you appear in the discovery feed for other users',
    'readReceipts': 'Controls whether others can see if you\'ve read their messages',
    'showVerification': 'Controls whether your verification badge is displayed',
  };
}
