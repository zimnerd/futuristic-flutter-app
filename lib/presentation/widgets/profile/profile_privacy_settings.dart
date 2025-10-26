import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

final _logger = Logger();

/// Widget for managing profile privacy settings
class ProfilePrivacySettings extends StatefulWidget {
  final Map<String, dynamic> privacySettings;
  final Function(Map<String, dynamic>) onSettingsChanged;

  const ProfilePrivacySettings({
    super.key,
    required this.privacySettings,
    required this.onSettingsChanged,
  });

  @override
  State<ProfilePrivacySettings> createState() => _ProfilePrivacySettingsState();
}

class _ProfilePrivacySettingsState extends State<ProfilePrivacySettings> {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.privacySettings);
    _logger.d(
      '🔍 [ProfilePrivacySettings.initState] readReceipts from widget: ${widget.privacySettings['readReceipts']}',
    );
    _logger.d(
      '🔍 [ProfilePrivacySettings.initState] readReceipts in _settings: ${_settings['readReceipts']}',
    );
  }

  @override
  void didUpdateWidget(ProfilePrivacySettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.d(
      '🔍 [ProfilePrivacySettings.didUpdateWidget] OLD readReceipts: ${oldWidget.privacySettings['readReceipts']}',
    );
    _logger.d(
      '🔍 [ProfilePrivacySettings.didUpdateWidget] NEW readReceipts: ${widget.privacySettings['readReceipts']}',
    );
    if (widget.privacySettings != oldWidget.privacySettings) {
      _logger.d(
        '🔍 [ProfilePrivacySettings.didUpdateWidget] Settings changed, updating _settings',
      );
      setState(() {
        _settings = Map.from(widget.privacySettings);
        _logger.d(
          '🔍 [ProfilePrivacySettings.didUpdateWidget] readReceipts in _settings after update: ${_settings['readReceipts']}',
        );
      });
    } else {
      _logger.d(
        '🔍 [ProfilePrivacySettings.didUpdateWidget] Settings unchanged, skipping update',
      );
    }
  }

  void _updateSetting(String key, dynamic value) {
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.05),
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
                    color: PulseColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.privacy_tip,
                    color: PulseColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      Text(
                        'Control who can see your information',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: context.outlineColor.withValues(alpha: 0.15),
            height: 1,
          ),

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
            'Incognito Mode',
            'Browse privately and hide from discovery',
            Icons.visibility_off,
            'incognitoMode',
            subtitle: 'Turn on to stop appearing in swipe deck',
            isWarning: true,
          ),

          _buildPrivacyOption(
            'Read Receipts',
            'Show when you\'ve read messages',
            Icons.done_all,
            'readReceipts',
            subtitle: 'Others can see if you\'ve read their messages',
          ),

          Divider(
            color: context.outlineColor.withValues(alpha: 0.15),
            height: 1,
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Message & Profile Visibility',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          _buildDropdownOption(
            'Who Can Message Me',
            'Control who can send you messages',
            Icons.message,
            'whoCanMessageMe',
            ['everyone', 'matches', 'none'],
            subtitle: 'Set message restrictions',
          ),

          _buildDropdownOption(
            'Who Can See My Profile',
            'Control profile visibility',
            Icons.person,
            'whoCanSeeMyProfile',
            ['everyone', 'matches', 'none'],
            subtitle: 'Set profile visibility restrictions',
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
                  ? Colors.orange.withValues(alpha: 0.1)
                  : context.outlineColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isWarning ? Colors.orange : context.onSurfaceVariantColor,
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
                  style: TextStyle(
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
                      color: context.onSurfaceVariantColor,
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
            activeTrackColor: PulseColors.primary,
            activeThumbColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownOption(
    String title,
    String description,
    IconData icon,
    String settingKey,
    List<String> options, {
    String? subtitle,
  }) {
    final currentValue = _settings[settingKey] as String? ?? options.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.outlineColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: context.onSurfaceVariantColor,
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
                      style: TextStyle(
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
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.outlineColor.withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: currentValue,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              dropdownColor: Colors.white,
              isExpanded: true,
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    _formatOptionText(option),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateSetting(settingKey, value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatOptionText(String option) {
    // Capitalize first letter of each word
    return option
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Data class for default privacy settings
class DefaultPrivacySettings {
  static const Map<String, dynamic> defaults = {
    'showDistance': true,
    'showAge': true,
    'showLastActive': true,
    'showOnlineStatus': true,
    'incognitoMode': false,
    'readReceipts': true,
    'whoCanMessageMe': 'everyone',
    'whoCanSeeMyProfile': 'everyone',
  };

  static const Map<String, String> descriptions = {
    'showDistance': 'Controls whether your distance is visible to other users',
    'showAge': 'Controls whether your age appears on your profile',
    'showLastActive':
        'Controls whether others can see when you were last online',
    'showOnlineStatus':
        'Controls whether others can see if you\'re currently online',
    'incognitoMode':
        'Controls whether you appear in the discovery feed for other users',
    'readReceipts':
        'Controls whether others can see if you\'ve read their messages',
    'whoCanMessageMe': 'Controls who can send you messages',
    'whoCanSeeMyProfile': 'Controls who can view your full profile',
  };
}
