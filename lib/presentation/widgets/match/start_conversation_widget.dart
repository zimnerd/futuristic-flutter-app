import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/messaging/messaging_bloc.dart';
import '../../../data/models/match_model.dart';

/// Widget for starting a conversation with a match
class StartConversationWidget extends StatelessWidget {
  const StartConversationWidget({
    super.key,
    required this.match,
    required this.onConversationStarted,
  });

  final MatchModel match;
  final Function(String conversationId) onConversationStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Match info header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Match!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    Text(
                      'Start your conversation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Compatibility score
          if (match.compatibilityScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(match.compatibilityScore * 100).round()}% Compatible',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Conversation starters
          Text(
            'Break the ice with:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          
          const SizedBox(height: 12),
          
          // Quick message options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getConversationStarters().map((starter) {
              return _QuickMessageChip(
                message: starter,
                onTap: () => _sendMessage(context, starter),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Custom message option
          ElevatedButton.icon(
            onPressed: () => _startCustomConversation(context),
            icon: const Icon(Icons.edit),
            label: const Text('Write your own message'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getConversationStarters() {
    return [
      "Hey! 👋",
      "Great match! 😊",
      "How's your day going?",
      "Love your profile!",
      "What's your favorite weekend activity?",
      "Coffee or tea? ☕",
    ];
  }

  void _sendMessage(BuildContext context, String message) {
    // Create conversation and send first message
    context.read<MessagingBloc>().add(
      StartConversation(
        matchId: match.id,
        initialMessage: message,
      ),
    );
  }

  void _startCustomConversation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomMessageSheet(
        match: match,
        onSend: (message) => _sendMessage(context, message),
      ),
    );
  }
}

class _QuickMessageChip extends StatelessWidget {
  const _QuickMessageChip({
    required this.message,
    required this.onTap,
  });

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CustomMessageSheet extends StatefulWidget {
  const _CustomMessageSheet({
    required this.match,
    required this.onSend,
  });

  final MatchModel match;
  final Function(String message) onSend;

  @override
  State<_CustomMessageSheet> createState() => _CustomMessageSheetState();
}

class _CustomMessageSheetState extends State<_CustomMessageSheet> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Write your message',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        widget.onSend(_controller.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
