import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../data/models/chat_model.dart';
import '../../../blocs/chat_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/skeleton_loading.dart';

/// Message Search Results Screen
///
/// Displays search results across all conversations with:
/// - Highlighted search terms
/// - Jump to message functionality
/// - Filter by conversation, date, sender
/// - Recent searches history
class MessageSearchResultsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? conversationId; // Optional: search within specific conversation

  const MessageSearchResultsScreen({
    super.key,
    this.initialQuery,
    this.conversationId,
  });

  @override
  State<MessageSearchResultsScreen> createState() =>
      _MessageSearchResultsScreenState();
}

class _MessageSearchResultsScreenState
    extends State<MessageSearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<String> _recentSearches = [];
  String? _selectedConversation;
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _selectedConversation = widget.conversationId;
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // TODO: Load from local storage
    setState(() {
      _recentSearches = [
        'dinner plans',
        'coffee',
        'weekend',
      ];
    });
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });
    // TODO: Save to local storage
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    _saveRecentSearch(query);
    HapticFeedback.lightImpact();

    // TODO: Implement SearchMessages event in ChatBloc
    // context.read<ChatBloc>().add(
    //       SearchMessages(
    //         query: query,
    //         conversationId: _selectedConversation,
    //         startDate: _selectedDateRange?.start,
    //         endDate: _selectedDateRange?.end,
    //       ),
    //     );
  }

  void _jumpToMessage(MessageModel message) {
    HapticFeedback.mediumImpact();

    // Navigate to chat screen with message highlighted
    context.pop(); // Close search results
    context.push(
      '/chat/${message.conversationId}',
      extra: {'highlightMessageId': message.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          autofocus: widget.initialQuery == null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onSubmitted: _performSearch,
          onChanged: (value) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters panel
          if (_showFilters) _buildFiltersPanel(),

          // Search results
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                // TODO: Implement ChatSearching and ChatSearchResults states in ChatBloc
                // if (state is ChatSearching) {
                //   return _buildLoadingState();
                // }

                // if (state is ChatSearchResults) {
                //   if (state.results.isEmpty) {
                //     return _buildEmptyResults();
                //   }
                //   return _buildSearchResults(state.results);
                // }

                // if (state is ChatError) {
                //   return _buildErrorState(state.message);
                // }

                // Show recent searches when no search performed
                return _buildRecentSearches();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range filter
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    }
                  },
                  child: Text(
                    _selectedDateRange == null
                        ? 'Any date'
                        : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() => _selectedDateRange = null);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Conversation filter
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  value: _selectedConversation,
                  isExpanded: true,
                  hint: const Text('All conversations'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All conversations'),
                    ),
                    // TODO: Load actual conversations
                  ],
                  onChanged: (value) {
                    setState(() => _selectedConversation = value);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(List<MessageSearchResult> results) {
    // Group by conversation
    final groupedResults = <String, List<MessageSearchResult>>{};
    for (final result in results) {
      final key = result.conversationName ?? 'Unknown';
      groupedResults.putIfAbsent(key, () => []).add(result);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final conversationName = groupedResults.keys.elementAt(index);
        final messages = groupedResults[conversationName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversation header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                conversationName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.primary,
                ),
              ),
            ),

            // Messages in this conversation
            ...messages.map((result) => _buildMessageResultCard(result)),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildMessageResultCard(MessageSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _jumpToMessage(result.message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender and timestamp
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: PulseColors.primary.withOpacity(0.1),
                    child: Text(
                      result.senderName[0].toUpperCase(),
                      style: const TextStyle(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatTimestamp(result.message.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Message preview with highlighted search term
              _buildHighlightedText(
                result.message.content ?? '',
                _searchController.text,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String searchTerm) {
    if (searchTerm.isEmpty) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(height: 1.4),
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerTerm = searchTerm.toLowerCase();
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final index = lowerText.indexOf(lowerTerm, currentIndex);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }

      if (index > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + searchTerm.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );

      currentIndex = index + searchTerm.length;
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search,
        title: 'Search Messages',
        message: 'Search across all your conversations to find specific messages',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._recentSearches.map(
          (search) => ListTile(
            leading: const Icon(Icons.history, color: Colors.grey),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() => _recentSearches.remove(search));
              },
            ),
            onTap: () {
              _searchController.text = search;
              _performSearch(search);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'Try different keywords or adjust your filters',
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Search Error',
      message: message,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}

/// Model for search results
class MessageSearchResult {
  final MessageModel message;
  final String senderName;
  final String? conversationName;

  MessageSearchResult({
    required this.message,
    required this.senderName,
    this.conversationName,
  });
}
