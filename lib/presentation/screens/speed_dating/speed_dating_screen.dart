import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/speed_dating/speed_dating_bloc.dart';
import '../../blocs/speed_dating/speed_dating_event.dart';
import '../../blocs/speed_dating/speed_dating_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/speed_dating/speed_dating_event_card.dart';
import '../../widgets/speed_dating/active_session_widget.dart';
import '../../theme/pulse_colors.dart';
import 'speed_dating_room_screen.dart';
import 'speed_dating_event_details_screen.dart';
import '../../widgets/speed_dating/create_speed_dating_event_dialog.dart';

/// Main screen for speed dating functionality
class SpeedDatingScreen extends StatefulWidget {
  const SpeedDatingScreen({super.key});

  @override
  State<SpeedDatingScreen> createState() => _SpeedDatingScreenState();
}

class _SpeedDatingScreenState extends State<SpeedDatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<SpeedDatingBloc>().add(LoadSpeedDatingEvents());
    context.read<SpeedDatingBloc>().add(LoadUserSpeedDatingSessions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Dating'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.event),
              text: 'Events',
            ),
            Tab(
              icon: Icon(Icons.speed),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'History',
            ),
          ],
        ),
      ),
      body: BlocBuilder<SpeedDatingBloc, SpeedDatingState>(
        builder: (context, state) {
          if (state is SpeedDatingLoading) {
            return const Center(child: PulseLoadingWidget());
          }

          if (state is SpeedDatingError) {
            return PulseErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<SpeedDatingBloc>().add(LoadSpeedDatingEvents());
                context.read<SpeedDatingBloc>().add(LoadUserSpeedDatingSessions());
              },
            );
          }

          if (state is SpeedDatingLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildEventsTab(state),
                _buildActiveTab(state),
                _buildHistoryTab(state),
              ],
            );
          }

          return const Center(child: PulseLoadingWidget());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEventDialog(),
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildEventsTab(SpeedDatingLoaded state) {
    if (state.events.isEmpty) {
      return _buildEmptyEvents();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SpeedDatingBloc>().add(LoadSpeedDatingEvents());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.events.length,
        itemBuilder: (context, index) {
          final event = state.events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SpeedDatingEventCard(
              event: event,
              onJoin: () => _joinEvent(event['id']),
              onViewDetails: () => _viewEventDetails(event),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTab(SpeedDatingLoaded state) {
    if (state.currentSession == null) {
      return _buildNoActiveSession();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ActiveSessionWidget(
            session: state.currentSession!,
            onEnterRoom: () => _enterSpeedDatingRoom(state.currentSession!),
            onLeaveSession: () => _leaveSession(state.currentSession!['eventId']),
          ),
          const SizedBox(height: 24),
          if (state.matches.isNotEmpty) ...[
            const Text(
              'Recent Matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMatchesList(state.matches),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(SpeedDatingLoaded state) {
    if (state.userSessions.isEmpty) {
      return _buildEmptyHistory();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.userSessions.length,
      itemBuilder: (context, index) {
        final session = state.userSessions[index];
        return _buildHistoryCard(session);
      },
    );
  }

  Widget _buildEmptyEvents() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Speed Dating Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to create a speed dating event in your area!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveSession() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Session',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join a speed dating event to start meeting new people!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Browse Events'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Dating History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your past speed dating sessions will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(List<Map<String, dynamic>> matches) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: match['avatarUrl'] != null
                      ? NetworkImage(match['avatarUrl'])
                      : null,
                  backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
                  child: match['avatarUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  match['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${match['matchScore'] ?? 0}% match',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: PulseColors.secondary.withValues(alpha: 0.2),
          child: const Icon(Icons.speed, color: PulseColors.secondary),
        ),
        title: Text(session['eventTitle'] ?? 'Speed Dating Event'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${session['date'] ?? 'Unknown'}'),
            Text('Matches: ${session['matchesCount'] ?? 0}'),
          ],
        ),
        trailing: Icon(
          session['completed'] == true 
            ? Icons.check_circle
            : Icons.schedule,
          color: session['completed'] == true 
            ? Colors.green
            : Colors.orange,
        ),
        onTap: () => _viewSessionDetails(session),
      ),
    );
  }

  void _joinEvent(String eventId) {
    context.read<SpeedDatingBloc>().add(JoinSpeedDatingEvent(eventId));
  }

  void _leaveSession(String eventId) {
    context.read<SpeedDatingBloc>().add(LeaveSpeedDatingEvent(eventId));
  }

  void _enterSpeedDatingRoom(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeedDatingRoomScreen(session: session),
      ),
    );
  }

  void _viewEventDetails(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeedDatingEventDetailsScreen(event: event),
      ),
    );
  }

  void _viewSessionDetails(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeedDatingRoomScreen(session: session),
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateSpeedDatingEventDialog(),
    );
  }
}
