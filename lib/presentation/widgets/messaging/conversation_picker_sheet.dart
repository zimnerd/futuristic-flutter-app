import 'package:flutter/material.dart';
import '../../../domain/entities/conversation.dart';
import '../../theme/pulse_colors.dart';
import '../common/robust_network_image.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Conversation Picker Sheet
///
/// Modal bottom sheet for selecting conversations to forward messages to.
/// Features:
/// - Multi-select mode with checkboxes
/// - Search conversations
/// - Display conversation avatars and names
/// - Group chat indicators
/// - Last message preview
/// - Selection count indicator
class ConversationPickerSheet extends StatefulWidget {
  final List<Conversation> conversations;
  final Function(List<String> conversationIds) onConversationsSelected;
  final bool allowMultiSelect;

  const ConversationPickerSheet({
    super.key,
    required this.conversations,
    required this.onConversationsSelected,
    this.allowMultiSelect = true,
  });

  @override
  State<ConversationPickerSheet> createState() =>
      _ConversationPickerSheetState();
}

class _ConversationPickerSheetState extends State<ConversationPickerSheet> {
  final Set<String> _selectedConversationIds = {};
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _filteredConversations = widget.conversations;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = widget.conversations;
      } else {
        _filteredConversations = widget.conversations.where((conv) {
          final name = conv.otherUserName.toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower);
        }).toList();
      }
    });
  }

  void _toggleConversation(String conversationId) {
    setState(() {
      if (widget.allowMultiSelect) {
        if (_selectedConversationIds.contains(conversationId)) {
          _selectedConversationIds.remove(conversationId);
        } else {
          _selectedConversationIds.add(conversationId);
        }
      } else {
        _selectedConversationIds.clear();
        _selectedConversationIds.add(conversationId);
        // For single select, immediately return the selection
        widget.onConversationsSelected([conversationId]);
        Navigator.pop(context);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedConversationIds.isNotEmpty) {
      widget.onConversationsSelected(_selectedConversationIds.toList());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: PulseColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outlineColor.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Forward to...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
                if (widget.allowMultiSelect &&
                    _selectedConversationIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: PulseColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedConversationIds.length} selected',
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterConversations,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: context.outlineColor.shade400),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.outlineColor.shade400,
                ),
                filled: true,
                fillColor: context.outlineColor.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Conversations list
          Expanded(
            child: _filteredConversations.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'No conversations yet'
                          : 'No conversations found',
                      style: TextStyle(
                        color: context.outlineColor.shade400,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _filteredConversations[index];
                      final isSelected = _selectedConversationIds.contains(
                        conversation.id,
                      );

                      return InkWell(
                        onTap: () => _toggleConversation(conversation.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? PulseColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        context.outlineColor.shade800,
                                    child: RobustNetworkImage(
                                      imageUrl: conversation.otherUserAvatar,
                                      blurhash:
                                          conversation.otherUserAvatarBlurhash,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(24),
                                      errorWidget: Icon(
                                        Icons.person,
                                        color: context.outlineColor.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 12),

                              // Conversation info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conversation.otherUserName,
                                      style: TextStyle(
                                        color: context.onSurfaceColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      conversation.lastMessage,
                                      style: TextStyle(
                                        color: context.outlineColor.shade400,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Checkbox (multi-select only)
                              if (widget.allowMultiSelect)
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (_) =>
                                      _toggleConversation(conversation.id),
                                  fillColor: WidgetStateProperty.resolveWith((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return PulseColors.primary;
                                    }
                                    return null;
                                  }),
                                  checkColor: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm button (multi-select only)
          if (widget.allowMultiSelect)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PulseColors.surfaceDark,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedConversationIds.isEmpty
                        ? null
                        : _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      disabledBackgroundColor: context.outlineColor.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedConversationIds.isEmpty
                          ? 'Select conversations'
                          : 'Forward to ${_selectedConversationIds.length} conversation${_selectedConversationIds.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.onSurfaceColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
