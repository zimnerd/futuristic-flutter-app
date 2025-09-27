import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/event.dart';
import '../../blocs/event/event_bloc.dart';
import '../../blocs/event/event_event.dart';
import '../../blocs/event/event_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/events/event_card.dart';
import '../../widgets/events/category_chip.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    context.read<EventBloc>().add(const LoadEvents());
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    context.read<EventBloc>().add(FilterEventsByCategory(category));
  }

  void _onSearchChanged(String query) {
    context.read<EventBloc>().add(SearchEvents(query));
  }

  void _onEventTap(Event event) {
    context.push('/events/${event.id}');
  }

  void _onAttendEvent(Event event) {
    context.read<EventBloc>().add(AttendEvent(event.id));
  }

  void _onLeaveEvent(Event event) {
    context.read<EventBloc>().add(LeaveEvent(event.id));
  }

  void _onCreateEvent() {
    context.push('/events/create');
  }

  void _onRefreshCategories() {
    context.read<EventBloc>().add(RefreshEventCategories());
  }

  void _onShowFilters() {
    // TODO: Implement advanced filters modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Advanced filters coming soon!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: PulseColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.surface,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        title: Text(
          'Events',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: PulseColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onCreateEvent,
            icon: Icon(
              Icons.add,
              color: PulseColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Category Filter
          CategoryFilterChips(
            selectedCategorySlug: _selectedCategory,
            onCategorySelected: _onCategorySelected,
          ),
          
          // Events List
          Expanded(
            child: BlocConsumer<EventBloc, EventState>(
              listener: (context, state) {
                if (state is EventError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: PulseColors.error,
                    ),
                  );
                } else if (state is EventAttendanceUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.isAttending 
                            ? 'Successfully joined the event!' 
                            : 'Left the event',
                      ),
                      backgroundColor: state.isAttending 
                          ? PulseColors.success 
                          : PulseColors.onSurfaceVariant,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is EventLoading) {
                  return _buildLoadingState();
                } else if (state is EventsLoaded) {
                  return _buildEventsLoaded(state);
                } else if (state is EventRefreshing) {
                  return _buildRefreshingState(state);
                } else if (state is EventError) {
                  return _buildErrorState(state);
                } else {
                  return _buildEmptyState();
                }
              },
            ),
          ),
        ],
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
              color: PulseColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PulseColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _onRefreshCategories,
              icon: Icon(
                Icons.refresh,
                color: PulseColors.primary,
              ),
              tooltip: 'Refresh categories',
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
              icon: Icon(
                Icons.tune,
                color: PulseColors.onSurfaceVariant,
              ),
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
          CircularProgressIndicator(
            color: PulseColors.primary,
          ),
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
    if (state.filteredEvents.isEmpty) {
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
        itemCount: state.filteredEvents.length,
        itemBuilder: (context, index) {
          final event = state.filteredEvents[index];
          return EventCard(
            event: event,
            onTap: () => _onEventTap(event),
            onAttend: () => _onAttendEvent(event),
            onLeave: () => _onLeaveEvent(event),
          );
        },
      ),
    );
  }

  Widget _buildRefreshingState(EventRefreshing state) {
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
            itemCount: state.currentEvents.length,
            itemBuilder: (context, index) {
              final event = state.currentEvents[index];
              return EventCard(
                event: event,
                onTap: () => _onEventTap(event),
                onAttend: () => _onAttendEvent(event),
                onLeave: () => _onLeaveEvent(event),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: PulseColors.error,
            ),
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
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
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
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
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
                context.read<EventBloc>().add(const FilterEventsByCategory(null));
                context.read<EventBloc>().add(const SearchEvents(''));
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                foregroundColor: PulseColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}