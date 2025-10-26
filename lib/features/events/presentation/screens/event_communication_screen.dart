import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import '../../../../presentation/theme/pulse_colors.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/entities/event_message.dart';
import '../../../../domain/entities/call.dart';
import '../../../../data/services/call_service.dart';
import '../bloc/event_chat_bloc.dart';
import '../../../../presentation/widgets/common/pulse_toast.dart';

class EventCommunicationScreen extends StatefulWidget {
  final Event event;

  const EventCommunicationScreen({super.key, required this.event});

  @override
  State<EventCommunicationScreen> createState() =>
      _EventCommunicationScreenState();
}

class _EventCommunicationScreenState extends State<EventCommunicationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  late EventChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatBloc = EventChatBloc();

    // Load messages when the screen initializes
    _chatBloc.add(LoadEventMessages(widget.event.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _chatBloc,
      child: Scaffold(
        backgroundColor: PulseColors.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.event.attendees.length} participants',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: PulseColors.secondary,
            labelStyle: const TextStyle(color: Colors.white),
            unselectedLabelStyle: const TextStyle(color: Colors.white70),
            tabs: const [
              Tab(icon: Icon(Icons.chat), text: 'Chat'),
              Tab(icon: Icon(Icons.call), text: 'Voice'),
              Tab(icon: Icon(Icons.videocam), text: 'Video'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildChatTab(), _buildVoiceTab(), _buildVideoTab()],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<EventChatBloc, EventChatState>(
              builder: (context, state) {
                if (state is EventChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: PulseColors.primary,
                    ),
                  );
                } else if (state is EventChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: context.outlineColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.onSurfaceVariantColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<EventChatBloc>().add(
                              LoadEventMessages(widget.event.id),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is EventChatLoaded ||
                    state is EventChatSending) {
                  final messages = state is EventChatLoaded
                      ? state.messages
                      : (state as EventChatSending).messages;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: context.outlineColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: context.onSurfaceVariantColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to say something!',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.onSurfaceVariantColor.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _buildChatMessage(messages[index]),
                  );
                } else {
                  return Center(
                    child: Text(
                      'Start a conversation!',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.onSurfaceVariantColor,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          BlocBuilder<EventChatBloc, EventChatState>(
            builder: (context, state) {
              final isSending = state is EventChatSending;
              return _buildChatInput(isSending);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(EventMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isMe ? PulseColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMe)
              Text(
                message.userName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.onSurfaceVariantColor,
                ),
              ),
            if (!message.isMe) const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: message.isMe
                    ? Colors.white70
                    : context.onSurfaceVariantColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput([bool isSending = false]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: context.outlineColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: isSending ? 'Sending...' : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: context.outlineColor.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (text) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: isSending
                  ? context.outlineColor.withValues(alpha: 0.5)
                  : PulseColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white),
              onPressed: isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<EventChatBloc>().add(
        SendEventMessage(eventId: widget.event.id, content: content),
      );
      _messageController.clear();
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildVoiceTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: PulseColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Voice Chat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with other event participants',
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceVariantColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final callService = CallService.instance;
                  await callService.initialize();

                  // For event communication, we need participant IDs
                  // Get them from event attendees
                  final participantIds = widget.event.attendees
                      .map((attendee) => attendee.id)
                      .where(
                        (id) => id != 'current_user_id',
                      ) // Exclude current user
                      .toList();

                  if (participantIds.isEmpty) {
                    if (mounted) {
                      PulseToast.warning(
                        context,
                        message: 'No participants available for call',
                      );
                    }
                    return;
                  }

                  // For now, start voice call with first participant
                  final callId = await callService.initiateCall(
                    recipientId: participantIds.first,
                    type: CallType.audio,
                  );

                  if (mounted) {
                    PulseToast.success(
                      context,
                      message: 'Voice call started: $callId',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    PulseToast.error(
                      context,
                      message: 'Failed to start voice call: $e',
                    );
                  }
                }
              },
              icon: Icon(Icons.call),
              label: Text('Start Voice Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: PulseColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.videocam, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Video Chat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Face-to-face conversation with participants',
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceVariantColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final callService = CallService.instance;
                  await callService.initialize();

                  // For event communication, we need participant IDs
                  // Get them from event attendees
                  final participantIds = widget.event.attendees
                      .map((attendee) => attendee.id)
                      .where(
                        (id) => id != 'current_user_id',
                      ) // Exclude current user
                      .toList();

                  if (participantIds.isEmpty) {
                    if (mounted) {
                      PulseToast.info(
                        context,
                        message: 'No participants available for call',
                      );
                    }
                    return;
                  }

                  // For now, start video call with first participant
                  final callId = await callService.initiateCall(
                    recipientId: participantIds.first,
                    type: CallType.video,
                  );

                  if (mounted) {
                    PulseToast.success(
                      context,
                      message: 'Video call started: $callId',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    PulseToast.error(
                      context,
                      message: 'Failed to start video call: $e',
                    );
                  }
                }
              },
              icon: Icon(Icons.videocam),
              label: Text('Start Video Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
