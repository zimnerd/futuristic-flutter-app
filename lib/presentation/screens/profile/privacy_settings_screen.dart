import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/privacy_preset.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_toast.dart';

final _logger = Logger();

/// Enhanced Privacy Settings Screen with presets and granular controls
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _currentSettings;
  PrivacyPresetLevel? _selectedPreset;
  bool _hasUnsavedChanges = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSettings() {
    // Get current settings from profile bloc
    final profileState = context.read<ProfileBloc>().state;
    if (profileState.profile != null) {
      _currentSettings = {
        'showAge': profileState.profile!.showAge ?? true,
        'showDistance': profileState.profile!.showDistance ?? true,
        'showLastActive': profileState.profile!.showLastActive ?? true,
        'showOnlineStatus': profileState.profile!.showOnlineStatus ?? true,
        'incognitoMode': profileState.profile!.incognitoMode ?? false,
        'readReceipts': profileState.profile!.readReceipts ?? true,
        'whoCanMessageMe': profileState.profile!.whoCanMessageMe ?? 'everyone',
        'whoCanSeeMyProfile':
            profileState.profile!.whoCanSeeMyProfile ?? 'everyone',
      };

      // Detect current preset
      _selectedPreset = PrivacyPreset.detectPreset(_currentSettings);

      _logger.i('📱 Privacy Settings initialized: $_currentSettings');
      _logger.i('🎯 Detected preset: $_selectedPreset');
    }
  }

  void _applyPreset(PrivacyPresetLevel level) {
    final preset = PrivacyPreset.getByLevel(level);
    setState(() {
      _currentSettings = Map.from(preset.settings);
      _selectedPreset = level;
      _hasUnsavedChanges = true;
    });

    _logger.i('🎨 Applied preset: ${preset.title}');
    _logger.i('⚙️ New settings: $_currentSettings');
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _currentSettings[key] = value;
      _selectedPreset = PrivacyPreset.detectPreset(_currentSettings);
      _hasUnsavedChanges = true;
    });

    _logger.d('🔧 Updated $key = $value, detected preset: $_selectedPreset');
  }

  Future<void> _saveSettings() async {
    _logger.i('💾 Saving privacy settings...');

    context.read<ProfileBloc>().add(
      UpdatePrivacySettings(settings: _currentSettings),
    );

    // Show success toast
    if (mounted) {
      PulseToast.success(context, message: 'Privacy settings saved');

      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldDiscard = await _showDiscardDialog();
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldDiscard = await _showDiscardDialog();
                if (shouldDiscard == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _saveSettings,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: PulseColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: PulseColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.auto_fix_high_rounded), text: 'Presets'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Custom'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildPresetsTab(), _buildCustomTab()],
        ),
      ),
    );
  }

  Widget _buildPresetsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Privacy Presets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose a preset that matches your privacy preference',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Preset Cards
          ...PrivacyPreset.all.map((preset) => _buildPresetCard(preset)),

          SizedBox(height: 24),

          // Comparison Table
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildPresetCard(PrivacyPreset preset) {
    final isSelected = _selectedPreset == preset.level;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? preset.color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: preset.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _applyPreset(preset.level),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: preset.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(preset.icon, color: preset.color, size: 28),
                ),

                SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            preset.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: preset.color,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        preset.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final comparison = PrivacyPreset.getComparison();
    final presets = PrivacyPreset.all;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Feature Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          Divider(height: 1),

          // Header Row
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ...presets.map(
                  (preset) => Expanded(
                    child: Center(
                      child: Icon(preset.icon, color: preset.color, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Feature Rows
          ...comparison.entries.map((entry) {
            final featureKey = entry.key;
            final featureLabel =
                PrivacyPreset.featureLabels[featureKey] ?? featureKey;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      featureLabel,
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  ...presets.map((preset) {
                    final value = entry.value[preset.level];
                    return Expanded(
                      child: Center(child: _buildFeatureValue(value)),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureValue(dynamic value) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: value ? Colors.green : Colors.red[300],
        size: 18,
      );
    } else {
      return Text(
        value.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (_selectedPreset == null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: PulseColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Custom privacy settings configured',
                      style: TextStyle(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Profile Visibility Section
          _buildSection('Profile Visibility', Icons.visibility_rounded, [
            _buildDropdownSetting(
              'Who can see my profile',
              'whoCanSeeMyProfile',
              'Control who can view your full profile',
              ['everyone', 'matches', 'none'],
              {
                'everyone': 'Everyone',
                'matches': 'Matches Only',
                'none': 'Hidden',
              },
            ),
            _buildDropdownSetting(
              'Who can message me',
              'whoCanMessageMe',
              'Control who can send you messages',
              ['everyone', 'matches', 'none'],
              {
                'everyone': 'Everyone',
                'matches': 'Matches Only',
                'none': 'No One',
              },
            ),
          ]),

          SizedBox(height: 16),

          // Activity Visibility Section
          _buildSection('Activity Visibility', Icons.access_time_rounded, [
            _buildToggleSetting(
              'Show online status',
              'showOnlineStatus',
              'Let others see when you\'re currently active',
            ),
            _buildToggleSetting(
              'Show last active',
              'showLastActive',
              'Display when you were last online',
            ),
            _buildToggleSetting(
              'Read receipts',
              'readReceipts',
              'Let others know when you\'ve read their messages',
            ),
          ]),

          SizedBox(height: 16),

          // Profile Information Section
          _buildSection('Profile Information', Icons.person_rounded, [
            _buildToggleSetting(
              'Show age',
              'showAge',
              'Display your age on your profile',
            ),
            _buildToggleSetting(
              'Show distance',
              'showDistance',
              'Show how far away you are from others',
            ),
          ]),

          SizedBox(height: 16),

          // Advanced Section
          _buildSection('Advanced', Icons.settings_rounded, [
            _buildToggleSetting(
              'Incognito mode',
              'incognitoMode',
              'Browse profiles without appearing in discovery',
              isPremium: true,
            ),
          ]),

          SizedBox(height: 32),

          // Save Button (fixed at bottom)
          if (_hasUnsavedChanges)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Privacy Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: PulseColors.primary, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String key,
    String description, {
    bool isPremium = false,
  }) {
    final value = _currentSettings[key] as bool;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (isPremium) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PulseColors.primary,
                              PulseColors.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: (newValue) => _updateSetting(key, newValue),
            activeThumbColor: PulseColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String key,
    String description,
    List<String> options,
    Map<String, String> labels,
  ) {
    final value = _currentSettings[key] as String;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: PulseColors.primary),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    labels[option] ?? option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  _updateSetting(key, newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?'),
        content: Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Discard'),
          ),
        ],
      ),
    );
  }
}
