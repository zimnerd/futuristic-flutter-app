import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Enhanced search widget for message conversations
class MessageSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> conversations;
  final Function(String) onSearch;

  MessageSearchDelegate({required this.conversations, required this.onSearch})
    : super(
        searchFieldLabel: 'Search conversations...',
        searchFieldStyle: PulseTextStyles.bodyMedium.copyWith(
          color: PulseColors.onSurface,
        ),
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: PulseColors.onSurface),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: PulseColors.outline),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filterConversations(query);

    if (results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No conversations found',
        subtitle: 'Try adjusting your search terms',
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final conversation = results[index];
        return _buildConversationTile(context, conversation);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }

    final suggestions = _filterConversations(query);

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final conversation = suggestions[index];
        return _buildSuggestionTile(context, conversation);
      },
    );
  }

  List<Map<String, dynamic>> _filterConversations(String searchQuery) {
    if (searchQuery.isEmpty) return conversations;

    final lowercaseQuery = searchQuery.toLowerCase();
    return conversations.where((conversation) {
      final name = (conversation['name'] as String? ?? '').toLowerCase();
      final lastMessage = (conversation['lastMessage'] as String? ?? '')
          .toLowerCase();

      return name.contains(lowercaseQuery) ||
          lastMessage.contains(lowercaseQuery);
    }).toList();
  }

  Widget _buildConversationTile(
    BuildContext context,
    Map<String, dynamic> conversation,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation['avatar'] != null
            ? NetworkImage(conversation['avatar'])
            : null,
        child: conversation['avatar'] == null
            ? Text(
                conversation['name']?.substring(0, 1).toUpperCase() ?? '?',
                style: PulseTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                ),
              )
            : null,
      ),
      title: Text(
        conversation['name'] ?? 'Unknown',
        style: PulseTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        conversation['lastMessage'] ?? '',
        style: PulseTextStyles.bodyMedium.copyWith(
          color: PulseColors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation['timestamp'] ?? '',
            style: PulseTextStyles.bodySmall.copyWith(
              color: PulseColors.outline,
            ),
          ),
          if (conversation['unreadCount'] != null &&
              conversation['unreadCount'] > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PulseColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation['unreadCount']}',
                style: PulseTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        close(context, conversation['id'] ?? '');
      },
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    Map<String, dynamic> conversation,
  ) {
    return ListTile(
      leading: const Icon(Icons.search, color: PulseColors.outline),
      title: RichText(
        text: TextSpan(
          style: PulseTextStyles.bodyMedium.copyWith(
            color: PulseColors.onSurface,
          ),
          children: _highlightSearchTerm(conversation['name'] ?? '', query),
        ),
      ),
      subtitle: conversation['lastMessage'] != null
          ? RichText(
              text: TextSpan(
                style: PulseTextStyles.bodySmall.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
                children: _highlightSearchTerm(
                  conversation['lastMessage'],
                  query,
                ),
              ),
            )
          : null,
      onTap: () {
        query = conversation['name'] ?? '';
        showResults(context);
      },
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    // In a real app, you'd get this from shared preferences or a service
    final recentSearches = ['Emma', 'Alex', 'Sarah', 'Jake'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(PulseSpacing.lg),
          child: Text(
            'Recent searches',
            style: PulseTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...recentSearches.map(
          (search) => ListTile(
            leading: const Icon(Icons.history, color: PulseColors.outline),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: PulseColors.outline),
              onPressed: () {
                // Remove from recent searches
              },
            ),
            onTap: () {
              query = search;
              showResults(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: PulseColors.outline),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            title,
            style: PulseTextStyles.headlineSmall.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            subtitle,
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightSearchTerm(String text, String searchTerm) {
    if (searchTerm.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final lowercaseText = text.toLowerCase();
    final lowercaseSearchTerm = searchTerm.toLowerCase();

    int start = 0;
    int index = lowercaseText.indexOf(lowercaseSearchTerm);

    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchTerm.length),
          style: const TextStyle(
            backgroundColor: PulseColors.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + searchTerm.length;
      index = lowercaseText.indexOf(lowercaseSearchTerm, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}

/// Simple search bar widget for inline search
class MessageSearchBar extends StatefulWidget {
  final String? hint;
  final Function(String) onChanged;
  final Function()? onClear;
  final TextEditingController? controller;

  const MessageSearchBar({
    super.key,
    this.hint,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: _focusNode.hasFocus
              ? PulseColors.primary
              : PulseColors.outline,
          width: _focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: PulseTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Search conversations...',
          hintStyle: PulseTextStyles.bodyMedium.copyWith(
            color: PulseColors.outline,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: PulseSpacing.lg,
            vertical: PulseSpacing.md,
          ),
          prefixIcon: const Icon(Icons.search, color: PulseColors.outline),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: PulseColors.outline),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {}); // Rebuild to show/hide clear button
          widget.onChanged(value);
        },
      ),
    );
  }
}
