import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../presentation/blocs/group_chat/group_chat_bloc.dart';
import '../../data/models.dart';
import '../widgets/participant_picker_dialog.dart';
import '../../../../presentation/widgets/common/pulse_toast.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  GroupType _selectedType = GroupType.standard;
  int _maxParticipants = 50;
  bool _allowParticipantInvite = true;
  bool _requireApproval = false;
  bool _autoAcceptFriends = true;
  bool _enableVoiceChat = true;
  bool _enableVideoChat = false;

  final List<String> _selectedParticipantIds = [];
  final Map<String, String> _selectedParticipantNames =
      {}; // Map userId -> fullName

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Group',
          style: TextStyle(
            color: Color(0xFF202124), // PulseColors.onSurface
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF202124), // PulseColors.onSurface
        ),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: Text(
              'Create',
              style: TextStyle(
                color: Color(0xFF6E3BFF), // PulseColors.primary
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<GroupChatBloc, GroupChatState>(
        listener: (context, state) {
          if (state is GroupCreated) {
            PulseToast.success(context, message: 'Group created successfully!');
            Navigator.of(context).pop(state.group);
          } else if (state is GroupChatError) {
            PulseToast.error(context, message: state.message);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildGroupTypeSection(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildParticipantsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: const OutlineInputBorder(),
                prefixIcon:  Icon(Icons.group),
                labelStyle: const TextStyle(
                  color: Color(0xFF202124), // PulseColors.onSurface
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.trim().length < 3) {
                  return 'Group name must be at least 3 characters';
                }
                return null;
              },
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this group about?',
                border: const OutlineInputBorder(),
                prefixIcon:  Icon(Icons.description),
                labelStyle: const TextStyle(
                  color: Color(0xFF202124), // PulseColors.onSurface
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GroupType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getGroupTypeLabel(type)),
                  selected: _selectedType == type,
                  labelStyle: TextStyle(
                    color: _selectedType == type
                        ? Colors.white
                        : const Color(0xFF202124), // PulseColors.onSurface
                  ),
                  selectedColor: const Color(0xFF6E3BFF), // PulseColors.primary
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                        // Adjust defaults based on type
                        if (type == GroupType.liveHost ||
                            type == GroupType.speedDating) {
                          _requireApproval = true;
                          _enableVideoChat = true;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _getGroupTypeDescription(_selectedType),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Max Participants'),
              subtitle: Slider(
                value: _maxParticipants.toDouble(),
                min: 2,
                max: 100,
                divisions: 98,
                label: _maxParticipants.toString(),
                onChanged: (value) {
                  setState(() {
                    _maxParticipants = value.toInt();
                  });
                },
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _maxParticipants.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Require Approval',
                style: TextStyle(color: Color(0xFF202124)),
              ),
              subtitle: Text(
                'Host must approve new members',
                style: TextStyle(color: Color(0xFF5F6368)),
              ),
              value: _requireApproval,
              onChanged: (value) {
                setState(() {
                  _requireApproval = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Allow Participant Invites',
                style: TextStyle(color: Color(0xFF202124)),
              ),
              subtitle: Text(
                'Members can invite others',
                style: TextStyle(color: Color(0xFF5F6368)),
              ),
              value: _allowParticipantInvite,
              onChanged: (value) {
                setState(() {
                  _allowParticipantInvite = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Auto Accept Friends',
                style: TextStyle(color: Color(0xFF202124)),
              ),
              subtitle: Text(
                'Automatically accept your friends',
                style: TextStyle(color: Color(0xFF5F6368)),
              ),
              value: _autoAcceptFriends,
              onChanged: (value) {
                setState(() {
                  _autoAcceptFriends = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Enable Voice Chat',
                style: TextStyle(color: Color(0xFF202124)),
              ),
              subtitle: Text(
                'Allow voice messages and calls',
                style: TextStyle(color: Color(0xFF5F6368)),
              ),
              value: _enableVoiceChat,
              onChanged: (value) {
                setState(() {
                  _enableVoiceChat = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Enable Video Chat',
                style: TextStyle(color: Color(0xFF202124)),
              ),
              subtitle: Text(
                'Allow video calls',
                style: TextStyle(color: Color(0xFF5F6368)),
              ),
              value: _enableVideoChat,
              onChanged: (value) {
                setState(() {
                  _enableVideoChat = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showParticipantPicker,
                  icon:  Icon(Icons.person_add),
                  label: Text('Add (${_selectedParticipantNames.length})'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select people to add to the group',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            if (_selectedParticipantIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedParticipantIds.map((id) {
                  final name = _selectedParticipantNames[id] ?? 'Unknown User';
                  return Chip(
                    label: Text(
                      name,
                      style: const TextStyle(
                        color: Color(
                          0xFF202124,
                        ), // PulseColors.onSurface - dark text
                      ),
                    ),
                    deleteIcon:  Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedParticipantIds.remove(id);
                        _selectedParticipantNames.remove(id);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGroupTypeLabel(GroupType type) {
    switch (type) {
      case GroupType.standard:
        return '💬 Standard';
      case GroupType.study:
        return '📚 Study';
      case GroupType.interest:
        return '🎯 Interest';
      case GroupType.dating:
        return '💕 Dating';
      case GroupType.liveHost:
        return '🎥 Live Host';
      case GroupType.speedDating:
        return '⚡ Speed Dating';
    }
  }

  String _getGroupTypeDescription(GroupType type) {
    switch (type) {
      case GroupType.standard:
        return 'General purpose group chat';
      case GroupType.study:
        return 'For study groups and learning together';
      case GroupType.interest:
        return 'Share interests and hobbies';
      case GroupType.dating:
        return 'Meet new people for dating';
      case GroupType.liveHost:
        return 'Monkey.app style live sessions with approval';
      case GroupType.speedDating:
        return 'Quick speed dating events with rotations';
    }
  }

  void _showParticipantPicker() async {
    final selectedData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) =>
          ParticipantPickerDialog(initialSelectedIds: _selectedParticipantIds),
    );

    if (selectedData != null && mounted) {
      setState(() {
        _selectedParticipantNames
          ..clear()
          ..addAll(selectedData);
        _selectedParticipantIds
          ..clear()
          ..addAll(selectedData.keys);
      });
    }
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
      PulseToast.info(context, message: 'Please add at least one participant');
      return;
    }

    context.read<GroupChatBloc>().add(
      CreateGroup(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        groupType: _selectedType,
        participantUserIds: _selectedParticipantIds,
        requireApproval: _requireApproval,
      ),
    );
  }
}
