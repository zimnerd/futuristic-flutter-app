import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import '../widgets/chat/ai_message_input.dart';
import '../theme/pulse_colors.dart';
import '../widgets/common/pulse_toast.dart';

/// Demo screen showcasing all AI features in the mobile app
class AiFeaturesDemo extends StatefulWidget {
  const AiFeaturesDemo({super.key});

  @override
  State<AiFeaturesDemo> createState() => _AiFeaturesDemoState();
}

class _AiFeaturesDemoState extends State<AiFeaturesDemo>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<DemoMessage> _messages = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final String _lastReceivedMessage = "Hey! How are you doing today? 😊";

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _initializeDemoMessages();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeDemoMessages() {
    _messages.addAll([
      DemoMessage(
        text: "Welcome to PulseLink's AI Features! 🚀",
        isAi: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      DemoMessage(
        text:
            "I can help you with profile building, icebreakers, and smart replies!",
        isAi: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      DemoMessage(
        text: _lastReceivedMessage,
        isAi: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ]);
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        DemoMessage(text: message, isAi: false, timestamp: DateTime.now()),
      );
    });

    _messageController.clear();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(
            DemoMessage(
              text: _generateAiResponse(message),
              isAi: true,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  String _generateAiResponse(String userMessage) {
    // Simple demo responses
    final responses = [
      "That's really interesting! Tell me more about that.",
      "I love your perspective on this! 💭",
      "Thanks for sharing! What's your favorite part about it?",
      "That sounds amazing! I'd love to experience that too.",
      "You have such great taste! What else do you enjoy?",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildAiFeaturesOverview(),
              Expanded(child: _buildMessagesList()),
              _buildAiMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PulseColors.primary, PulseColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: context.onSurfaceColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Features Demo',
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Experience the future of dating',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAiFeaturesOverview() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PulseColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: PulseColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available AI Features',
                      style: TextStyle(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureChip(
                        '🤖 AI Companion',
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFeatureChip('💬 Smart Replies', Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureChip('⚡ Icebreakers', Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFeatureChip('✨ Profile Help', Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(DemoMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isAi) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PulseColors.primary, PulseColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: context.onSurfaceColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isAi
                    ? Colors.white.withValues(alpha: 0.1)
                    : PulseColors.primary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: message.isAi
                    ? Border.all(
                        color: PulseColors.primary.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!message.isAi) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.onSurfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: PulseColors.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiMessageInput() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.3)),
      ),
      child: AiMessageInput(
        controller: _messageController,
        onSend: _sendMessage,
        chatId: 'demo_chat_ai_features',
        lastReceivedMessage: _lastReceivedMessage,
        onTyping: () {
          // Handle typing indicator
        },
        onCamera: () {
          PulseToast.info(context, message: 'Camera feature coming soon!');
        },
        onGallery: () {
          PulseToast.info(context, message: 'Gallery feature coming soon!');
        },
        onVoice: () {
          PulseToast.info(
            context,
            message: 'Voice message feature coming soon!',
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class DemoMessage {
  final String text;
  final bool isAi;
  final DateTime timestamp;

  DemoMessage({
    required this.text,
    required this.isAi,
    required this.timestamp,
  });
}
