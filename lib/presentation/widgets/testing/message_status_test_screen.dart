import 'package:flutter/material.dart';
import '../../../data/models/chat_model.dart';
import '../messaging/message_status_indicator.dart';

/// Test screen for visually verifying MessageStatusIndicator states
/// 
/// Run this screen to see all 5 status states side-by-side for visual QA
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => MessageStatusTestScreen()),
/// );
/// ```
class MessageStatusTestScreen extends StatelessWidget {
  const MessageStatusTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Status Indicator Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Status Indicator Visual Test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify all 5 status states render correctly with proper colors and icons',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Sending State
          _buildStatusCard(
            context,
            status: MessageStatus.sending,
            title: 'Sending',
            description: 'Message queued/sending to server',
            expectedIcon: 'schedule (clock)',
            expectedColor: 'Grey',
          ),

          // Sent State
          _buildStatusCard(
            context,
            status: MessageStatus.sent,
            title: 'Sent',
            description: 'Server received the message',
            expectedIcon: 'check (single)',
            expectedColor: 'Grey',
          ),

          // Delivered State
          _buildStatusCard(
            context,
            status: MessageStatus.delivered,
            title: 'Delivered',
            description: 'Delivered to recipient device',
            expectedIcon: 'done_all (double check)',
            expectedColor: 'Grey',
          ),

          // Read State
          _buildStatusCard(
            context,
            status: MessageStatus.read,
            title: 'Read',
            description: 'Read by recipient',
            expectedIcon: 'done_all (double check)',
            expectedColor: 'Blue',
          ),

          // Failed State
          _buildStatusCard(
            context,
            status: MessageStatus.failed,
            title: 'Failed',
            description: 'Send failed - retry available',
            expectedIcon: 'error_outline + refresh',
            expectedColor: 'Red',
            hasRetry: true,
          ),

          const SizedBox(height: 32),

          // Size variations
          const Text(
            'Size Variations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Small (14px - media-only bubbles)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MessageStatusIndicator(
                        status: MessageStatus.read,
                        size: 14,
                        color: Colors.white,
                        readColor: Colors.blue.shade300,
                      ),
                      const SizedBox(width: 8),
                      const Text('14px', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Default (16px - text bubbles)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MessageStatusIndicator(
                        status: MessageStatus.read,
                        size: 16,
                        color: Colors.grey.shade600,
                        readColor: Colors.blue.shade300,
                      ),
                      const SizedBox(width: 8),
                      const Text('16px (default)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Large (20px - custom use)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MessageStatusIndicator(
                        status: MessageStatus.read,
                        size: 20,
                        color: Colors.grey.shade600,
                        readColor: Colors.blue.shade300,
                      ),
                      const SizedBox(width: 8),
                      const Text('20px', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Retry button test
          const Text(
            'Interactive Test',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tap the retry button to test interaction:'),
                  const SizedBox(height: 16),
                  MessageStatusIndicator(
                    status: MessageStatus.failed,
                    size: 20,
                    errorColor: Colors.red,
                    onRetry: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Retry callback triggered!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required MessageStatus status,
    required String title,
    required String description,
    required String expectedIcon,
    required String expectedColor,
    bool hasRetry = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: MessageStatusIndicator(
                  status: status,
                  size: 24,
                  color: Colors.grey.shade600,
                  readColor: Colors.blue.shade300,
                  errorColor: Colors.red,
                  onRetry: hasRetry
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Retry triggered for $title'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Status details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Icon: $expectedIcon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Color: $expectedColor',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark or status
            Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade300,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
