import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/models.dart';

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
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<GroupChatBloc, GroupChatState>(
        listener: (context, state) {
          if (state is GroupCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(state.group);
          } else if (state is GroupChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
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
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
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
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this group about?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
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
            const Text(
              'Group Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GroupType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getGroupTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                        // Adjust defaults based on type
                        if (type == GroupType.liveHost || type == GroupType.speedDating) {
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
                color: Colors.grey[600],
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
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Max Participants'),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
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
              title: const Text('Require Approval'),
              subtitle: const Text('Host must approve new members'),
              value: _requireApproval,
              onChanged: (value) {
                setState(() {
                  _requireApproval = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow Participant Invites'),
              subtitle: const Text('Members can invite others'),
              value: _allowParticipantInvite,
              onChanged: (value) {
                setState(() {
                  _allowParticipantInvite = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Accept Friends'),
              subtitle: const Text('Automatically accept your friends'),
              value: _autoAcceptFriends,
              onChanged: (value) {
                setState(() {
                  _autoAcceptFriends = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Voice Chat'),
              subtitle: const Text('Allow voice messages and calls'),
              value: _enableVoiceChat,
              onChanged: (value) {
                setState(() {
                  _enableVoiceChat = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Video Chat'),
              subtitle: const Text('Allow video calls'),
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
                const Text(
                  'Add Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showParticipantPicker,
                  icon: const Icon(Icons.person_add),
                  label: Text('Add (${_selectedParticipantIds.length})'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select people to add to the group',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedParticipantIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedParticipantIds.map((id) {
                  return Chip(
                    label: Text('User $id'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedParticipantIds.remove(id);
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

  void _showParticipantPicker() {
    // TODO: Implement participant picker with user search
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participants'),
        content: const Text(
          'Participant picker will be implemented with user search functionality.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one participant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<GroupChatBloc>().add(
          CreateGroup(
            title: _titleController.text.trim(),
            groupType: _selectedType,
            participantUserIds: _selectedParticipantIds,
            maxParticipants: _maxParticipants,
            allowParticipantInvite: _allowParticipantInvite,
            requireApproval: _requireApproval,
            autoAcceptFriends: _autoAcceptFriends,
            enableVoiceChat: _enableVoiceChat,
            enableVideoChat: _enableVideoChat,
          ),
        );
  }
}
