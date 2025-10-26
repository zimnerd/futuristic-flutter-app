import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../../data/services/speed_dating_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../widgets/common/pulse_toast.dart';

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

  // Real-time listeners
  StreamSubscription? _eventStatusSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadEventData();
    _setupRealTimeListeners();
    _startAutoRefresh();
  }

  void _setupRealTimeListeners() {
    // Listen to event status changes
    _eventStatusSubscription = _speedDatingService.onEventStatusChanged.listen((
      status,
    ) {
      if (!mounted) return;

      if (status == SpeedDatingEventStatus.active) {
        _handleEventStarted();
      } else if (status == SpeedDatingEventStatus.completed) {
        _handleEventCompleted();
      } else if (status == SpeedDatingEventStatus.cancelled) {
        _handleEventCancelled();
      }
    });
  }

  void _startAutoRefresh() {
    // Auto-refresh every 15 seconds to ensure data is fresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !_isLoading) {
        _loadEventData();
      }
    });
  }

  void _handleEventStarted() {
    if (!mounted) return;

    final userId = _getCurrentUserId();
    if (userId != null && _event != null) {
      PulseToast.success(context, message: 'Event has started!');
      // Navigate to active round screen using GoRouter
      context.goNamed(
        'speedDatingActive',
        pathParameters: {
          'eventId': widget.eventId,
          'sessionId': _event!['currentSessionId'] as String? ?? widget.eventId,
        },
      );
    }
  }

  void _handleEventCompleted() {
    if (!mounted) return;
    PulseToast.info(context, message: 'Event has completed');
    context.goNamed('speedDating');
  }

  void _handleEventCancelled() {
    if (!mounted) return;
    PulseToast.error(context, message: 'Event has been cancelled');
    context.goNamed('speedDating');
  }

  Future<void> _loadEventData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await _speedDatingService.getEventById(widget.eventId);

      if (event != null && mounted) {
        final currentUserId = _getCurrentUserId();
        final updatedParticipants = List<Map<String, dynamic>>.from(
          event['participants'] ?? [],
        );

        setState(() {
          _event = event;
          _participants = updatedParticipants;
          _isLoading = false;
          _hasJoined = updatedParticipants.any(
            (p) => p['userId'] == currentUserId,
          );
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

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  Future<void> _joinEvent() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      PulseToast.error(context, message: 'User not authenticated');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final participant = await _speedDatingService.joinEvent(widget.eventId);

      if (participant != null && mounted) {
        setState(() {
          _hasJoined = true;
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
    if (userId == null) {
      PulseToast.error(context, message: 'User not authenticated');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(
          'Leave Event',
          style: TextStyle(color: context.onSurfaceColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to leave this event?',
          style: TextStyle(color: context.onSurfaceColor, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Leave',
              style: TextStyle(
                color: context.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      final success = await _speedDatingService.leaveEvent(widget.eventId);

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
    if (_event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(
          'Start Event',
          style: TextStyle(color: context.onSurfaceColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to start the speed dating event? '
          'All participants will begin their first round.',
          style: TextStyle(color: context.onSurfaceColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E3BFF),
            ),
            child: Text('Start Event'),
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
      // Event status listener will handle navigation
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start event: $e';
          _isLoading = false;
        });
      }
      if (mounted) {
        PulseToast.error(context, message: 'Failed to start event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.goNamed('speedDating');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Speed Dating Lobby'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.goNamed('speedDating'),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadEventData,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _event == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null && _event == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.errorColor),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEventData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return Center(child: Text('Event not found'));
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
            const SizedBox(height: 16),
            if (_error != null) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.errorColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: context.errorColor, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.errorColor, size: 20),
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
          ),
        ],
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
                    style: TextStyle(
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
                style: TextStyle(
                  fontSize: 16,
                  color: context.onSurfaceVariantColor,
                ),
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
        color = context.successColor;
        label = 'Active';
        break;
      case 'completed':
        color = context.primaryColor;
        label = 'Completed';
        break;
      case 'cancelled':
        color = context.errorColor;
        label = 'Cancelled';
        break;
      default:
        color = context.statusWarning;
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
        Icon(icon, size: 20, color: context.onSurfaceVariantColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
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
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_participants.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No participants yet.\nBe the first to join!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: context.outlineColor),
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
        backgroundColor: context.outlineColor.withValues(alpha: 0.3),
        child: photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: age != null ? Text('$age years old') : null,
      trailing: status == 'active'
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
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
        if (status.toLowerCase() == 'upcoming') ...[
          if (_hasJoined)
            ElevatedButton(
              onPressed: _isJoining ? null : _leaveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.errorColor,
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
                  : Text(
                      'Leave Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceColor,
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
                  : Text(
                      'Join Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceColor,
                      ),
                    ),
            ),
          // Organizer can start event when 4+ participants are present
          if (isOrganizer && _participants.length >= 4) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startEvent,
              icon: Icon(Icons.play_arrow),
              label: Text('Start Event'),
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
    // Clean up subscriptions and timers
    _eventStatusSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
