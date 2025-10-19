import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

/// Participant Picker Dialog for Group Creation
///
/// Displays a searchable list of users to add as group participants.
/// Features:
/// - Real-time search with debouncing
/// - User cards with photo, name, and location
/// - Multi-select with visual feedback
/// - Already selected participants shown at top
class ParticipantPickerDialog extends StatefulWidget {
  final List<String> initialSelectedIds;

  const ParticipantPickerDialog({
    super.key,
    this.initialSelectedIds = const [],
  });

  @override
  State<ParticipantPickerDialog> createState() =>
      _ParticipantPickerDialogState();
}

class _ParticipantPickerDialogState extends State<ParticipantPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient.instance;

  List<Map<String, dynamic>> _users = [];
  Set<String> _selectedIds = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
    _loadUsers();
  }

  Future<void> _loadUsers({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch matched users instead of all users
      // This ensures users can only add people they've matched with
      final response = await _apiClient.get(ApiConstants.matchingMatches);

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? response.data as List;
        setState(() {
          _users = data.map((u) => u as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load matched users');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load matched users: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      // API returns nested structure: {id: matchId, user: {firstName, lastName, ...}}
      final userData = user['user'] as Map<String, dynamic>? ?? user;
      final firstName = (userData['firstName'] as String? ?? '').toLowerCase();
      final lastName = (userData['lastName'] as String? ?? '').toLowerCase();
      final fullName = '$firstName $lastName';
      return fullName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.person_add, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Participants',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedIds.length} selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild for filtering
                },
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ),

            // User list
            Expanded(child: _buildUserList()),

            const Divider(height: 1),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () {
                              // Return map of {userId: fullName} for selected users
                              final selectedData = <String, String>{};
                              for (final user in _users) {
                                final userData =
                                    user['user'] as Map<String, dynamic>? ??
                                    user;
                                final userId =
                                    userData['id'] as String? ??
                                    user['id'] as String;
                                if (_selectedIds.contains(userId)) {
                                  final firstName =
                                      userData['firstName'] as String? ??
                                      'Unknown';
                                  final lastName =
                                      userData['lastName'] as String? ?? '';
                                  selectedData[userId] = '$firstName $lastName'
                                      .trim();
                                }
                              }
                              Navigator.pop(context, selectedData);
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredUsers = _filteredUsers;

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No users found'
                  : 'No users match your search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    // API returns nested structure: {id: matchId, user: {id, firstName, lastName, photos, ...}}
    final matchId = user['id'] as String;
    final userData = user['user'] as Map<String, dynamic>? ?? user;
    final userId = userData['id'] as String? ?? matchId;
    final firstName = userData['firstName'] as String? ?? 'Unknown';
    final lastName = userData['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final photos = userData['photos'] as List?;
    final profilePhoto = photos != null && photos.isNotEmpty
        ? photos[0] as String?
        : null;
    final location = userData['location'] as String?;
    final isSelected = _selectedIds.contains(userId);

    return ListTile(
      onTap: () => _toggleSelection(userId),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: profilePhoto != null
                ? CachedNetworkImageProvider(profilePhoto)
                : null,
            child: profilePhoto == null
                ? Text(
                    firstName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Text(
        fullName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF202124), // PulseColors.onSurface
        ),
      ),
      subtitle: location != null
          ? Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: Color(0xFF5F6368),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5F6368), // PulseColors.onSurfaceVariant
                    ),
                  ),
                ),
              ],
            )
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleSelection(userId),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
