import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_dating_app/presentation/widgets/chat/message_input.dart';
import 'package:pulse_dating_app/presentation/widgets/chat/typing_indicator.dart';
import 'package:pulse_dating_app/presentation/widgets/call/call_controls.dart';

void main() {
  group('Chat Widgets Tests', () {
    testWidgets('MessageInput shows send button when text is entered', (
      tester,
    ) async {
      // Arrange
      final controller = TextEditingController();
      bool sendCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInput(
              controller: controller,
              onSend: () => sendCalled = true,
            ),
          ),
        ),
      );

      // Type text
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert
      expect(sendCalled, isTrue);
    });

    testWidgets('TypingIndicator displays animation', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(userName: 'John')),
        ),
      );

      // Assert
      expect(find.text('John is typing'), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });
  });

  group('Call Widgets Tests', () {
    testWidgets('CallControls displays all control buttons', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallControls(
              isVideoEnabled: true,
              isAudioEnabled: true,
              isSpeakerEnabled: false,
              onToggleVideo: () {},
              onToggleAudio: () {},
              onToggleSpeaker: () {},
              onEndCall: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.volume_down), findsOneWidget);
      expect(find.byIcon(Icons.call_end), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);
    });
  });
}
