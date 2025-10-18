import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../widgets/common/pulse_toast.dart';

/// Emergency Contacts Screen
///
/// Allows users to manage emergency contacts for safety during dates:
/// - Add/remove emergency contacts
/// - Notify contacts when going on date
/// - Share live location
/// - Safety check-in reminders
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<EmergencyContact> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    // TODO: Load from backend API
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  Future<void> _addContact() async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => const _AddContactDialog(),
    );

    if (result != null) {
      setState(() => _contacts.add(result));

      // TODO: Save to backend
      HapticFeedback.mediumImpact();
      if (mounted) {
        PulseToast.success(
          context,
          message: 'Emergency contact added',
        );
      }
    }
  }

  Future<void> _removeContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text(
          'Remove ${contact.name} from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: PulseColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _contacts.remove(contact));

      // TODO: Remove from backend
      HapticFeedback.lightImpact();
      if (mounted) {
        PulseToast.info(
          context,
          message: 'Contact removed',
        );
      }
    }
  }

  void _showSafetyTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SafetyTipsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSafetyTips,
            tooltip: 'Safety Tips',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? _buildEmptyState()
              : _buildContactsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
        backgroundColor: PulseColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contact_emergency,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Emergency Contacts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add trusted contacts who can be notified when you\'re on a date',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PulseColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PulseColors.info.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: PulseColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your contacts can be notified when you go on dates and receive your live location',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contacts list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return _buildContactCard(contact);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
          child: Text(
            contact.name[0].toUpperCase(),
            style: const TextStyle(
              color: PulseColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact.phone,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (contact.relationship != null) ...[
              const SizedBox(height: 4),
              Text(
                contact.relationship!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'remove') {
              _removeContact(contact);
            } else if (value == 'test') {
              _testNotification(contact);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'test',
              child: Row(
                children: [
                  Icon(Icons.send_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Send Test Message'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: PulseColors.error),
                  SizedBox(width: 12),
                  Text('Remove', style: TextStyle(color: PulseColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testNotification(EmergencyContact contact) {
    // TODO: Send test notification
    PulseToast.info(
      context,
      message: 'Test notification sent to ${contact.name}',
    );
  }
}

/// Add Contact Dialog
class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _relationship;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship (Optional)',
                prefixIcon: Icon(Icons.people_outline),
              ),
              items: const [
                DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                DropdownMenuItem(value: 'Partner', child: Text('Partner')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _relationship = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                EmergencyContact(
                  name: _nameController.text,
                  phone: _phoneController.text,
                  relationship: _relationship,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: PulseColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Contact'),
        ),
      ],
    );
  }
}

/// Safety Tips Sheet
class _SafetyTipsSheet extends StatelessWidget {
  const _SafetyTipsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: PulseColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Dating Safety Tips',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSafetyTip(
            Icons.location_on_outlined,
            'Meet in Public',
            'Always meet in a public place for first dates',
          ),
          _buildSafetyTip(
            Icons.people_outline,
            'Tell Someone',
            'Let friends or family know where you\'re going',
          ),
          _buildSafetyTip(
            Icons.phone_outlined,
            'Keep Your Phone Charged',
            'Ensure your phone is charged for emergencies',
          ),
          _buildSafetyTip(
            Icons.local_drink_outlined,
            'Watch Your Drink',
            'Never leave your drink unattended',
          ),
          _buildSafetyTip(
            Icons.directions_car_outlined,
            'Arrange Your Own Transport',
            'Drive yourself or use a trusted ride service',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Got It'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: PulseColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Emergency Contact Model
class EmergencyContact {
  final String name;
  final String phone;
  final String? relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String?,
    );
  }
}
