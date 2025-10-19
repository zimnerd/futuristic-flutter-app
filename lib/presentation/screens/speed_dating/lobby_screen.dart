import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/speed_dating_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/pulse_toast.dart';
import 'active_round_screen.dart';

/// Speed Dating Lobby Screen
/// Shows event details, participant list, and join/leave controls
class SpeedDatingLobbyScreen extends StatefulWidget {
  final String eventId;

  const SpeedDatingLobbyScreen({super.key, required this.eventId});

  @override
  State<SpeedDatingLobbyScreen> createState() => _SpeedDatingLobbyScreenState();
}

class _SpeedDatingLobbyScreenState extends State<SpeedDatingLobbyScreen> {
  final SpeedDatingService _speedDatingService = SpeedDatingService();

  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  bool _isJoining = false;
  bool _hasJoined = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEventData();
    _listenToEventStatus();
  }

  Future<void> _loadEventData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await _speedDatingService.getEventById(widget.eventId);

      if (event != null && mounted) {
        setState(() {
          _event = event;
          _participants = List<Map<String, dynamic>>.from(
            event['participants'] ?? [],
          );
          _isLoading = false;

          // Check if current user has joined
          final currentUserId = _getCurrentUserId();
          _hasJoined = _participants.any((p) => p['userId'] == currentUserId);
        });
      } else if (mounted) {
        setState(() {
          _error = 'Event not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load event: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _listenToEventStatus() {
    _speedDatingService.onEventStatusChanged.listen((status) {
      if (status == SpeedDatingEventStatus.active && mounted) {
        // Event has started - navigate to active round
        final userId = _getCurrentUserId();
        if (userId != null && _event != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ActiveRoundScreen(
                eventId: widget.eventId,
                sessionId:
                    _event!['currentSessionId'] as String? ?? widget.eventId,
              ),
            ),
          );
        } else {
          PulseToast.info(context, message: 'Event has started!');
        }
      }
    });
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  Future<void> _joinEvent() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final participant = await _speedDatingService.joinEvent(
        widget.eventId,
        userId,
      );

      if (participant != null && mounted) {
        setState(() {
          _hasJoined = true;
          _isJoining = false;
        });

        // Reload event data to get updated participant list
        await _loadEventData();

        if (mounted) {
          PulseToast.success(
            context,
            message: 'Successfully joined the event!',
          );
        }
      } else if (mounted) {
        setState(() {
          _error = 'Failed to join event';
          _isJoining = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error joining event: $e';
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leaveEvent() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Event'),
        content: const Text('Are you sure you want to leave this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final success = await _speedDatingService.leaveEvent(
        widget.eventId,
        userId,
      );

      if (success && mounted) {
        setState(() {
          _hasJoined = false;
          _isJoining = false;
        });

        // Reload event data
        await _loadEventData();

        if (mounted) {
          PulseToast.info(context, message: 'Left the event');
        }
      } else if (mounted) {
        setState(() {
          _error = 'Failed to leave event';
          _isJoining = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error leaving event: $e';
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _startEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Event'),
        content: const Text(
          'Are you sure you want to start the speed dating event? '
          'All participants will begin their first round.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Event'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _speedDatingService.startEvent(widget.eventId);

      // Navigation will happen via event status listener
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start event: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Dating Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEventData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEventData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return const Center(child: Text('Event not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadEventData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEventCard(),
            const SizedBox(height: 24),
            _buildParticipantsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    final event = _event!;
    final scheduledAt = DateTime.parse(event['scheduledAt'] as String);
    final duration = event['duration'] as int;
    final maxParticipants = event['maxParticipants'] as int;
    final status = event['status'] as String;
    final isVirtual = event['isVirtual'] as bool? ?? true;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event['title'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            if (event['description'] != null)
              Text(
                event['description'] as String,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            const SizedBox(height: 16),
            _buildEventDetail(
              Icons.calendar_today,
              DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledAt),
            ),
            const SizedBox(height: 8),
            _buildEventDetail(Icons.timer, '$duration minutes'),
            const SizedBox(height: 8),
            _buildEventDetail(
              Icons.group,
              '${_participants.length} / $maxParticipants participants',
            ),
            const SizedBox(height: 8),
            _buildEventDetail(
              isVirtual ? Icons.videocam : Icons.location_on,
              isVirtual
                  ? 'Virtual Event'
                  : (event['location'] as String? ?? 'TBA'),
            ),
            if (event['ageMin'] != null || event['ageMax'] != null) ...[
              const SizedBox(height: 8),
              _buildEventDetail(
                Icons.cake,
                'Age: ${event['ageMin'] ?? '18'} - ${event['ageMax'] ?? '100'}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.orange;
        label = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Participants',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_participants.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_participants.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No participants yet.\nBe the first to join!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _participants.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _buildParticipantItem(_participants[index]),
          ),
      ],
    );
  }

  Widget _buildParticipantItem(Map<String, dynamic> participant) {
    final user = participant['user'] as Map<String, dynamic>?;
    if (user == null) return const SizedBox.shrink();

    final name = user['name'] as String? ?? 'Unknown';
    final photoUrl = user['photoUrl'] as String?;
    final age = user['age'] as int?;
    final status = participant['status'] as String? ?? 'registered';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        child: photoUrl == null ? Text(name[0].toUpperCase()) : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: age != null ? Text('$age years old') : null,
      trailing: status == 'active'
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildActionButtons() {
    if (_event == null) return const SizedBox.shrink();

    final status = _event!['status'] as String;

    // Check if current user is organizer (event creator)
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : '';
    final isOrganizer = _event!['creatorId'] == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'upcoming') ...[
          if (_hasJoined)
            ElevatedButton(
              onPressed: _isJoining ? null : _leaveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Leave Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )
          else
            ElevatedButton(
              onPressed: _isJoining ? null : _joinEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E3BFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Join Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          // Organizer can start event when 4+ participants are present
          if (isOrganizer && _participants.length >= 4) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startEvent,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Event'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
