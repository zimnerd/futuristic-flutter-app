import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/voice_message.dart';
import '../../blocs/voice_message/voice_message_bloc.dart';
import '../../blocs/voice_message/voice_message_event.dart';
import '../../blocs/voice_message/voice_message_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/voice_messages/voice_recorder_widget.dart';
import '../../widgets/voice_messages/voice_message_list_widget.dart';
import '../../widgets/voice_messages/voice_message_player_widget.dart';

/// Main screen for voice messages functionality
class VoiceMessagesScreen extends StatefulWidget {
  const VoiceMessagesScreen({super.key});

  @override
  State<VoiceMessagesScreen> createState() => _VoiceMessagesScreenState();
}

class _VoiceMessagesScreenState extends State<VoiceMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VoiceMessage? _selectedMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<VoiceMessageBloc>().add(
      LoadVoiceMessages(chatId: 'current_chat_id'),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Record'),
            Tab(icon: Icon(Icons.inbox), text: 'Received'),
            Tab(icon: Icon(Icons.send), text: 'Sent'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Voice Message Player (shown when a message is selected)
          if (_selectedMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: VoiceMessagePlayerWidget(
                message: _selectedMessage!,
                onClose: () => setState(() => _selectedMessage = null),
              ),
            ),
          // Main Content
          Expanded(
            child: BlocBuilder<VoiceMessageBloc, VoiceMessageState>(
              builder: (context, state) {
                if (state.status == VoiceMessageStatus.error) {
                  return PulseErrorWidget(
                    message: state.errorMessage ?? 'An error occurred',
                    onRetry: () {
                      context.read<VoiceMessageBloc>().add(
                        LoadVoiceMessages(chatId: 'current_chat_id'),
                      );
                    },
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecordTab(state),
                    _buildReceivedTab(state),
                    _buildSentTab(state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTab(VoiceMessageState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          VoiceRecorderWidget(
            onMessageRecorded: (VoiceMessage message) {
              context.read<VoiceMessageBloc>().add(
                SendVoiceMessage(
                  chatId: 'current_chat_id',
                  audioPath: message.audioUrl,
                  durationMs: message.duration * 1000,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (state.status == VoiceMessageStatus.recording)
            const Text(
              'Recording...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          if (state.status == VoiceMessageStatus.sending)
            const Column(
              children: [
                PulseLoadingWidget(),
                SizedBox(height: 8),
                Text('Sending voice message...'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(VoiceMessageState state) {
    if (state.status == VoiceMessageStatus.loading) {
      return const Center(child: PulseLoadingWidget());
    }

    return VoiceMessageListWidget(
      messages: state.messages
          .where((msg) => msg.senderId != 'current_user_id')
          .toList(),
      onMessageTap: (message) {
        setState(() {
          _selectedMessage = message;
        });
      },
      onMessageDelete: (message) {
        context.read<VoiceMessageBloc>().add(
          DeleteVoiceMessage(messageId: message.id),
        );
      },
      emptyStateTitle: 'No Received Messages',
      emptyStateSubtitle: 'Voice messages you receive will appear here',
    );
  }

  Widget _buildSentTab(VoiceMessageState state) {
    if (state.status == VoiceMessageStatus.loading) {
      return const Center(child: PulseLoadingWidget());
    }

    return VoiceMessageListWidget(
      messages: state.messages
          .where((msg) => msg.senderId == 'current_user_id')
          .toList(),
      onMessageTap: (message) {
        setState(() {
          _selectedMessage = message;
        });
      },
      onMessageDelete: (message) {
        context.read<VoiceMessageBloc>().add(
          DeleteVoiceMessage(messageId: message.id),
        );
      },
      emptyStateTitle: 'No Sent Messages',
      emptyStateSubtitle: 'Voice messages you send will appear here',
    );
  }
}
