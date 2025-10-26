import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../navigation/app_router.dart';
import '../../blocs/speed_dating/speed_dating_bloc.dart';
import '../../blocs/speed_dating/speed_dating_event.dart';
import '../../blocs/speed_dating/speed_dating_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/speed_dating/speed_dating_event_card.dart';
import '../../widgets/speed_dating/active_session_widget.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Main screen for speed dating functionality
class SpeedDatingScreen extends StatefulWidget {
  const SpeedDatingScreen({super.key});

  @override
  State<SpeedDatingScreen> createState() => _SpeedDatingScreenState();
}

class _SpeedDatingScreenState extends State<SpeedDatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final List<String> _categories = [
    'all',
    'general',
    'professional',
    'casual',
    'themed',
  ];

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speed Dating',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: isSmallScreen
              ? const [
                  Tab(icon: Icon(Icons.event)),
                  Tab(icon: Icon(Icons.speed)),
                  Tab(icon: Icon(Icons.history)),
                ]
              : const [
                  Tab(icon: Icon(Icons.event), text: 'Events'),
                  Tab(icon: Icon(Icons.speed), text: 'Active'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                ],
        ),
      ),
      body: BlocListener<SpeedDatingBloc, SpeedDatingState>(
        listener: (context, state) {
          // Show success toasts for join/leave actions
          if (state is SpeedDatingJoined) {
            PulseToast.success(
              context,
              message: 'Successfully joined the event!',
            );
          } else if (state is SpeedDatingLeft) {
            PulseToast.success(context, message: 'Successfully left the event');
          }
        },
        child: BlocBuilder<SpeedDatingBloc, SpeedDatingState>(
          builder: (context, state) {
            if (state is SpeedDatingLoading) {
              return Center(child: PulseLoadingWidget());
            }

            if (state is SpeedDatingError) {
              return PulseErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<SpeedDatingBloc>().add(LoadSpeedDatingEvents());
                  context.read<SpeedDatingBloc>().add(
                    LoadUserSpeedDatingSessions(),
                  );
                },
              );
            }

            if (state is SpeedDatingLoaded) {
              return Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventsTab(state),
                      _buildActiveTab(state),
                      _buildHistoryTab(state),
                    ],
                  ),
                  // Show loading indicator at top when refreshing
                  if (state.isRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 3,
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            PulseColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            // For joining/joined/leaving/left states, show loading
            // The BLoC will emit SpeedDatingLoaded once events refresh
            return Center(child: PulseLoadingWidget());
          },
        ),
      ),
    );
  }

  Widget _buildEventsTab(SpeedDatingLoaded state) {
    // Filter events based on search and category
    final filteredEvents = state.events.where((event) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          event['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          event['description'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      
      final matchesCategory =
          _selectedCategory == 'all' ||
          event['category']?.toString() == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: context.outlineColor.shade50,
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category[0].toUpperCase() + category.substring(1),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: context.surfaceColor,
                        selectedColor: PulseColors.primary.withValues(
                          alpha: 0.2,
                        ),
                        checkmarkColor: PulseColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? PulseColors.primary
                              : context.outlineColor.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Events List
        Expanded(
          child: filteredEvents.isEmpty
              ? _buildEmptyEvents()
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<SpeedDatingBloc>().add(
                      LoadSpeedDatingEvents(),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
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
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyEvents() {
    if (_searchQuery.isNotEmpty || _selectedCategory != 'all') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: context.outlineColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'No Events Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Try adjusting your search or filters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: context.onSurfaceVariantColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = 'all';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: context.onSurfaceColor,
                ),
                child: Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: context.outlineColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No Speed Dating Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back soon! Admins will post new events regularly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceVariantColor,
              ),
            ),
          ],
        ),
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
            onLeaveSession: () =>
                _leaveSession(state.currentSession!['eventId']),
          ),
          const SizedBox(height: 24),
          if (state.matches.isNotEmpty) ...[
            Text(
              'Recent Matches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              color: context.outlineColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Session',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Join a speed dating event to start meeting new people!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceVariantColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
              ),
              child: Text('Browse Events'),
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
              color: context.outlineColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No Dating History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your past speed dating sessions will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceVariantColor,
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
                      ? Icon(Icons.person)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  match['name'] ?? 'Unknown',
                  style: TextStyle(
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
                    color: context.onSurfaceVariantColor,
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
    final String? imageUrl = session['imageUrl'];
    final String title =
        session['title'] ?? session['eventTitle'] ?? 'Speed Dating Event';

    // Parse startTime from API
    final DateTime? startTime = DateTime.tryParse(session['startTime'] ?? '');
    final String date = startTime != null
        ? '${startTime.day}/${startTime.month}/${startTime.year}'
        : (session['date'] ?? 'Unknown');

    final int matchesCount = session['matchesCount'] ?? 0;
    final bool isCompleted =
        session['status'] == 'completed' || session['completed'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: PulseColors.secondary.withValues(alpha: 0.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.speed,
                      color: PulseColors.secondary,
                      size: 28,
                    ),
                  )
                : Icon(
                    Icons.speed,
                    color: PulseColors.secondary,
                    size: 28,
                  ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Date: $date',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Text(
              'Matches: $matchesCount',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        trailing: Icon(
          isCompleted ? Icons.check_circle : Icons.schedule,
          color: isCompleted ? Colors.green : Colors.orange,
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
    context.push(
      AppRoutes.speedDatingRoom,
      extra: {'session': session, 'eventId': session['eventId'] ?? ''},
    );
  }

  void _viewEventDetails(Map<String, dynamic> event) {
    context.push(AppRoutes.speedDatingEventDetails, extra: event);
  }

  void _viewSessionDetails(Map<String, dynamic> session) {
    context.push(
      AppRoutes.speedDatingRoom,
      extra: {'session': session, 'eventId': session['eventId'] ?? ''},
    );
  }
}
