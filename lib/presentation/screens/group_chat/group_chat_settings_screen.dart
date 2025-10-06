import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/group_chat/data/models.dart';
import '../../../features/group_chat/data/group_chat_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';

final sl = GetIt.instance;

/// Comprehensive Group Chat Settings Screen
/// 
/// Features:
/// - Group information editing (name, description, photo)
/// - Privacy & security settings
/// - Notification preferences
/// - Participant management (view, add, remove, change roles)
/// - Moderation tools (mute, block, report)
/// - Group actions (leave, delete)
/// 
/// Admin-only features:
/// - Update group settings
/// - Change participant roles
/// - Remove participants
/// - Delete group
class GroupChatSettingsScreen extends StatefulWidget {
  final GroupConversation group;

  const GroupChatSettingsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatSettingsScreen> createState() => _GroupChatSettingsScreenState();
}

class _GroupChatSettingsScreenState extends State<GroupChatSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Settings state
  late bool _allowParticipantInvite;
  late bool _requireApproval;
  late bool _autoAcceptFriends;
  late bool _enableVoiceChat;
  late bool _enableVideoChat;
  late int _maxParticipants;
  
  // Notification settings
  bool _muteNotifications = false;
  bool _showPreviews = true;
  
  // UI state
  bool _hasUnsavedChanges = false;

  // Current user (mocked - should come from AuthBloc)
  final String _currentUserId = 'current-user-id';

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    _groupNameController.text = widget.group.title;
    _descriptionController.text = widget.group.description ?? '';
    
    final settings = widget.group.settings;
    _allowParticipantInvite = settings?.allowParticipantInvite ?? true;
    _requireApproval = settings?.requireApproval ?? false;
    _autoAcceptFriends = settings?.autoAcceptFriends ?? true;
    _enableVoiceChat = settings?.enableVoiceChat ?? true;
    _enableVideoChat = settings?.enableVideoChat ?? false;
    _maxParticipants = settings?.maxParticipants ?? 50;
    
    // Listen for text changes
    _groupNameController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isAdmin() {
    final currentUserParticipant = widget.group.participants.firstWhere(
      (p) => p.userId == _currentUserId,
      orElse: () => widget.group.participants.first,
    );
    return currentUserParticipant.role == ParticipantRole.admin ||
        currentUserParticipant.role == ParticipantRole.owner;
  }

  bool _isOwner() {
    final currentUserParticipant = widget.group.participants.firstWhere(
      (p) => p.userId == _currentUserId,
      orElse: () => widget.group.participants.first,
    );
    return currentUserParticipant.role == ParticipantRole.owner;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Group Settings'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_hasUnsavedChanges && _isAdmin())
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: PulseColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Group Info Section
          _buildGroupInfoSection(),
          const SizedBox(height: 16),

          // Privacy & Security Settings
          if (_isAdmin()) ...[
            _buildPrivacySettingsSection(),
            const SizedBox(height: 16),
          ],

          // Notification Settings
          _buildNotificationSettingsSection(),
          const SizedBox(height: 16),

          // Participants Section
          _buildParticipantsSection(),
          const SizedBox(height: 16),

          // Moderation Tools
          if (_isAdmin()) ...[
            _buildModerationSection(),
            const SizedBox(height: 16),
          ],

          // Danger Zone
          _buildDangerZoneSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ========== GROUP INFO SECTION ==========

  Widget _buildGroupInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: PulseColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Group Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Group Photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.group,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        if (_isAdmin())
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeGroupPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PulseColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0A0E27),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Group Name
                  TextFormField(
                    controller: _groupNameController,
                    enabled: _isAdmin(),
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: PulseColors.primary),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.title,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Group name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    enabled: _isAdmin(),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: PulseColors.primary),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Group Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.people,
                        label: 'Members',
                        value: widget.group.participantCount.toString(),
                      ),
                      _buildStatItem(
                        icon: Icons.calendar_today,
                        label: 'Created',
                        value: _formatDate(widget.group.lastActivity),
                      ),
                      _buildStatItem(
                        icon: Icons.category,
                        label: 'Type',
                        value: _formatGroupType(widget.group.groupType),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: PulseColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ========== PRIVACY & SECURITY SETTINGS ==========

  Widget _buildPrivacySettingsSection() {
    return _buildSettingsCard(
      icon: Icons.security,
      title: 'Privacy & Security',
      children: [
        _buildSwitchTile(
          title: 'Allow Participant Invites',
          subtitle: 'Members can invite others to join',
          value: _allowParticipantInvite,
          onChanged: (value) => setState(() {
            _allowParticipantInvite = value;
            _markAsChanged();
          }),
        ),
        const Divider(height: 1, color: Colors.white12),
        _buildSwitchTile(
          title: 'Require Join Approval',
          subtitle: 'Admin must approve new members',
          value: _requireApproval,
          onChanged: (value) => setState(() {
            _requireApproval = value;
            _markAsChanged();
          }),
        ),
        const Divider(height: 1, color: Colors.white12),
        _buildSwitchTile(
          title: 'Auto-Accept Friends',
          subtitle: 'Friends can join without approval',
          value: _autoAcceptFriends,
          onChanged: (value) => setState(() {
            _autoAcceptFriends = value;
            _markAsChanged();
          }),
        ),
        const Divider(height: 1, color: Colors.white12),
        _buildSwitchTile(
          title: 'Enable Voice Chat',
          subtitle: 'Allow voice calls in this group',
          value: _enableVoiceChat,
          onChanged: (value) => setState(() {
            _enableVoiceChat = value;
            _markAsChanged();
          }),
        ),
        const Divider(height: 1, color: Colors.white12),
        _buildSwitchTile(
          title: 'Enable Video Chat',
          subtitle: 'Allow video calls in this group',
          value: _enableVideoChat,
          onChanged: (value) => setState(() {
            _enableVideoChat = value;
            _markAsChanged();
          }),
        ),
        const Divider(height: 1, color: Colors.white12),
        _buildSliderTile(
          title: 'Max Participants',
          subtitle: 'Maximum: $_maxParticipants members',
          value: _maxParticipants.toDouble(),
          min: 2,
          max: 500,
          divisions: 99,
          onChanged: (value) => setState(() {
            _maxParticipants = value.toInt();
            _markAsChanged();
          }),
        ),
      ],
    );
  }

  // ========== NOTIFICATION SETTINGS ==========

  Widget _buildNotificationSettingsSection() {
    return _buildSettingsCard(
      icon: Icons.notifications,
      title: 'Notifications',
      children: [
        _buildSwitchTile(
          title: 'Mute Notifications',
          subtitle: 'Don\'t receive notifications from this group',
          value: _muteNotifications,
          onChanged: (value) => setState(() => _muteNotifications = value),
        ),
        const Divider(height: 1, color: Colors.white12),
        _buildSwitchTile(
          title: 'Show Message Previews',
          subtitle: 'Display message content in notifications',
          value: _showPreviews,
          onChanged: (value) => setState(() => _showPreviews = value),
        ),
      ],
    );
  }

  // ========== PARTICIPANTS SECTION ==========

  Widget _buildParticipantsSection() {
    return _buildSettingsCard(
      icon: Icons.people,
      title: 'Participants (${widget.group.participantCount})',
      trailing: _isAdmin()
          ? IconButton(
              icon: Icon(Icons.person_add, color: PulseColors.primary),
              onPressed: _showAddParticipantsDialog,
            )
          : null,
      children: [
        ...widget.group.participants.map((participant) => _buildParticipantTile(participant)),
      ],
    );
  }

  Widget _buildParticipantTile(GroupParticipant participant) {
    final isCurrentUser = participant.userId == _currentUserId;
    final canModify = _isAdmin() && !isCurrentUser && participant.role != ParticipantRole.owner;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
        backgroundImage: participant.profilePhoto != null
            ? CachedNetworkImageProvider(participant.profilePhoto!)
            : null,
        child: participant.profilePhoto == null
            ? Text(
                participant.firstName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              participant.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: PulseColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          _buildRoleBadge(participant.role),
          if (participant.isOnline) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Online',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      trailing: canModify
          ? PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.7)),
              onSelected: (value) => _handleParticipantAction(value, participant),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'change_role',
                  child: ListTile(
                    leading: Icon(Icons.admin_panel_settings),
                    title: Text('Change Role'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.person_remove, color: Colors.red),
                    title: Text('Remove', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRoleBadge(ParticipantRole role) {
    Color color;
    String label;

    switch (role) {
      case ParticipantRole.owner:
        color = Colors.amber;
        label = 'Owner';
        break;
      case ParticipantRole.admin:
        color = Colors.purple;
        label = 'Admin';
        break;
      case ParticipantRole.moderator:
        color = Colors.blue;
        label = 'Moderator';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ========== MODERATION SECTION ==========

  Widget _buildModerationSection() {
    return _buildSettingsCard(
      icon: Icons.shield,
      title: 'Moderation Tools',
      children: [
        ListTile(
          leading: Icon(Icons.block, color: Colors.orange.shade300),
          title: const Text(
            'Blocked Users',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Manage blocked participants',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          onTap: _showBlockedUsers,
        ),
        const Divider(height: 1, color: Colors.white12),
        ListTile(
          leading: Icon(Icons.flag, color: Colors.red.shade300),
          title: const Text(
            'Reported Content',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Review reports from members',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          onTap: _showReportedContent,
        ),
      ],
    );
  }

  // ========== DANGER ZONE ==========

  Widget _buildDangerZoneSection() {
    return _buildSettingsCard(
      icon: Icons.warning,
      title: 'Danger Zone',
      children: [
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.orange),
          title: const Text(
            'Leave Group',
            style: TextStyle(color: Colors.orange),
          ),
          subtitle: Text(
            'You can rejoin later if group is public',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          onTap: _confirmLeaveGroup,
        ),
        if (_isOwner()) ...[
          const Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Group',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              'Permanently delete this group and all messages',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
            onTap: _confirmDeleteGroup,
          ),
        ],
      ],
    );
  }

  // ========== HELPER WIDGETS ==========

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: PulseColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
      ),
      value: value,
      activeThumbColor: PulseColors.primary,
      activeTrackColor: PulseColors.primary.withValues(alpha: 0.5),
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: PulseColors.primary,
          inactiveColor: Colors.white.withValues(alpha: 0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ========== ACTION HANDLERS ==========

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Unsaved Changes', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Saving settings...'),
              ],
            ),
            duration: Duration(seconds: 60),
          ),
        );
      }

      // Call API to update group settings
      final service = sl<GroupChatService>();
      final updatedGroup = await service.updateGroupSettings(
        conversationId: widget.group.id,
        title: _groupNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        allowParticipantInvite: _allowParticipantInvite,
        requireApproval: _requireApproval,
        autoAcceptFriends: _autoAcceptFriends,
        enableVoiceChat: _enableVoiceChat,
        enableVideoChat: _enableVideoChat,
        maxParticipants: _maxParticipants,
      );

      if (mounted) {
        // Dismiss loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        setState(() {
          _hasUnsavedChanges = false;
        });

        // Return updated group to previous screen
        Navigator.pop(context, updatedGroup);
      }
    } catch (e) {
      if (mounted) {
        // Dismiss loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Failed to save settings: ${e.toString().replaceAll('Exception: ', '')}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveSettings,
            ),
          ),
        );
      }
    }
  }

  void _changeGroupPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3A),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _takePhotoWithCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeGroupPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AddParticipantsDialog(
        groupId: widget.group.id,
        existingParticipantIds: widget.group.participants.map((p) => p.userId).toList(),
        onParticipantsAdded: () {
          // Refresh group data
          setState(() {});
        },
      ),
    );
  }

  void _handleParticipantAction(String action, GroupParticipant participant) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(participant);
        break;
      case 'remove':
        _confirmRemoveParticipant(participant);
        break;
    }
  }

  void _showChangeRoleDialog(GroupParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Change Role for ${participant.fullName}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleOption('Admin', ParticipantRole.admin, participant),
            _buildRoleOption('Moderator', ParticipantRole.moderator, participant),
            _buildRoleOption('Member', ParticipantRole.member, participant),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String label, ParticipantRole role, GroupParticipant participant) {
    final isSelected = participant.role == role;
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        Navigator.pop(context);
        _changeParticipantRole(participant, role);
      },
    );
  }

  Future<void> _changeParticipantRole(GroupParticipant participant, ParticipantRole newRole) async {
    try {
      final service = sl<GroupChatService>();
      await service.changeParticipantRole(
        conversationId: widget.group.id,
        targetUserId: participant.userId,
        role: newRole,
        reason: 'Role changed by admin',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Changed ${participant.fullName}\'s role to ${newRole.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmRemoveParticipant(GroupParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Remove Participant', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${participant.fullName} from this group?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeParticipant(participant);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeParticipant(GroupParticipant participant) async {
    try {
      final service = sl<GroupChatService>();
      await service.removeParticipant(
        conversationId: widget.group.id,
        userId: participant.userId,
        reason: 'Removed by admin',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.fullName} removed from group'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove participant: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockedUsersScreen(
          conversationId: widget.group.id,
        ),
      ),
    );
  }

  void _showReportedContent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportedContentScreen(
          conversationId: widget.group.id,
        ),
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Leave Group', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this group? You can rejoin later if it\'s public.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final service = sl<GroupChatService>();
      await service.leaveGroup(
        conversationId: widget.group.id,
        message: 'Left the group',
      );
      
      if (mounted) {
        Navigator.pop(context); // Close settings screen
        Navigator.pop(context); // Close chat screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You left the group'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Are you sure you want to permanently delete this group? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      final service = sl<GroupChatService>();
      await service.deleteGroup(
        conversationId: widget.group.id,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close settings screen
        Navigator.pop(context); // Close chat screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted permanently'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete group: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ========== UTILITY METHODS ==========

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        await _uploadGroupPhoto(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Take photo with camera
  Future<void> _takePhotoWithCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        await _uploadGroupPhoto(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Upload group photo
  Future<void> _uploadGroupPhoto(String imagePath) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Uploading photo...'),
              ],
            ),
            duration: Duration(seconds: 60),
          ),
        );
      }

      final service = sl<GroupChatService>();
      await service.uploadGroupPhoto(
        conversationId: widget.group.id,
        imagePath: imagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group photo updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Remove group photo
  Future<void> _removeGroupPhoto() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text('Remove Photo', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to remove the group photo?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final service = sl<GroupChatService>();
        await service.removeGroupPhoto(conversationId: widget.group.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group photo removed'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the screen
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else {
      return 'Today';
    }
  }

  String _formatGroupType(GroupType type) {
    switch (type) {
      case GroupType.standard:
        return 'Standard';
      case GroupType.study:
        return 'Study';
      case GroupType.interest:
        return 'Interest';
      case GroupType.dating:
        return 'Dating';
      case GroupType.liveHost:
        return 'Live';
      case GroupType.speedDating:
        return 'Speed';
    }
  }
}

// ========== ADD PARTICIPANTS DIALOG ==========

class AddParticipantsDialog extends StatefulWidget {
  final String groupId;
  final List<String> existingParticipantIds;
  final VoidCallback onParticipantsAdded;

  const AddParticipantsDialog({
    super.key,
    required this.groupId,
    required this.existingParticipantIds,
    required this.onParticipantsAdded,
  });

  @override
  State<AddParticipantsDialog> createState() => _AddParticipantsDialogState();
}

class _AddParticipantsDialogState extends State<AddParticipantsDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];
  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F3A),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Participants',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                if (value.length < 2) {
                  setState(() {
                    _searchResults = [];
                    _isSearching = false;
                  });
                  return;
                }
                setState(() => _isSearching = true);
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  _searchUsers(value);
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Search for users to add',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              final userId = user['id'] as String;
                              final isSelected = _selectedUserIds.contains(userId);
                              final isExisting = widget.existingParticipantIds.contains(userId);

                              return ListTile(
                                enabled: !isExisting,
                                leading: CircleAvatar(
                                  backgroundImage: user['photoUrl'] != null
                                      ? CachedNetworkImageProvider(user['photoUrl'])
                                      : null,
                                  child: user['photoUrl'] == null
                                      ? Text(user['firstName'][0].toUpperCase())
                                      : null,
                                ),
                                title: Text(
                                  '${user['firstName']} ${user['lastName']}',
                                  style: TextStyle(
                                    color: isExisting ? Colors.grey : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isExisting ? 'Already in group' : '@${user['username']}',
                                  style: TextStyle(
                                    color: isExisting ? Colors.grey : Colors.white70,
                                  ),
                                ),
                                trailing: isExisting
                                    ? const Icon(Icons.check, color: Colors.grey)
                                    : Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedUserIds.add(userId);
                                              _selectedUsers[userId] = user;
                                            } else {
                                              _selectedUserIds.remove(userId);
                                              _selectedUsers.remove(userId);
                                            }
                                          });
                                        },
                                      ),
                              );
                            },
                          ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedUserIds.isEmpty || _isLoading
                    ? null
                    : _addParticipants,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Add ${_selectedUserIds.length} ${_selectedUserIds.length == 1 ? 'Person' : 'People'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addParticipants() async {
    setState(() => _isLoading = true);

    try {
      final service = sl<GroupChatService>();
      for (final userId in _selectedUserIds) {
        await service.addParticipant(
          conversationId: widget.groupId,
          userId: userId,
          role: ParticipantRole.member,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onParticipantsAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participants added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add participants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final service = sl<GroupChatService>();
      final results = await service.searchUsers(
        query: query,
        conversationId: widget.groupId,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ========== BLOCKED USERS SCREEN ==========

class BlockedUsersScreen extends StatefulWidget {
  final String conversationId;

  const BlockedUsersScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser>? _blockedUsers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final service = sl<GroupChatService>();
      final users = await service.getBlockedUsers(conversationId: widget.conversationId);
      
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load blocked users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Blocked Users'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers == null || _blockedUsers!.isEmpty
              ? const Center(
                  child: Text(
                    'No blocked users',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _blockedUsers!.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final user = _blockedUsers![index];
                    return Card(
                      color: const Color(0xFF1A1F3A),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: user.photoUrl != null
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${user.username}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (user.reason != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${user.reason}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _unblockUser(user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Unblock'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _unblockUser(BlockedUser user) async {
    try {
      final service = sl<GroupChatService>();
      await service.unblockUser(
        conversationId: widget.conversationId,
        userId: user.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} unblocked'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBlockedUsers(); // Reload the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ========== REPORTED CONTENT SCREEN ==========

class ReportedContentScreen extends StatefulWidget {
  final String conversationId;

  const ReportedContentScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ReportedContentScreen> createState() => _ReportedContentScreenState();
}

class _ReportedContentScreenState extends State<ReportedContentScreen> {
  List<ReportedContent>? _reports;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportedContent();
  }

  Future<void> _loadReportedContent() async {
    try {
      final service = sl<GroupChatService>();
      final reports = await service.getReportedContent(
        conversationId: widget.conversationId,
      );
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reported content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Reported Content'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports == null || _reports!.isEmpty
              ? const Center(
                  child: Text(
                    'No reported content',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _reports!.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final report = _reports![index];
                    return Card(
                      color: const Color(0xFF1A1F3A),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: report.reporterPhotoUrl != null
                                      ? CachedNetworkImageProvider(report.reporterPhotoUrl!)
                                      : null,
                                  child: report.reporterPhotoUrl == null
                                      ? Text(
                                          report.reporterUsername[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reported by @${report.reporterUsername}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(report.reportedAt),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(report.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    report.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reason: ${report.reason}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (report.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      report.description!,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (report.message != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  report.message!.content,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (report.status == 'pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _reviewReport(report, 'dismissed'),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Dismiss'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _reviewReport(report, 'action_taken'),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Take Action'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'dismissed':
        return Colors.grey;
      case 'action_taken':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _reviewReport(ReportedContent report, String action) async {
    try {
      final service = sl<GroupChatService>();
      await service.reviewReport(
        conversationId: widget.conversationId,
        reportId: report.id,
        action: action,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report $action successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReportedContent(); // Reload the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to review report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

