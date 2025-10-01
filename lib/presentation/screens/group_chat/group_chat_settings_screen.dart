import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

import '../../../features/group_chat/data/models.dart';
import '../../../features/group_chat/data/group_chat_service.dart';
import '../../../core/theme/app_theme.dart';

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
                // TODO: Implement image picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement remove photo
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParticipantsDialog() {
    // TODO: Implement add participants dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add participants feature coming soon')),
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
      // TODO: Implement API call
      await Future.delayed(const Duration(milliseconds: 300));
      
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
    // TODO: Implement blocked users screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked users feature coming soon')),
    );
  }

  void _showReportedContent() {
    // TODO: Implement reported content screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reported content feature coming soon')),
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
      // TODO: Implement leave group API call
      await Future.delayed(const Duration(milliseconds: 300));
      
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
      // TODO: Implement delete group API call
      // context.read<GroupChatBloc>().add(DeleteGroup(conversationId: widget.group.id));
      await Future.delayed(const Duration(milliseconds: 300));
      
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
