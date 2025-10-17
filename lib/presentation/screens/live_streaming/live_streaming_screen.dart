import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../navigation/app_router.dart';
import '../../blocs/live_streaming/live_streaming_bloc.dart';
import '../../blocs/live_streaming/live_streaming_event.dart';
import '../../blocs/live_streaming/live_streaming_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/live_streaming/live_stream_card.dart';
import '../../widgets/live_streaming/stream_card_skeleton.dart';
import '../../widgets/live_streaming/stream_category_filter.dart';
import '../../theme/pulse_colors.dart';
import '../../../data/services/service_locator.dart';
import '../../../data/services/websocket_service_impl.dart';

/// Main screen for live streaming functionality
class LiveStreamingScreen extends StatefulWidget {
  const LiveStreamingScreen({super.key});

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  
  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<LiveStreamingBloc>().add(const LoadLiveStreams());
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Setup real-time viewer count updates
    _setupViewerCountListener();
  }

  void _setupViewerCountListener() {
    try {
      final webSocketService = WebSocketServiceImpl.instance;

      // Listen for stream viewer count updates
      webSocketService.on('stream:viewer_count', (data) {
        if (data != null && data is Map<String, dynamic>) {
          final streamId = data['streamId'] as String?;
          final viewerCount = data['viewerCount'] as int?;

          if (streamId != null && viewerCount != null && mounted) {
            context.read<LiveStreamingBloc>().add(
              UpdateStreamViewers(streamId: streamId, viewerCount: viewerCount),
            );
          }
        }
      });
    } catch (e) {
      // Handle WebSocket connection errors gracefully
      debugPrint('Failed to setup viewer count listener: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more streams when reaching the bottom
      final state = context.read<LiveStreamingBloc>().state;
      if (state is LiveStreamsLoaded && state.hasMoreStreams) {
        context.read<LiveStreamingBloc>().add(
          LoadLiveStreams(
            category: _selectedCategory,
            page: state.currentPage + 1,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounce?.cancel();

    // Create new timer with 300ms delay
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        // Load all streams if search is cleared
        context.read<LiveStreamingBloc>().add(
          LoadLiveStreams(category: _selectedCategory),
        );
      } else {
        // Search streams with query
        context.read<LiveStreamingBloc>().add(
          SearchStreams(query: query, category: _selectedCategory),
        );
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<LiveStreamingBloc>().add(
          LoadLiveStreams(category: _selectedCategory),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search streams...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Live Streaming'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'Scheduled Streams',
            onPressed: () => context.push(AppRoutes.scheduledStreams),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.live_tv),
              text: 'Live Streams',
            ),
            Tab(
              icon: Icon(Icons.videocam),
              text: 'My Streams',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveStreamsTab(),
          _buildMyStreamsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewStream,
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.videocam),
        label: const Text('Go Live'),
      ),
    );
  }

  Widget _buildLiveStreamsTab() {
    return Column(
      children: [
        // Category filter
        StreamCategoryFilter(
          selectedCategory: _selectedCategory,
          onCategoryChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
            context.read<LiveStreamingBloc>().add(
              LoadLiveStreams(category: category),
            );
          },
        ),
        
        // Streams list
        Expanded(
          child: BlocBuilder<LiveStreamingBloc, LiveStreamingState>(
            builder: (context, state) {
              if (state is LiveStreamingLoading && _selectedCategory == null) {
                // Show skeleton loading cards
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: const StreamCardSkeleton(),
                    );
                  },
                );
              }
              
              if (state is LiveStreamingError) {
                return PulseErrorWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<LiveStreamingBloc>().add(
                      const LoadLiveStreams(),
                    );
                  },
                );
              }              if (state is LiveStreamsLoaded) {
                return _buildStreamsList(state);
              }

              // Default loading state
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: const StreamCardSkeleton(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyStreamsTab() {
    return BlocBuilder<LiveStreamingBloc, LiveStreamingState>(
      builder: (context, state) {
        if (state is LiveStreamingLoading) {
          // Show skeleton loading cards
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: const StreamCardSkeleton(),
              );
            },
          );
        }

        if (state is LiveStreamingError) {
          return PulseErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<LiveStreamingBloc>().add(const LoadLiveStreams());
            },
          );
        }

        if (state is StreamingHistoryLoaded) {
          return _buildUserStreamsList(state.history);
        }

        return const Center(
          child: Text('No streams found'),
        );
      },
    );
  }

  Widget _buildStreamsList(LiveStreamsLoaded state) {
    if (state.streams.isEmpty) {
      return _buildEmptyStreams();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LiveStreamingBloc>().add(
          LoadLiveStreams(category: _selectedCategory),
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.streams.length + (state.hasMoreStreams ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.streams.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: PulseLoadingWidget(),
              ),
            );
          }

          final stream = state.streams[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LiveStreamCard(
              stream: stream,
              onTap: () => _joinStream(stream),
              onReport: () => _reportStream(stream),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserStreamsList(List<Map<String, dynamic>> streams) {
    if (streams.isEmpty) {
      return _buildNoStreamsMessage();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: streams.length,
      itemBuilder: (context, index) {
        final stream = streams[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LiveStreamCard(
            stream: stream,
            isOwner: true,
            onTap: () => _viewStreamDetails(stream),
            onEdit: () => _editStream(stream),
            onDelete: () => _deleteStream(stream),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStreams() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Live Streams',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedCategory != null
                  ? 'No streams in $_selectedCategory category right now'
                  : 'No one is live streaming at the moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewStream,
              icon: const Icon(Icons.videocam),
              label: const Text('Be the First to Go Live!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
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

  Widget _buildNoStreamsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Streams Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your first live stream to connect with your matches!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewStream,
              icon: const Icon(Icons.add),
              label: const Text('Start Your First Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
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

  void _startNewStream() {
    context.push(AppRoutes.startStream);
  }

  void _joinStream(Map<String, dynamic> stream) {
    context.push(
      AppRoutes.liveStreamViewer,
      extra: stream,
    );
  }

  void _viewStreamDetails(Map<String, dynamic> stream) {
    // Navigate to stream viewer screen to view/join the stream
    context.push(
      AppRoutes.liveStreamViewer,
      extra: stream,
    );
  }

  void _editStream(Map<String, dynamic> stream) async {
    // Navigate to edit stream screen
    final result = await context.push(
      AppRoutes.startStream,
      extra: stream,
    );
    
    if (result != null && mounted) {
      // Refresh the streams list if stream was updated
      context.read<LiveStreamingBloc>().add(const LoadLiveStreams());
    }
  }

  void _deleteStream(Map<String, dynamic> stream) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stream'),
        content: const Text('Are you sure you want to delete this stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final liveStreamingBloc = context.read<LiveStreamingBloc>();

              navigator.pop();
              
              // Call the service to delete the stream
              try {
                final liveStreamingService =
                    ServiceLocator().liveStreamingService;
                final streamId = stream['id'] ?? '';
                final success = await liveStreamingService.endLiveStream(
                  streamId,
                );

                if (!mounted) return;

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Stream ended successfully')),
                  );
                  // Refresh the streams list
                  liveStreamingBloc.add(
                    const LoadLiveStreams(),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to end stream. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportStream(Map<String, dynamic> stream) {
    String selectedReason = 'Inappropriate content';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Stream'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you reporting this stream?'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items:
                    [
                          'Inappropriate content',
                          'Harassment',
                          'Spam',
                          'Violence',
                          'Copyright violation',
                          'Other',
                        ]
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedReason = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();
                
                // Call the service to report the stream
                try {
                  final liveStreamingService =
                      ServiceLocator().liveStreamingService;
                  final streamId = stream['id'] ?? '';
                  final success = await liveStreamingService.reportStream(
                    streamId: streamId,
                    reason: selectedReason,
                  );

                  if (!mounted) return;

                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Stream reported successfully'),
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to report stream. Please try again.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }
}
