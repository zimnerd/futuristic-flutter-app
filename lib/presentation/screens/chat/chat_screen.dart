import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../blocs/chat_bloc.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/services/service_locator.dart';
import '../../../data/services/background_sync_manager.dart';
import '../../../data/services/audio_call_service.dart';
import '../../../services/media_upload_service.dart' as media_service;
import '../../../domain/entities/message.dart' show MessageType;
import '../../../presentation/blocs/auth/auth_bloc.dart';
import '../../../presentation/blocs/auth/auth_state.dart';
import '../../../presentation/blocs/block_report/block_report_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/haptic_feedback_utils.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/models/voice_message.dart';
import '../../widgets/chat/compact_voice_recorder.dart';
import '../../widgets/chat/animated_typing_indicator.dart';
import '../../widgets/chat/quick_reply_chip_bar.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/dialogs/block_user_dialog.dart';
import '../../widgets/dialogs/report_user_dialog.dart';

import '../../../core/performance/message_pagination_optimizer.dart';
import '../../../core/performance/media_loading_optimizer.dart';
import '../../../core/performance/memory_manager.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/call_message_widget.dart';
import '../../widgets/chat/ai_message_input.dart';
import '../../widgets/chat/rich_ai_chat_assistant_modal.dart';
import '../../sheets/conversation_picker_sheet.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../dialogs/call_back_confirmation_dialog.dart';
import '../../sheets/call_details_bottom_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final UserModel? otherUserProfile;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.otherUserProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageInputFocusNode = FocusNode();
  Timer? _typingTimer;
  Timer? _smartReplyDebounceTimer;
  bool _isCurrentlyTyping = false;
  bool _hasMarkedAsRead =
      false; // Track if we've already marked this conversation as read
  
  // Search functionality state
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<MessageModel> _searchResults = [];
  String _currentSearchQuery = '';
  int _currentSearchIndex = 0;
  
  // Reply functionality state
  MessageModel? _replyToMessage;
  
  // Smart replies state
  List<String> _smartReplySuggestions = [];
  bool _isLoadingSmartReplies = false;
  DateTime? _smartReplyCacheTimestamp;
  static const Duration _smartReplyCacheDuration = Duration(minutes: 5);
  
  // Performance optimizers
  late final MessagePaginationOptimizer _paginationOptimizer;
  late final MediaLoadingOptimizer _mediaOptimizer;
  late final MemoryManager _memoryManager;
  
  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }
  
  @override
  void initState() {
    super.initState();
    
    // Initialize performance optimizers
    _paginationOptimizer = MessagePaginationOptimizer();
    _mediaOptimizer = MediaLoadingOptimizer();
    _memoryManager = MemoryManager();
    _memoryManager.startMemoryManagement();
    
    // Debug information
    AppLogger.debug('ChatScreen initialized with:');
    AppLogger.debug('  conversationId: ${widget.conversationId}');
    AppLogger.debug('  otherUserId: ${widget.otherUserId}');
    AppLogger.debug('  otherUserName: ${widget.otherUserName}');
    
    // Check if this is a new conversation that needs to be created
    if (widget.conversationId == 'new') {
      _createNewConversation();
    } else {
      // Load latest messages for existing conversation (fast cache response)
      context.read<ChatBloc>().add(
        LoadLatestMessages(conversationId: widget.conversationId),
      );

      // Load smart reply suggestions when conversation opens
      _loadSmartReplySuggestions();

      // ✅ We'll mark as read later only if there are actually unread messages
      // This will be handled when we receive MessagesLoaded state
    }
    
    // Auto-scroll to bottom when keyboard appears
    _scrollController.addListener(_scrollListener);
  }

  /// Create a new conversation with the other user
  void _createNewConversation() async {
    AppLogger.debug(
      'Creating new conversation with otherUserId: ${widget.otherUserId}',
    );
    
    if (widget.otherUserId.isEmpty || widget.otherUserId == 'current_user_id') {
      // Handle error - no valid other user ID provided
      AppLogger.warning('Error: Invalid otherUserId: ${widget.otherUserId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot create conversation - invalid user ID'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(); // Go back
      return;
    }
    
    // Dispatch the create conversation event
    context.read<ChatBloc>().add(
      CreateConversation(participantId: widget.otherUserId),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.dispose();
    _messageInputFocusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _typingTimer?.cancel();
    _smartReplyDebounceTimer?.cancel();

    // Cleanup performance optimizers
    _paginationOptimizer.dispose();
    _mediaOptimizer.dispose();
    _memoryManager.stopMemoryManagement();
    
    super.dispose();
  }

  void _scrollListener() {
    // Load more messages when scrolled to top with performance optimization
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      
      // Check if we should load more messages (performance optimization)
      if (!_paginationOptimizer.isLoadingMore(widget.conversationId)) {
        context.read<ChatBloc>().add(
          LoadMessages(conversationId: widget.conversationId),
        );
        
        // Set loading state to prevent duplicate requests
        _paginationOptimizer.setLoadingMore(widget.conversationId, true);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  /// Preload media for visible messages to improve performance
  void _preloadVisibleMedia(List<MessageModel> messages) {
    // Preload media from the most recent messages (likely to be visible)
    final visibleMessages = messages.take(20).toList();

    for (final message in visibleMessages) {
      if ((message.type == MessageType.image ||
              message.type == MessageType.video) &&
          message.mediaUrls?.isNotEmpty == true) {
        // Preload all media URLs in the message
        for (final mediaUrl in message.mediaUrls!) {
          _mediaOptimizer.preloadMedia(
            mediaUrl,
            isVideo: message.type == MessageType.video,
          );
        }
      }
    }
  }

  void _retryFailedMessage(MessageModel message) {
    AppLogger.debug('Retrying failed message: ${message.id}');

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying message...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Trigger background sync to retry messages in outbox
    BackgroundSyncManager.instance.startSync();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Don't allow sending messages to "new" conversation
    if (widget.conversationId == 'new') {
      PulseToast.warning(
        context,
        message: 'Please wait for conversation to be created',
      );
      return;
    }

    final currentUserId = _currentUserId;
    AppLogger.debug('Sending message with currentUserId: $currentUserId');

    // Haptic feedback for sending message
    PulseHaptics.messageSent();

    context.read<ChatBloc>().add(
      SendMessage(
        conversationId: widget.conversationId,
        type: MessageType.text,
        content: text,
        currentUserId: currentUserId,
        replyToMessageId: _replyToMessage?.id,
      ),
    );

    _messageController.clear();
    
    // Clear reply state after sending
    if (_replyToMessage != null) {
      _cancelReply();
    }
    
    _scrollToBottom();
  }

  /// Load smart reply suggestions based on conversation context
  Future<void> _loadSmartReplySuggestions({
    String? lastMessage,
    int retryCount = 0,
  }) async {
    if (widget.conversationId == 'new') return;

    // Check cache validity (5 minutes)
    if (_smartReplyCacheTimestamp != null &&
        _smartReplySuggestions.isNotEmpty) {
      final cacheAge = DateTime.now().difference(_smartReplyCacheTimestamp!);
      if (cacheAge < _smartReplyCacheDuration) {
        AppLogger.debug(
          'Using cached smart reply suggestions (age: ${cacheAge.inMinutes}m)',
        );
        return; // Use cached suggestions
      }
    }

    setState(() {
      _isLoadingSmartReplies = true;
    });

    try {
      final autoReplyService = ServiceLocator().autoReplyService;

      // Get the last message from the conversation if not provided
      String? messageContext = lastMessage;
      if (messageContext == null) {
        final chatState = context.read<ChatBloc>().state;
        if (chatState is MessagesLoaded && chatState.messages.isNotEmpty) {
          final lastMsg = chatState.messages.first;
          messageContext = lastMsg.content;
        }
      }

      if (messageContext != null && messageContext.isNotEmpty) {
        final suggestions = await autoReplyService.generateReplySuggestions(
          conversationId: widget.conversationId,
          lastMessage: messageContext,
          count: 5, // Request 5 suggestions, show best 3-5
        );

        setState(() {
          _smartReplySuggestions = suggestions;
          _smartReplyCacheTimestamp = DateTime.now();
          _isLoadingSmartReplies = false;
        });

        AppLogger.debug('Loaded ${suggestions.length} smart reply suggestions');
      } else {
        setState(() {
          _smartReplySuggestions = [];
          _smartReplyCacheTimestamp = null;
          _isLoadingSmartReplies = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load smart reply suggestions: $e');

      // Retry logic (max 2 retries with exponential backoff)
      if (retryCount < 2) {
        final delaySeconds = 2 * (retryCount + 1); // 2s, 4s
        AppLogger.debug(
          'Retrying smart reply suggestions in ${delaySeconds}s (attempt ${retryCount + 1}/2)',
        );
        await Future.delayed(Duration(seconds: delaySeconds));
        return _loadSmartReplySuggestions(
          lastMessage: lastMessage,
          retryCount: retryCount + 1,
        );
      }

      // Show user-friendly error with retry option after max retries
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to load smart suggestions. Tap refresh to try again.',
            ),
            action: SnackBarAction(
              label: 'Refresh',
              onPressed: () {
                setState(() => _smartReplyCacheTimestamp = null);
                _loadSmartReplySuggestions();
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      setState(() {
        _smartReplySuggestions = [];
        _isLoadingSmartReplies = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Clean up when leaving chat screen
        if (_typingTimer?.isActive == true) {
          _typingTimer?.cancel();
        }
      },
      child: KeyboardDismissibleScaffold(
        enableDismissOnTap: false, // Don't dismiss on message tap
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                  AppLogger.debug(
                    'ChatScreen BlocConsumer listener - State: ${state.runtimeType}',
                  );
                
                if (state is MessagesLoaded) {
                    AppLogger.debug(
                      'ChatScreen - MessagesLoaded with ${state.messages.length} messages',
                    );
                  _scrollToBottom();
                  
                    // Cache messages for performance optimization
                    _paginationOptimizer.addMessages(
                      widget.conversationId,
                      state.messages,
                    );

                    // Preload media for visible messages
                    _preloadVisibleMedia(state.messages);

                    // Reset loading state
                    _paginationOptimizer.setLoadingMore(
                      widget.conversationId,
                      false,
                    );
                  
                    // Debounced smart reply refresh when new message received
                    // Cancel previous timer if exists
                    _smartReplyDebounceTimer?.cancel();
                    _smartReplyDebounceTimer = Timer(
                      const Duration(seconds: 2),
                      () {
                        _loadSmartReplySuggestions();
                      },
                    );
                  
                    // ✅ Only mark as read if we haven't done so yet and there are unread messages
                    if (!_hasMarkedAsRead && _currentUserId != null) {
                      // Check if there are any unread messages from the other user
                      final unreadMessages = state.messages
                          .where(
                            (message) =>
                                message.senderId != _currentUserId &&
                                message.status != MessageStatus.read,
                          )
                          .toList();

                      if (unreadMessages.isNotEmpty) {
                        context.read<ChatBloc>().add(
                          MarkConversationAsRead(
                            conversationId: widget.conversationId,
                          ),
                        );
                        _hasMarkedAsRead = true;
                        AppLogger.debug(
                          'ChatScreen - Marked conversation as read (${unreadMessages.length} unread messages)',
                        );
                      } else {
                        AppLogger.debug(
                          'ChatScreen - No unread messages, skipping mark as read',
                        );
                      }
                    }
                } else if (state is ConversationCreated) {
                    AppLogger.debug(
                      'ChatScreen - ConversationCreated: ${state.conversation.id}',
                    );
                  // Navigate to the actual conversation ID
                  final realConversationId = state.conversation.id;

                  // Replace current route with real conversation ID
                  context.go(
                    '/chat/$realConversationId',
                    extra: {
                      'otherUserId': widget.otherUserId,
                      'otherUserName': widget.otherUserName,
                      'otherUserPhoto': widget.otherUserPhoto,
                      'otherUserProfile': widget.otherUserProfile,
                    },
                  );
                  } else if (state is MessageSent) {
                    AppLogger.debug(
                      'ChatScreen - MessageSent: ${state.message.id}',
                    );
                    // Note: MessageSent should rarely occur if we're in MessagesLoaded state
                    _scrollToBottom();
                  } else if (state is MessageSearchLoaded) {
                    AppLogger.debug(
                      'ChatScreen - MessageSearchLoaded: Found ${state.searchResults.length} results for query "${state.query}"',
                    );
                    // Update local search results for UI navigation
                    setState(() {
                      _searchResults = state.searchResults;
                      _currentSearchIndex = 0;
                      // Scroll to first result if any found
                      if (_searchResults.isNotEmpty) {
                        _scrollToSearchResult(_searchResults[0]);
                      }
                    });
                  } else if (state is MessageSearchError) {
                    AppLogger.error(
                      'ChatScreen - MessageSearchError: ${state.error}',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Search failed: ${state.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is ChatError) {
                    AppLogger.error('ChatScreen - ChatError: ${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              builder: (context, state) {
                  AppLogger.debug(
                    'UI Builder called with state: ${state.runtimeType}',
                  );
                  if (state is MessagesLoaded) {
                    AppLogger.debug(
                      'UI Builder - MessagesLoaded with ${state.messages.length} messages',
                    );
                  }
                return _buildMessagesList(state);
              },
            ),
          ),
          _buildTypingIndicator(),
            QuickReplyChipBar(
              suggestions: _smartReplySuggestions,
              isLoading: _isLoadingSmartReplies,
              onChipTap: (suggestion) {
                // Track smart reply usage (edit mode)
                AnalyticsService.instance.trackFeatureUsage(
                  featureName: 'smart_reply_edit',
                  properties: {
                    'conversationId': widget.conversationId,
                    'suggestion_length': suggestion.length,
                    'action': 'populate_for_edit',
                  },
                );
                // Populate message field with suggestion for editing
                _messageController.text = suggestion;
                _messageInputFocusNode.requestFocus();
              },
              onChipLongPress: (suggestion) {
                // Track smart reply usage (direct send)
                AnalyticsService.instance.trackFeatureUsage(
                  featureName: 'smart_reply_send',
                  properties: {
                    'conversationId': widget.conversationId,
                    'suggestion_length': suggestion.length,
                    'action': 'direct_send',
                  },
                );
                // Send suggestion directly without editing
                _messageController.text = suggestion;
                _sendMessage();
              },
              onChipDismiss: (suggestion) {
                // Track dismissed suggestion
                AnalyticsService.instance.trackFeatureUsage(
                  featureName: 'smart_reply_dismiss',
                  properties: {
                    'conversationId': widget.conversationId,
                    'suggestion_length': suggestion.length,
                  },
                );
                // Remove dismissed suggestion from list
                setState(() {
                  _smartReplySuggestions.remove(suggestion);
                });
              },
              onRefresh: () {
                // Track manual refresh
                AnalyticsService.instance.trackButtonClick(
                  buttonName: 'smart_reply_refresh',
                  screenName: 'chat_screen',
                  properties: {
                    'conversationId': widget.conversationId,
                    'cache_age_minutes': _smartReplyCacheTimestamp != null
                        ? DateTime.now()
                              .difference(_smartReplyCacheTimestamp!)
                              .inMinutes
                        : null,
                  },
                );
                // Force refresh suggestions by invalidating cache
                setState(() {
                  _smartReplyCacheTimestamp = null;
                });
                _loadSmartReplySuggestions();
                AppLogger.debug('Manual smart reply refresh triggered');
              },
            ),
          AiMessageInput(
            controller: _messageController,
            chatId: widget.conversationId,
              currentUserId: _currentUserId,
              matchUserId: widget.otherUserId,
            onSend: _sendMessage,
            onCamera: _handleCameraAction,
            onGallery: _handleGalleryAction,
              onVideoCamera: _handleVideoCameraAction,
              onVideoGallery: _handleVideoGalleryAction,
            onVoice: _handleVoiceAction,
              replyToMessage: _replyToMessage,
              onCancelReply: _cancelReply,
            onTyping: () {
              // Debounce typing status to avoid spam
              // Only send typing_start if we're not already typing
              if (!_isCurrentlyTyping) {
                _isCurrentlyTyping = true;
                context.read<ChatBloc>().add(
                  UpdateTypingStatus(
                    conversationId: widget.conversationId,
                    isTyping: true,
                  ),
                );
              }

              // Reset the stop typing timer
              _typingTimer?.cancel();
              _typingTimer = Timer(const Duration(seconds: 2), () {
                if (_isCurrentlyTyping) {
                  _isCurrentlyTyping = false;
                  context.read<ChatBloc>().add(
                    UpdateTypingStatus(
                      conversationId: widget.conversationId,
                      isTyping: false,
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return _isSearchActive ? _buildSearchAppBar() : _buildNormalAppBar();
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PulseColors.primary,
              PulseColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back button for search
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearchActive = false;
                      _currentSearchQuery = '';
                      _searchResults.clear();
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                // Search input
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search messages...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                ),

                // Search navigation buttons
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_currentSearchIndex + 1}/${_searchResults.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  IconButton(
                    onPressed: _currentSearchIndex > 0
                        ? _previousSearchResult
                        : null,
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentSearchIndex < _searchResults.length - 1
                        ? _nextSearchResult
                        : null,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [PulseColors.primary, PulseColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),

                // Profile avatar with online indicator
                GestureDetector(
                  onTap: () => _viewFullProfile(context),
                  child: Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.otherUserPhoto != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.otherUserPhoto!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: PulseColors.primary.withValues(alpha: 0.3),
                                  child: Text(
                                    widget.otherUserName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Online indicator
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: PulseColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // User info
                Expanded(
                  child: GestureDetector(
                    onTap: () => _viewFullProfile(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (widget.otherUserProfile != null) ...[
                          Text(
                            '${widget.otherUserProfile!.age ?? 'Unknown'} • ${widget.otherUserProfile!.location ?? 'Location unknown'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.otherUserProfile!.bio?.isNotEmpty == true)
                            Text(
                              widget.otherUserProfile!.bio!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ] else
                          Text(
                            'Active now',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _initiateCall(context, false),
                      icon: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _initiateCall(context, true),
                      icon: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSearchActive = true;
                        });
                        // Auto-focus search field
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _searchFocusNode.requestFocus();
                        });
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 22,
                      ),
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 20),
                              SizedBox(width: 12),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Block User',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'unmatch',
                          child: Row(
                            children: [
                              Icon(
                                Icons.heart_broken,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Unmatch',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(
                                Icons.report,
                                size: 20,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Report User',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatState state) {
    AppLogger.debug(
      '_buildMessagesList called with state: ${state.runtimeType}',
    );
    
    if (state is ChatLoading) {
      AppLogger.debug('_buildMessagesList - Showing loading indicator');
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
        ),
      );
    }

    if (state is ChatError) {
      AppLogger.error('_buildMessagesList - Showing error: ${state.message}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ChatBloc>().add(
                  LoadLatestMessages(conversationId: widget.conversationId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is MessagesLoaded) {
      AppLogger.debug(
        '_buildMessagesList - MessagesLoaded with ${state.messages.length} messages',
      );
      
      if (state.messages.isEmpty) {
        AppLogger.debug('_buildMessagesList - Showing empty state');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 64),
              SizedBox(height: 16),
              Text(
                'No messages yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Send a message to start the conversation!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<ChatBloc>().add(
            RefreshMessages(conversationId: widget.conversationId),
          );

          // Wait for refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            // Check if user scrolled to the bottom (where older messages are)
            if (scrollNotification.metrics.pixels >=
                    scrollNotification.metrics.maxScrollExtent * 0.9 &&
                state.hasMoreMessages &&
                !state.isLoadingMore) {
              AppLogger.debug(
                'Loading more messages - user scrolled to bottom',
              );

              // Get the oldest message ID for pagination
              final oldestMessageId = state.messages.isNotEmpty
                  ? state.messages.last.id
                  : null;

              context.read<ChatBloc>().add(
                LoadMoreMessages(
                  conversationId: widget.conversationId,
                  oldestMessageId: oldestMessageId,
                ),
              );
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount:
                state.messages.length +
                (state.hasMoreMessages
                    ? 1
                    : 0) + // Add loading indicator at bottom
                (state.isRefreshing ? 1 : 0), // Add refresh indicator at top
            itemBuilder: (context, index) {
              // Show refresh indicator at top (index 0 in reverse list)
              if (state.isRefreshing && index == 0) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Refreshing...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Adjust index for refresh indicator
              final messageIndex = state.isRefreshing ? index - 1 : index;

              // Show load more indicator at bottom (last index in reverse list)
              if (state.hasMoreMessages &&
                  messageIndex >= state.messages.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: state.isLoadingMore
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading more messages...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () {
                              AppLogger.debug(
                                'Manual load more messages triggered',
                              );
                              final oldestMessageId = state.messages.isNotEmpty
                                  ? state.messages.last.id
                                  : null;

                              context.read<ChatBloc>().add(
                                LoadMoreMessages(
                                  conversationId: widget.conversationId,
                                  oldestMessageId: oldestMessageId,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Tap to load older messages',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              }

              // Regular message item
              if (messageIndex < state.messages.length) {
                final message = state.messages[messageIndex];
                final currentUserId = _currentUserId;
                final isCurrentUser =
                    currentUserId != null && message.senderId == currentUserId;

                AppLogger.debug(
                  '_buildMessagesList - Message ${message.id}: senderId=${message.senderId}, currentUserId=$currentUserId, isCurrentUser=$isCurrentUser, content="${message.content}", status=${message.status}',
                );

                // Handle call messages specially
                if (message.type == MessageType.call) {
                  return CallMessageWidget(
                    message: message,
                    isMe: isCurrentUser,
                    onCallBack: () => _handleCallBack(message),
                    onViewDetails: () => _showCallDetails(message),
                  );
                }

                // Regular message bubble for all other message types
                return MessageBubble(
                  message: message,
                  isCurrentUser: isCurrentUser,
                  currentUserId: currentUserId,
                  onLongPress: () => _onLongPress(message),
                  onRetry: () => _retryFailedMessage(message),
                  onReaction: (emoji) => _onReaction(message, emoji),
                  onReply: () => _onReply(message),
                  onMediaTap: () => _onMediaTap(message),
                  isHighlighted:
                      _searchResults.contains(message) &&
                      _searchResults.isNotEmpty &&
                      _searchResults[_currentSearchIndex] == message,
                  searchQuery: _currentSearchQuery.isNotEmpty
                      ? _currentSearchQuery
                      : null,
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    // Handle MessageSent state for fresh conversations
    if (state is MessageSent) {
      AppLogger.debug(
        '_buildMessagesList - MessageSent for fresh conversation, showing single message: ${state.message.id}',
      );

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                children: [
                  MessageBubble(
                    message: state.message,
                    isCurrentUser:
                        true, // MessageSent is always from current user
                    currentUserId: _currentUserId ?? '',
                    onLongPress: () => _onLongPress(state.message),
                    onRetry: () => _retryFailedMessage(state.message),
                    onReaction: (emoji) => _onReaction(state.message, emoji),
                    onReply: () => _onReply(state.message),
                    onMediaTap: () => _onMediaTap(state.message),
                    isHighlighted:
                        _searchResults.contains(state.message) &&
                        _searchResults.isNotEmpty &&
                        _searchResults[_currentSearchIndex] == state.message,
                    searchQuery: _currentSearchQuery.isNotEmpty
                        ? _currentSearchQuery
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTypingIndicator() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is MessagesLoaded &&
            state.conversationId == widget.conversationId &&
            state.typingUsers.isNotEmpty) {
          // Extract typing user names from the map (keys where value is true)
          final typingUserNames = state.typingUsers.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();

          if (typingUserNames.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: widget.otherUserPhoto != null
                      ? CachedNetworkImageProvider(widget.otherUserPhoto!)
                      : null,
                  backgroundColor: PulseColors.primary,
                  child: widget.otherUserPhoto == null
                      ? Text(
                          widget.otherUserName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                // Use the new animated typing indicator widget
                AnimatedTypingIndicator(typingUsers: typingUserNames,
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _viewFullProfile(BuildContext context) {
    // Show a placeholder dialog since profile viewing needs to be implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.otherUserName}\'s Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.otherUserPhoto != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.otherUserPhoto!,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.otherUserProfile != null) ...[
              if (widget.otherUserProfile!.age != null)
                Text('Age: ${widget.otherUserProfile!.age}'),
              if (widget.otherUserProfile!.location != null)
                Text('Location: ${widget.otherUserProfile!.location}'),
              if (widget.otherUserProfile!.bio != null)
                Text('Bio: ${widget.otherUserProfile!.bio}'),
            ] else
              const Text('Profile information not available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateCall(BuildContext context, bool isVideo) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(),
        ),
      );

      // Create call on backend first
      final audioService = AudioCallService.instance;
      final callId = await audioService.initiateAudioCall(
        recipientId: widget.otherUserId,
        recipientName: widget.otherUserName,
        isVideo: isVideo,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (callId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initiate call'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create UserModel from available data
      final remoteUser = UserModel(
        id: widget.otherUserId,
        email: '', // Not available in chat context
        username: widget.otherUserName,
        firstName: widget.otherUserName.split(' ').first,
        lastName: widget.otherUserName.split(' ').length > 1
            ? widget.otherUserName.split(' ').last
            : null,
        photos: widget.otherUserPhoto != null ? [widget.otherUserPhoto!] : [],
        createdAt: DateTime.now(),
      );

      // Navigate to audio call screen with backend-generated call ID
      if (context.mounted) {
        context.push(
          '/audio-call/$callId',
          extra: {
            'remoteUser': remoteUser,
            'isIncoming': false,
            'isVideo': isVideo,
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        _viewFullProfile(context);
        break;
      case 'block':
        _showBlockDialog(context);
        break;
      case 'unmatch':
        _showUnmatchDialog(context);
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<BlockReportBloc>(),
        child: BlocListener<BlockReportBloc, BlockReportState>(
          listener: (context, state) {
            if (state is UserBlocked) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.otherUserName} has been blocked'),
                  backgroundColor: Colors.green,
                ),
              );
              // Close chat after blocking
              this.context.pop();
            } else if (state is BlockReportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to block: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlockUserDialog(
            userId: widget.otherUserId,
            userName: widget.otherUserName,
          ),
        ),
      ),
    );
  }

  void _showUnmatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch User'),
        content: Text(
          'Are you sure you want to unmatch with ${widget.otherUserName}? This will remove them from your matches and delete this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement unmatch functionality
              Navigator.pop(context);
              // Close the chat screen and go back
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unmatched with ${widget.otherUserName}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<BlockReportBloc>(),
        child: BlocListener<BlockReportBloc, BlockReportState>(
          listener: (context, state) {
            if (state is UserReported) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.otherUserName} has been reported'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is BlockReportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to report: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: ReportUserDialog(
            userId: widget.otherUserId,
            userName: widget.otherUserName,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('View ${widget.otherUserName}\'s Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening ${widget.otherUserName}\'s profile',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Mute Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications muted')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('Block ${widget.otherUserName}'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockUserDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text(
                  'Report User',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportUserDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Conversation',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConversationDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Block ${widget.otherUserName}?'),
          content: Text(
            'You won\'t receive messages from ${widget.otherUserName} anymore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.otherUserName} has been blocked'),
                  ),
                );
              },
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showReportUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report ${widget.otherUserName}'),
          content: const Text('Why are you reporting this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.otherUserName} has been reported'),
                  ),
                );
              },
              child: const Text('Report', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text(
            'This conversation will be permanently deleted. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close chat screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleCameraAction() async {
    try {
      AppLogger.debug('Opening camera for photo capture');

      // Check current permission status first
      var cameraPermission = await Permission.camera.status;
      AppLogger.debug('Current camera permission status: $cameraPermission');
      
      // If denied or not determined, request permission
      if (!cameraPermission.isGranted) {
        AppLogger.debug('Requesting camera permission...');
        cameraPermission = await Permission.camera.request();
        AppLogger.debug('Permission request result: $cameraPermission');
      }
      
      // Handle different permission states
      if (cameraPermission.isDenied) {
        AppLogger.warning('Camera permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera permission is required to take photos.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (cameraPermission.isPermanentlyDenied) {
        AppLogger.warning('Camera permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Camera permission is permanently denied. Please enable it in settings.',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
      
      if (!cameraPermission.isGranted) {
        AppLogger.warning('Camera permission not granted: $cameraPermission');
        return;
      }

      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFile != null) {
        AppLogger.debug('Image captured from camera: ${imageFile.path}');
        await _sendImageMessage(File(imageFile.path));
      } else {
        AppLogger.debug('Camera capture cancelled by user');
      }
    } catch (e) {
      AppLogger.error('Error capturing image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to capture image. Please check camera permissions and try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleGalleryAction() async {
    try {
      AppLogger.debug('Opening gallery for photo selection');

      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFile != null) {
        AppLogger.debug('Image selected from gallery: ${imageFile.path}');
        await _sendImageMessage(File(imageFile.path));
      } else {
        AppLogger.debug('Gallery selection cancelled by user');
      }
    } catch (e) {
      AppLogger.error('Error selecting image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleVideoCameraAction() async {
    try {
      AppLogger.debug('Opening camera for video capture');

      // Check current permission status first
      var cameraPermission = await Permission.camera.status;
      var microphonePermission = await Permission.microphone.status;
      
      AppLogger.debug('Current camera permission status: $cameraPermission');
      AppLogger.debug('Current microphone permission status: $microphonePermission');
      
      // Request camera permission if not granted
      if (!cameraPermission.isGranted) {
        AppLogger.debug('Requesting camera permission...');
        cameraPermission = await Permission.camera.request();
        AppLogger.debug('Camera permission request result: $cameraPermission');
      }
      
      // Request microphone permission if not granted
      if (!microphonePermission.isGranted) {
        AppLogger.debug('Requesting microphone permission...');
        microphonePermission = await Permission.microphone.request();
        AppLogger.debug('Microphone permission request result: $microphonePermission');
      }
      
      // Handle camera permission states
      if (cameraPermission.isDenied || microphonePermission.isDenied) {
        AppLogger.warning('Camera or microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera and microphone permissions are required to record videos.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (cameraPermission.isPermanentlyDenied || microphonePermission.isPermanentlyDenied) {
        AppLogger.warning('Camera or microphone permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Permissions are permanently denied. Please enable them in settings.',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
      
      if (!cameraPermission.isGranted || !microphonePermission.isGranted) {
        AppLogger.warning('Required permissions not granted');
        return;
      }

      final picker = ImagePicker();
      final videoFile = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (videoFile != null) {
        AppLogger.debug('Video captured from camera: ${videoFile.path}');
        await _sendVideoMessage(File(videoFile.path));
      } else {
        AppLogger.debug('Video capture cancelled by user');
      }
    } catch (e) {
      AppLogger.error('Error capturing video from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture video. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleVideoGalleryAction() async {
    try {
      AppLogger.debug('Opening gallery for video selection');

      final picker = ImagePicker();
      final videoFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (videoFile != null) {
        AppLogger.debug('Video selected from gallery: ${videoFile.path}');
        await _sendVideoMessage(File(videoFile.path));
      } else {
        AppLogger.debug('Gallery video selection cancelled by user');
      }
    } catch (e) {
      AppLogger.error('Error selecting video from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select video. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleVoiceAction() async {
    // Check microphone permission
    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required for voice messages',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show voice recorder modal
    if (!mounted || !context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: CompactVoiceRecorder(
          onMessageRecorded: (voiceMessage) {
            Navigator.of(context).pop();
            _sendVoiceMessage(voiceMessage);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _sendVoiceMessage(VoiceMessage voiceMessage) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    try {
      // Show uploading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading voice message...'),
          backgroundColor: PulseColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      // Upload voice message file
      final mediaUploadService = ServiceLocator().mediaUploadService;
      final uploadResult = await mediaUploadService.uploadMedia(
        filePath: voiceMessage.audioUrl,
        category: media_service.MediaCategory.chatMessage,
        type: media_service.MediaType.audio,
        isPublic: false,
        requiresModeration: false,
      );

      if (uploadResult.success && uploadResult.mediaId != null) {
        AppLogger.debug(
          'Voice message uploaded successfully: ${uploadResult.mediaId}',
        );

        // Send message with uploaded media
        if (mounted) {
          context.read<ChatBloc>().add(
            SendMessage(
              conversationId: widget.conversationId,
              content: '',
              type: MessageType.audio,
              currentUserId: currentUserId,
              mediaIds: [uploadResult.mediaId!],
              metadata: {
                'duration': voiceMessage.duration,
                'waveform': voiceMessage.waveformData,
              },
              replyToMessageId: _replyToMessage?.id,
            ),
          );

          // Clear reply if set
          if (_replyToMessage != null) {
            setState(() {
              _replyToMessage = null;
            });
          }

          // Scroll to bottom
          _scrollToBottom();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice message sent!'),
              backgroundColor: PulseColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(
          'Failed to upload voice message: ${uploadResult.error}',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to send voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send voice message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    try {
      AppLogger.debug('Preparing to send image message: ${imageFile.path}');

      // Don't allow sending messages to "new" conversation
      if (widget.conversationId == 'new') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for conversation to be created'),
          ),
        );
        return;
      }

      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        AppLogger.warning('Cannot send image - no current user ID');
        return;
      }

      AppLogger.debug(
        'Sending image message with currentUserId: $currentUserId',
      );

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Upload image using MediaUploadService
      final mediaUploadService = ServiceLocator().mediaUploadService;
      final uploadResult = await mediaUploadService.uploadMedia(
        filePath: imageFile.path,
        category: media_service.MediaCategory.chatMessage,
        type: media_service.MediaType.image,
        isPublic: false,
        requiresModeration: false,
      );

      if (uploadResult.success && uploadResult.mediaId != null) {
        AppLogger.debug('Image uploaded successfully: ${uploadResult.mediaId}');

        // Send message with uploaded media
        if (mounted) {
          context.read<ChatBloc>().add(
            SendMessage(
              conversationId: widget.conversationId,
              type: MessageType.image,
              content: '', // No text content for image messages
              currentUserId: currentUserId,
              mediaIds: [uploadResult.mediaId!],
            ),
          );
        }

        _scrollToBottom();

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sent successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Upload failed: ${uploadResult.error ?? "Unknown error"}');
      }
    } catch (e) {
      AppLogger.error('Error sending image message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendVideoMessage(File videoFile) async {
    try {
      AppLogger.debug('Preparing to send video message: ${videoFile.path}');

      // Don't allow sending messages to "new" conversation
      if (widget.conversationId == 'new') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for conversation to be created'),
          ),
        );
        return;
      }

      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        AppLogger.warning('Cannot send video - no current user ID');
        return;
      }

      AppLogger.debug(
        'Sending video message with currentUserId: $currentUserId',
      );

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading video...'),
              ],
            ),
            duration: Duration(seconds: 60), // Longer for videos
          ),
        );
      }

      // Upload video using MediaUploadService
      final mediaUploadService = ServiceLocator().mediaUploadService;
      final uploadResult = await mediaUploadService.uploadMedia(
        filePath: videoFile.path,
        category: media_service.MediaCategory.chatMessage,
        type: media_service.MediaType.video,
        isPublic: false,
        requiresModeration: false,
      );

      if (uploadResult.success && uploadResult.mediaId != null) {
        AppLogger.debug('Video uploaded successfully: ${uploadResult.mediaId}');

        // Send message with uploaded media
        if (mounted) {
          context.read<ChatBloc>().add(
            SendMessage(
              conversationId: widget.conversationId,
              type: MessageType.video,
              content: '', // No text content for video messages
              currentUserId: currentUserId,
              mediaIds: [uploadResult.mediaId!],
            ),
          );
        }

        _scrollToBottom();

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video sent successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(
          'Upload failed: ${uploadResult.error ?? "Unknown error"}',
        );
      }
    } catch (e) {
      AppLogger.error('Error sending video message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    final currentUserId = _currentUserId;
    final isMyMessage = currentUserId != null && message.senderId == currentUserId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  '❤️', '😂', '😢', '😡', '👍', '👎'
                ].map((emoji) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _addReaction(message.id, emoji);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action options
            _buildOptionTile(
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                _setReplyToMessage(message);
              },
            ),
            // Only show AI assistance for received messages (not my own)
            if (!isMyMessage)
              _buildOptionTile(
                icon: Icons.smart_toy_rounded,
                title: 'Reply using AI assistance',
                color: PulseColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _showAiAssistanceForMessage(message);
                },
              ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'Copy',
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
            _buildOptionTile(
              icon: Icons.bookmark_outline,
              title: message.isBookmarked ? 'Remove Bookmark' : 'Bookmark',
              color: message.isBookmarked ? PulseColors.primary : null,
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark(message);
              },
            ),
            if (message.type == MessageType.image ||
                message.type == MessageType.video ||
                message.type == MessageType.gif)
              _buildOptionTile(
                icon: Icons.download,
                title: 'Save to Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _saveMedia(message);
                },
              ),
            _buildOptionTile(
              icon: Icons.forward,
              title: 'Forward',
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(message);
              },
            ),
            if (isMyMessage) ...[
              _buildOptionTile(
                icon: Icons.edit,
                title: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              _buildOptionTile(
                icon: Icons.delete,
                title: 'Delete',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ] else ...[
              _buildOptionTile(
                icon: Icons.report,
                title: 'Report',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(message);
                },
              ),
            ],
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _addReaction(String messageId, String emoji) {
    // Emit AddReaction event to ChatBloc
    context.read<ChatBloc>().add(AddReaction(
      messageId: messageId,
      conversationId: widget.conversationId,
      emoji: emoji,
    ));
    
    AppLogger.debug('Added reaction $emoji to message $messageId');
  }

  void _setReplyToMessage(MessageModel message) {
    setState(() {
      _replyToMessage = message;
    });
    // Focus on the input field
    _messageInputFocusNode.requestFocus();

    AppLogger.debug('Set reply context for message: ${message.id}');
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _openMedia(MessageModel message) {
    if (message.mediaUrls?.isNotEmpty == true) {
      // Open media viewer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening media viewer...')),
      );
    }
  }

  void _copyMessage(MessageModel message) {
    if (message.content?.isNotEmpty == true) {
      Clipboard.setData(ClipboardData(text: message.content!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    }
  }

  void _saveMedia(MessageModel message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving media to gallery...')),
    );
  }

  void _forwardMessage(MessageModel message) {
    // Show conversation picker bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConversationPickerSheet(
        messageId: message.id,
        currentConversationId: widget.conversationId,
      ),
    );
  }

  void _editMessage(MessageModel message) {
    if (message.type != MessageType.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Can only edit text messages')),
      );
      return;
    }

    final editController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                context.read<ChatBloc>().add(
                  EditMessage(
                    messageId: message.id,
                    newContent: editController.text.trim(),
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(
                DeleteMessage(messageId: message.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportMessage(MessageModel message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report feature will be implemented')),
    );
  }

  void _toggleBookmark(MessageModel message) {
    // Dispatch BookmarkMessage event to BLoC
    context.read<ChatBloc>().add(
      BookmarkMessage(
        messageId: message.id,
        isBookmarked: !message.isBookmarked,
      ),
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isBookmarked
              ? 'Removed from bookmarks'
              : 'Message bookmarked',
        ),
        duration: const Duration(seconds: 2),
        action: message.isBookmarked
            ? null
            : SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Navigate to saved messages screen
                  Navigator.pushNamed(context, '/saved-messages');
                },
              ),
      ),
    );
  }

  void _showAiAssistanceForMessage(MessageModel message) {
    // Show AI assistance modal with specific message context
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => RichAiChatAssistantModal(
          conversationId: widget.conversationId,
          currentUserId: _currentUserId,
          matchUserId: widget.otherUserId,
          specificMessage:
              message.content, // Pass the specific message content for context
          onApplyToChat: (generatedMessage) {
            // Apply the generated message to chat input
            setState(() {
              _messageController.text = generatedMessage;
            });
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Search functionality methods
  void _performSearch(String query) {
    setState(() {
      _currentSearchQuery = query.trim();
      _currentSearchIndex = 0;

      if (_currentSearchQuery.isEmpty) {
        _searchResults.clear();
        return;
      }

      // Use BLoC to search messages via backend API
      context.read<ChatBloc>().add(
        SearchMessages(
          query: _currentSearchQuery,
          conversationId: widget.conversationId,
        ),
      );
    });
  }

  void _previousSearchResult() {
    if (_currentSearchIndex > 0) {
      setState(() {
        _currentSearchIndex--;
        _scrollToSearchResult(_searchResults[_currentSearchIndex]);
      });
    }
  }

  void _nextSearchResult() {
    if (_currentSearchIndex < _searchResults.length - 1) {
      setState(() {
        _currentSearchIndex++;
        _scrollToSearchResult(_searchResults[_currentSearchIndex]);
      });
    }
  }

  void _scrollToSearchResult(MessageModel message) {
    // Find the message in the list and scroll to it
    final chatState = context.read<ChatBloc>().state;
    if (chatState is MessagesLoaded) {
      final messageIndex = chatState.messages.indexOf(message);
      if (messageIndex >= 0) {
        // Calculate scroll position (approximate)
        final double position =
            messageIndex * 80.0; // Approximate message height
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Callback methods for MessageBubble and CallMessageWidget

  // Handle call back action from call message
  Future<void> _handleCallBack(MessageModel message) async {
    await CallBackConfirmationDialog.show(
      context,
      callMessage: message,
      otherUser: widget.otherUserProfile,
      onConfirm: (bool shouldUseVideo) {
        _initiateCallFromMessage(message, isVideo: shouldUseVideo);
      },
    );
  }

  // Show call details bottom sheet
  void _showCallDetails(MessageModel message) {
    CallDetailsBottomSheet.show(
      context,
      callMessage: message,
      otherUser: widget.otherUserProfile,
      onCallBack: () => _handleCallBack(message),
    );
  }

  // Initiate call from call message
  void _initiateCallFromMessage(MessageModel message, {required bool isVideo}) {
    final callMetadata = message.metadata ?? {};
    final isIncoming = callMetadata['isIncoming'] as bool? ?? false;

    // Get the other user's ID (the person we're calling back)
    final otherUserId = isIncoming
        ? message
              .senderId // If it was incoming, call back the sender
        : widget
              .otherUserId; // If it was outgoing, use the conversation participant

    AppLogger.info(
      'Initiating ${isVideo ? 'video' : 'audio'} call to user: $otherUserId from call message',
    );

    // Navigate to appropriate call screen
    if (isVideo) {
      context.push(
        '/video-call',
        extra: {
          'otherUserId': otherUserId,
          'otherUserName': widget.otherUserName,
          'otherUserPhoto': widget.otherUserPhoto,
          'conversationId': widget.conversationId,
          'isOutgoing': true,
        },
      );
    } else {
      context.push(
        '/audio-call',
        extra: {
          'otherUserId': otherUserId,
          'otherUserName': widget.otherUserName,
          'otherUserPhoto': widget.otherUserPhoto,
          'conversationId': widget.conversationId,
          'isOutgoing': true,
          'callType': 'audio',
        },
      );
    }
  }
  
  void _onLongPress(MessageModel message) {
    _showMessageOptions(context, message);
  }

  void _onReaction(MessageModel message, String emoji) {
    // Add reaction to message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added reaction: $emoji')),
    );
  }

  void _onReply(MessageModel message) {
    _setReplyToMessage(message);
  }

  void _onMediaTap(MessageModel message) {
    _openMedia(message);
  }
}
