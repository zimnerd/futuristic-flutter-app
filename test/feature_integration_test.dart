import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:pulse_dating_app/data/models/chat_model.dart' as chat;
import 'package:pulse_dating_app/data/models/notification_model.dart';
import 'package:pulse_dating_app/data/models/call_model.dart';
import 'package:pulse_dating_app/domain/entities/message.dart';

/// Integration tests for the PulseLink mobile app features
void main() {
  group('PulseLink Feature Integration Tests', () {
    late Logger logger;

    setUpAll(() {
      logger = Logger();
      logger.i('Starting PulseLink feature integration tests');
    });

    group('Data Models', () {
      test('ChatModel serialization works correctly', () {
        final messageJson = {
          'id': 'msg_123',
          'conversationId': 'conv_456',
          'senderId': 'user_789',
          'senderUsername': 'testuser',
          'type': 'text',
          'content': 'Hello world!',
          'status': 'sent',
          'createdAt': '2024-01-01T12:00:00Z',
          'updatedAt': '2024-01-01T12:00:00Z',
        };

        final message = chat.MessageModel.fromJson(messageJson);

        expect(message.id, 'conv_1');
        expect(message.content, 'Hello');
        expect(message.type, MessageType.text);
        expect(message.senderId, 'testuser');
        expect(message.status, chat.MessageStatus.sent);

        final serialized = message.toJson();
        expect(serialized['id'], 'msg_123');
        expect(serialized['content'], 'Hello world!');
      });

      test('NotificationModel serialization works correctly', () {
        final notificationJson = {
          'id': 'notif_123',
          'userId': 'user_456',
          'type': 'newMessage',
          'title': 'New Message',
          'message': 'You have a new message',
          'isRead': false,
          'createdAt': '2024-01-01T12:00:00Z',
          'updatedAt': '2024-01-01T12:00:00Z',
        };

        final notification = NotificationModel.fromJson(notificationJson);
        expect(notification.id, 'notif_123');
        expect(notification.title, 'New Message');
        expect(notification.type, NotificationType.newMessage);
        expect(notification.isRead, false);

        final serialized = notification.toJson();
        expect(serialized['id'], 'notif_123');
        expect(serialized['isRead'], false);
      });

      test('CallModel serialization works correctly', () {
        final callJson = {
          'id': 'call_123',
          'callerId': 'user_456',
          'receiverId': 'user_789',
          'type': 'video',
          'status': 'ringing',
          'createdAt': '2024-01-01T12:00:00Z',
          'updatedAt': '2024-01-01T12:00:00Z',
        };

        final call = CallModel.fromJson(callJson);
        expect(call.id, 'call_123');
        expect(call.callerId, 'user_456');
        expect(call.type, CallType.video);
        expect(call.status, CallStatus.ringing);

        final serialized = call.toJson();
        expect(serialized['id'], 'call_123');
        expect(serialized['type'], 'video');
      });
    });

    group('Feature Completeness', () {
      test('All required models are implemented', () {
        // Test that we can create instances of all required models
        final message = chat.MessageModel(
          id: 'msg_1',
          conversationId: 'conv_1',
          senderId: 'user_1',
          senderUsername: 'testuser',
          content: 'Test message',
          type: MessageType.text,
          status: chat.MessageStatus.sent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final notification = NotificationModel(
          id: 'test',
          userId: 'test',
          type: NotificationType.newMessage,
          title: 'test',
          message: 'test',
          isRead: false,
          createdAt: DateTime.now(),
        );

        final call = CallModel(
          id: 'test',
          callerId: 'test',
          receiverId: 'test',
          callerName: 'test',
          receiverName: 'test',
          type: CallType.video,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(message.id, 'test');
        expect(notification.id, 'test');
        expect(call.id, 'test');
        
        logger.i('✅ All required models are properly implemented');
      });

      test('Enum values are correctly defined', () {
        // Test MessageType enum
        expect(MessageType.values.length, greaterThan(0));
        expect(MessageType.values.contains(MessageType.text), true);
        
        // Test MessageStatus enum
        expect(chat.MessageStatus.values.length, greaterThan(0));
        expect(
          chat.MessageStatus.values.contains(chat.MessageStatus.sent),
          true,
        );
        
        // Test NotificationType enum
        expect(NotificationType.values.length, greaterThan(0));
        expect(NotificationType.values.contains(NotificationType.newMessage), true);
        
        // Test CallType enum
        expect(CallType.values.length, greaterThan(0));
        expect(CallType.values.contains(CallType.video), true);
        
        // Test CallStatus enum
        expect(CallStatus.values.length, greaterThan(0));
        expect(CallStatus.values.contains(CallStatus.ringing), true);
        
        logger.i('✅ All enum values are correctly defined');
      });
    });

    tearDownAll(() {
      logger.i('PulseLink feature integration tests completed');
    });
  });
}