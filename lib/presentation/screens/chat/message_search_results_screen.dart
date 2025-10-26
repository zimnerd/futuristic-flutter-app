import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/utils/search_query_parser.dart';
import '../../../data/models/chat_model.dart';
import '../../../blocs/chat_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/skeleton_loading.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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
  final SearchQueryParser _queryParser = SearchQueryParser();
  List<String> _recentSearches = [];
  String? _selectedConversation;
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;
  Timer? _debounceTimer; // ✅ Added for search debouncing
  ParsedSearchQuery? _parsedQuery; // Stores the parsed query for filtering

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _selectedConversation = widget.conversationId;
    _loadRecentSearches();

    // ✅ Add listener for real-time search with debouncing
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // ✅ Cancel timer on dispose
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ✅ Debounced search handler
  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    if (_searchController.text.trim().isEmpty) {
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_message_searches') ?? [];
      if (mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
      // Fallback to empty list if loading fails
      if (mounted) {
        setState(() {
          _recentSearches = [];
        });
      }
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_message_searches', _recentSearches);
    } catch (e) {
      debugPrint('Error saving recent search: $e');
      // Continue silently - search still works even if persistence fails
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    _saveRecentSearch(query);
    HapticFeedback.lightImpact();

    // Parse the query for advanced syntax
    setState(() {
      _parsedQuery = _queryParser.parse(query);
    });

    // Use simplified query for backend search (removes special syntax)
    final searchQuery = _parsedQuery!.hasSpecialSyntax
        ? _parsedQuery!.simplifiedQuery
        : query;

    // Trigger search via ChatBloc
    context.read<ChatBloc>().add(
      SearchMessages(
        query: searchQuery.isNotEmpty ? searchQuery : query,
        conversationId: _selectedConversation,
      ),
    );
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

  /// Show dialog with advanced search syntax help
  void _showSearchSyntaxHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Advanced Search Syntax'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use these special commands to refine your search:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildSyntaxExample(
                '"exact phrase"',
                'Find messages with this exact phrase',
                'Example: "hello world"',
              ),
              const SizedBox(height: 12),
              _buildSyntaxExample(
                'sender:username',
                'Filter by sender username',
                'Example: sender:john',
              ),
              const SizedBox(height: 12),
              _buildSyntaxExample(
                'after:YYYY-MM-DD',
                'Find messages after this date',
                'Example: after:2024-01-01',
              ),
              const SizedBox(height: 12),
              _buildSyntaxExample(
                'before:YYYY-MM-DD',
                'Find messages before this date',
                'Example: before:2024-12-31',
              ),
              const SizedBox(height: 16),
              Text(
                'You can combine multiple commands:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '"project update" sender:sarah after:2024-01-15',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: PulseColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxExample(
    String syntax,
    String description,
    String example,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          syntax,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: PulseColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 13, color: context.onSurfaceVariantColor),
        ),
        const SizedBox(height: 2),
        Text(
          example,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: context.onSurfaceVariantColor,
          ),
        ),
      ],
    );
  }

  /// Apply client-side filtering based on advanced search syntax
  List<MessageModel> _applyAdvancedFilters(List<MessageModel> messages) {
    if (_parsedQuery == null || !_parsedQuery!.hasSpecialSyntax) {
      return messages;
    }

    return messages.where((message) {
      // Filter by sender (username or user ID)
      if (_parsedQuery!.sender != null) {
        final sender = _parsedQuery!.sender!.toLowerCase();
        final senderUsername = message.senderUsername.toLowerCase();
        final senderId = message.senderId.toLowerCase();

        if (!senderUsername.contains(sender) && !senderId.contains(sender)) {
          return false;
        }
      }

      // Filter by date range (before)
      if (_parsedQuery!.beforeDate != null) {
        if (message.createdAt.isAfter(_parsedQuery!.beforeDate!)) {
          return false;
        }
      }

      // Filter by date range (after)
      if (_parsedQuery!.afterDate != null) {
        if (message.createdAt.isBefore(_parsedQuery!.afterDate!)) {
          return false;
        }
      }

      // Filter by exact phrases
      if (_parsedQuery!.phrases.isNotEmpty) {
        final content = message.content?.toLowerCase() ?? '';
        for (final phrase in _parsedQuery!.phrases) {
          if (!content.contains(phrase.toLowerCase())) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PulseColors.primary,
        foregroundColor: context.onSurfaceColor,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          autofocus: widget.initialQuery == null,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          // Search is triggered automatically via debounced listener
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Search syntax help',
            onPressed: _showSearchSyntaxHelp,
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: context.onSurfaceColor,
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
          // Active syntax filters indicator
          if (_parsedQuery != null && _parsedQuery!.hasSpecialSyntax)
            _buildActiveFiltersChip(),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(),

          // Search results
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (previous, current) {
                // Only rebuild for search-related state changes
                return current is MessageSearchLoading ||
                    current is MessageSearchLoaded ||
                    current is MessageSearchError;
              },
              builder: (context, state) {
                if (state is MessageSearchLoading) {
                  return _buildLoadingState();
                }

                if (state is MessageSearchLoaded) {
                  // Apply advanced filters client-side
                  final filteredResults = _applyAdvancedFilters(
                    state.searchResults,
                  );

                  if (filteredResults.isEmpty) {
                    return _buildEmptyResults();
                  }
                  return _buildSearchResults(filteredResults);
                }

                if (state is MessageSearchError) {
                  return _buildErrorState(state.error);
                }

                // Show recent searches when no search performed
                return _buildRecentSearches();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChip() {
    final filters = <String>[];

    if (_parsedQuery!.phrases.isNotEmpty) {
      filters.add(
        '${_parsedQuery!.phrases.length} phrase${_parsedQuery!.phrases.length > 1 ? 's' : ''}',
      );
    }
    if (_parsedQuery!.sender != null) {
      filters.add('sender:${_parsedQuery!.sender}');
    }
    if (_parsedQuery!.afterDate != null) {
      filters.add(
        'after:${DateFormat('yyyy-MM-dd').format(_parsedQuery!.afterDate!)}',
      );
    }
    if (_parsedQuery!.beforeDate != null) {
      filters.add(
        'before:${DateFormat('yyyy-MM-dd').format(_parsedQuery!.beforeDate!)}',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: PulseColors.primary.withValues(alpha: 0.1),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Icon(Icons.filter_alt, size: 16, color: PulseColors.primary),
          ...filters.map(
            (filter) => Chip(
              label: Text(filter, style: TextStyle(fontSize: 12)),
              backgroundColor: context.surfaceColor,
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () {
                // Clear all advanced syntax and perform plain search
                _searchController.text = _parsedQuery!.simplifiedQuery;
                _performSearch(_parsedQuery!.simplifiedQuery);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
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
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Icons.calendar_today, size: 20),
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
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: Icon(Icons.close, size: 20),
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
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (previous, current) {
              // Only rebuild when conversations change
              if (previous is ConversationsLoaded &&
                  current is ConversationsLoaded) {
                return previous.conversations != current.conversations;
              }
              return current is ConversationsLoaded;
            },
            builder: (context, chatState) {
              List<DropdownMenuItem<String?>> dropdownItems = [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All conversations'),
                ),
              ];

              // Add conversations if loaded
              if (chatState is ConversationsLoaded) {
                final conversations = chatState.conversations;

                dropdownItems.addAll(
                  conversations.map((conversation) {
                    // Use otherUserName from ConversationModel
                    final displayName = conversation.otherUserName;

                    return DropdownMenuItem<String>(
                      value: conversation.id,
                      child: Text(displayName, overflow: TextOverflow.ellipsis),
                    );
                  }),
                );
              }

              return Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _selectedConversation,
                      isExpanded: true,
                      hint: Text('All conversations'),
                      underline: const SizedBox(),
                      items: dropdownItems,
                      onChanged: (value) {
                        setState(() => _selectedConversation = value);
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
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

  Widget _buildSearchResults(List<MessageModel> messages) {
    // Convert MessageModel to MessageSearchResult
    final results = messages.map((message) {
      return MessageSearchResult(
        message: message,
        senderName: message.senderUsername,
        conversationName:
            message.conversationId, // Will show conversation ID for now
      );
    }).toList();

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
        final conversationMessages = groupedResults[conversationName]!;

        return Column(
          key: ValueKey(conversationName), // ✅ Added ValueKey for performance
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversation header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                conversationName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.primary,
                ),
              ),
            ),

            // Messages in this conversation
            ...conversationMessages.map(
              (result) => _buildMessageResultCard(result),
            ),

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
        side: BorderSide(color: context.outlineColor.withValues(alpha: 0.15)!),
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
                    backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      result.senderName[0].toUpperCase(),
                      style: TextStyle(
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatTimestamp(result.message.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.onSurfaceVariantColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.outlineColor),
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
        style: TextStyle(height: 1.4),
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
          style: TextStyle(
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
        style: TextStyle(
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
        message:
            'Search across all your conversations to find specific messages',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recent Searches',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._recentSearches.map(
          (search) => ListTile(
            leading: Icon(Icons.history, color: context.outlineColor),
            title: Text(search),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 20),
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
