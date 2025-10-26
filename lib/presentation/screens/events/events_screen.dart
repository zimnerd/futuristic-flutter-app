import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/event.dart';
import '../../blocs/event/event_bloc.dart';
import '../../blocs/event/event_event.dart';
import '../../blocs/event/event_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/events/event_card.dart';
import '../../widgets/events/category_chip.dart';
import '../../widgets/events/advanced_filters_modal.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_toast.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  final bool _showJoinedOnly = false;
  String? _joiningEventId;
  bool _shouldRefreshOnReturn = false;

  @override
  void initState() {
    super.initState();

    // Add observer to detect when app comes to foreground
    WidgetsBinding.instance.addObserver(this);

    // Defer event loading until after build completes to ensure bloc context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('📱 Events Screen: PostFrameCallback triggered');
      _loadEventsIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload events when app comes to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      AppLogger.info(
        '📱 Events Screen: App resumed, checking if reload needed',
      );
      _loadEventsIfNeeded();
    }
  }

  void _loadEventsIfNeeded() {
    try {
      final bloc = context.read<EventBloc>();
      final currentState = bloc.state;

      AppLogger.info(
        '📱 Events Screen: _loadEventsIfNeeded() - Current state: ${currentState.runtimeType}',
      );

      // 🔧 FIX: Also reload if state is EventDetailsLoaded (user just viewed event details)
      if (currentState is EventInitial ||
          currentState is EventError ||
          currentState is EventDetailsLoaded || // ← Added this!
          (currentState is EventsLoaded && currentState.events.isEmpty)) {
        AppLogger.info('📱 Events Screen: Loading events...');
        _loadEvents();
      } else {
        AppLogger.info('📱 Events Screen: Events already loaded, skipping');
      }
    } catch (e, stackTrace) {
      AppLogger.error('📱 Events Screen: ERROR in _loadEventsIfNeeded: $e');
      AppLogger.error('📱 Stack trace: $stackTrace');
    }
  }

  void _loadEvents() {
    try {
      AppLogger.info('📱 Events Screen: _loadEvents() called');
      final bloc = context.read<EventBloc>();
      AppLogger.info(
        '📱 Events Screen: Got EventBloc, current state: ${bloc.state.runtimeType}',
      );
      AppLogger.info('📱 Events Screen: Dispatching LoadEvents...');
      bloc.add(const LoadEvents());
      AppLogger.info('📱 Events Screen: LoadEvents dispatched');
    } catch (e, stackTrace) {
      AppLogger.error('📱 Events Screen: ERROR in _loadEvents: $e');
      AppLogger.error('📱 Stack trace: $stackTrace');
    }
  }

  void _onCategorySelected(String? category) {
    AppLogger.info(
      '📱 _onCategorySelected: category=$category, previous=$_selectedCategory',
    );
    setState(() {
      _selectedCategory = category;
    });
    context.read<EventBloc>().add(FilterEventsByCategory(category));
  }

  void _onSearchChanged(String query) {
    context.read<EventBloc>().add(SearchEvents(query));
  }

  void _onEventTap(Event event) async {
    // Navigate to event details and wait for return
    await context.push('/events/${event.id}');

    // Check if we should refresh after navigation
    if (_shouldRefreshOnReturn && mounted) {
      AppLogger.info('📱 Events Screen: Refreshing after return from details');
      _loadEvents();
      _shouldRefreshOnReturn = false;
    }
  }

  void _onAttendEvent(Event event) {
    setState(() {
      _joiningEventId = event.id;
    });
    context.read<EventBloc>().add(AttendEvent(event.id));
  }

  void _onLeaveEvent(Event event) {
    setState(() {
      _joiningEventId = event.id;
    });
    context.read<EventBloc>().add(LeaveEvent(event.id));
  }

  void _onCreateEvent() {
    context.push('/events/create');
  }

  void _onRefreshCategories() {
    AppLogger.info('📱 Events Screen: Refresh button tapped');
    context.read<EventBloc>().add(RefreshEventCategories());
    // Also reload events, not just categories!
    _loadEvents();
  }

  void _onShowFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdvancedFiltersModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventBloc, EventState>(
      listener: (context, state) {
        AppLogger.info(
          '📱 Events Screen BlocListener: state = ${state.runtimeType}',
        );

        // Handle attendance updates - mark that we should refresh on return
        if (state is EventAttendanceUpdated) {
          AppLogger.info(
            '📱 Events Screen: Attendance updated, setting refresh flag',
          );
          _shouldRefreshOnReturn = true;

          if (_joiningEventId != null) {
            setState(() {
              _joiningEventId = null;
            });
          }

          if (state.isAttending) {
            PulseToast.success(
              context,
              message: 'Successfully joined the event!',
              duration: const Duration(seconds: 2),
            );
          } else {
            PulseToast.info(
              context,
              message: 'Left the event',
              duration: const Duration(seconds: 2),
            );
          }
        }

        // Clear joining state when events are loaded
        if (state is EventsLoaded) {
          AppLogger.info('📱 Events Screen: EventsLoaded received');
          if (_joiningEventId != null) {
            setState(() {
              _joiningEventId = null;
            });
          }
        }

        // Handle errors
        if (state is EventError) {
          AppLogger.error('📱 Events Screen: Error - ${state.message}');
          if (_joiningEventId != null) {
            setState(() {
              _joiningEventId = null;
            });
          }

          String errorMessage = state.message;
          if (errorMessage.contains('Already attending') ||
              errorMessage.contains('already attending')) {
            errorMessage = 'You have already joined this event!';
          }

          PulseToast.error(
            context,
            message: errorMessage,
            duration: const Duration(seconds: 3),
          );
        }
      },
      child: KeyboardDismissibleScaffold(
        backgroundColor: PulseColors.surface,
        appBar: AppBar(
          backgroundColor: PulseColors.surface,
          elevation: 0,
          title: Text(
            'Events',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.onSurfaceColor,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _onCreateEvent,
              icon: Icon(Icons.add, color: PulseColors.primary),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Row(
              children: [
                Expanded(
                  child: CategoryFilterChips(
                    selectedCategorySlug: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                ),
              ],
            ),
            Expanded(
              child: BlocBuilder<EventBloc, EventState>(
                buildWhen: (previous, current) {
                  // Only rebuild when events data actually changes
                  if (previous is EventsLoaded && current is EventsLoaded) {
                    return previous.events != current.events ||
                        previous.filteredEvents != current.filteredEvents;
                  }
                  // Always rebuild for state type changes
                  return previous.runtimeType != current.runtimeType;
                },
                builder: (context, state) {
                  AppLogger.info(
                    '📱 BlocBuilder rebuilding - State: ${state.runtimeType}',
                  );

                  if (state is EventsLoaded) {
                    AppLogger.info(
                      '📱 BlocBuilder: EventsLoaded - events: ${state.events.length}, filtered: ${state.filteredEvents.length}',
                    );
                  }

                  if (state is EventLoading) {
                    return _buildLoadingState();
                  } else if (state is EventsLoaded) {
                    return _buildEventsLoaded(state);
                  } else if (state is EventRefreshing) {
                    return _buildRefreshingState(state);
                  } else if (state is EventDetailsLoaded) {
                    // 🔧 FIX: Handle EventDetailsLoaded - user just viewed event details
                    // Trigger reload to get back to EventsLoaded state
                    AppLogger.info(
                      '📱 BlocBuilder: EventDetailsLoaded detected, triggering reload',
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _loadEvents();
                      }
                    });
                    return _buildLoadingState();
                  } else if (state is EventCategoriesLoaded) {
                    // 🔧 FIX: Handle EventCategoriesLoaded - categories refreshed
                    // Trigger reload to get back to EventsLoaded state
                    AppLogger.info(
                      '📱 BlocBuilder: EventCategoriesLoaded detected, triggering reload',
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _loadEvents();
                      }
                    });
                    return _buildLoadingState();
                  } else if (state is EventError) {
                    return _buildErrorState(state);
                  } else {
                    AppLogger.info('📱 BlocBuilder: Showing empty state');
                    return _buildEmptyState();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: PulseColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: TextStyle(color: PulseColors.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search,
                    color: PulseColors.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: Icon(
                            Icons.clear,
                            color: PulseColors.onSurfaceVariant,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Reload Button
          Container(
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PulseColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _onRefreshCategories,
              icon: Icon(Icons.refresh, color: PulseColors.primary),
              tooltip: 'Refresh events',
            ),
          ),

          const SizedBox(width: 8),

          // Filter Button (for future advanced filters)
          Container(
            decoration: BoxDecoration(
              color: PulseColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _onShowFilters,
              icon: Icon(Icons.tune, color: PulseColors.onSurfaceVariant),
              tooltip: 'Advanced filters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: PulseColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading events...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsLoaded(EventsLoaded state) {
    AppLogger.info(
      '📱 _buildEventsLoaded called - events: ${state.events.length}, filteredEvents: ${state.filteredEvents.length}',
    );

    // Apply joined filter if enabled
    final eventsToShow = _showJoinedOnly
        ? state.filteredEvents.where((e) => e.isAttending).toList()
        : state.filteredEvents;

    AppLogger.info(
      '📱 _buildEventsLoaded - eventsToShow after join filter: ${eventsToShow.length}, _showJoinedOnly: $_showJoinedOnly',
    );

    if (eventsToShow.isEmpty) {
      AppLogger.info('📱 _buildEventsLoaded - Showing empty filtered state');
      return _buildEmptyFilteredState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<EventBloc>().add(const RefreshEvents());
      },
      color: PulseColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 56),
        itemCount: eventsToShow.length,
        itemBuilder: (context, index) {
          final event = eventsToShow[index];
          return EventCard(
            key: ValueKey(event.id),
            event: event,
            onTap: () => _onEventTap(event),
            onAttend: () => _onAttendEvent(event),
            onLeave: () => _onLeaveEvent(event),
            isLoading: _joiningEventId == event.id,
          );
        },
      ),
    );
  }

  Widget _buildRefreshingState(EventRefreshing state) {
    // Apply joined filter if enabled
    final eventsToShow = _showJoinedOnly
        ? state.currentEvents.where((e) => e.isAttending).toList()
        : state.currentEvents;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: PulseColors.primary.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: PulseColors.primary,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Refreshing events...',
                style: TextStyle(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 56),
            itemCount: eventsToShow.length,
            itemBuilder: (context, index) {
              final event = eventsToShow[index];
              return EventCard(
                key: ValueKey(event.id),
                event: event,
                onTap: () => _onEventTap(event),
                onAttend: () => _onAttendEvent(event),
                onLeave: () => _onLeaveEvent(event),
                isLoading: _joiningEventId == event.id,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(EventError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: PulseColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: PulseColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No events yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create an event and bring people together!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onCreateEvent,
              icon: Icon(Icons.add),
              label: Text('Create Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: PulseColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != null
                  ? 'No ${EventCategories.getDisplayName(_selectedCategory!).toLowerCase()} events match your search'
                  : 'No events match your search criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = null;
                });
                context.read<EventBloc>().add(
                  const FilterEventsByCategory(null),
                );
                context.read<EventBloc>().add(const SearchEvents(''));
              },
              icon: Icon(Icons.clear_all),
              label: Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: PulseColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
