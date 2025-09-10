import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/live_streaming/live_streaming_bloc.dart';
import '../../blocs/live_streaming/live_streaming_event.dart';
import '../../blocs/live_streaming/live_streaming_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/live_streaming/live_stream_card.dart';
import '../../widgets/live_streaming/stream_category_filter.dart';
import '../../theme/pulse_colors.dart';
import 'start_stream_screen.dart';
import 'live_stream_viewer_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<LiveStreamingBloc>().add(const LoadLiveStreams());
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streaming'),
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
                return const PulseLoadingWidget();
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

              return const Center(child: PulseLoadingWidget());
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
          return const PulseLoadingWidget();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StartStreamScreen(),
      ),
    );
  }

  void _joinStream(Map<String, dynamic> stream) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewerScreen(stream: stream),
      ),
    );
  }

  void _viewStreamDetails(Map<String, dynamic> stream) {
    // TODO: Navigate to stream details screen
  }

  void _editStream(Map<String, dynamic> stream) {
    // TODO: Navigate to edit stream screen
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
            onPressed: () {
              // TODO: Implement delete stream
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stream deleted successfully'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportStream(Map<String, dynamic> stream) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Stream'),
        content: const Text('Why are you reporting this stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement report stream
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stream reported successfully')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
