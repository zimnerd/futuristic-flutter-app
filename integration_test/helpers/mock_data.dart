/// Mock data fixtures for integration testing
class MockData {
  /// Test user profile data
  static const testUser = {
    'id': 'test-user-123',
    'firstName': 'Test',
    'lastName': 'User',
    'email': 'user@pulselink.com',
    'age': 28,
    'bio': 'Test user bio for integration testing',
    'gender': 'MALE',
    'interests': ['Music', 'Travel', 'Movies'],
  };

  /// Another test user for matching
  static const otherUser = {
    'id': 'other-user-456',
    'firstName': 'Jane',
    'lastName': 'Doe',
    'email': 'jane@pulselink.com',
    'age': 26,
    'bio': 'Another test user',
    'gender': 'FEMALE',
    'interests': ['Travel', 'Photography', 'Fitness'],
  };

  /// Test match data
  static const testMatch = {
    'id': 'match-123',
    'userId': 'test-user-123',
    'matchedUserId': 'other-user-456',
    'matchScore': 85,
    'matchedAt': '2025-01-20T10:00:00Z',
    'status': 'ACTIVE',
  };

  /// Test conversation data
  static const testConversation = {
    'id': 'conv-123',
    'participants': ['test-user-123', 'other-user-456'],
    'lastMessage': {
      'id': 'msg-456',
      'senderId': 'other-user-456',
      'content': 'Hey there!',
      'createdAt': '2025-01-22T09:30:00Z',
    },
    'updatedAt': '2025-01-22T09:30:00Z',
    'unreadCount': 2,
  };

  /// Test messages
  static const testMessages = [
    {
      'id': 'msg-001',
      'conversationId': 'conv-123',
      'senderId': 'test-user-123',
      'content': 'Hello!',
      'createdAt': '2025-01-22T09:00:00Z',
    },
    {
      'id': 'msg-002',
      'conversationId': 'conv-123',
      'senderId': 'other-user-456',
      'content': 'Hi! How are you?',
      'createdAt': '2025-01-22T09:15:00Z',
    },
    {
      'id': 'msg-003',
      'conversationId': 'conv-123',
      'senderId': 'test-user-123',
      'content': 'I\'m good, thanks! How about you?',
      'createdAt': '2025-01-22T09:20:00Z',
    },
  ];

  /// Test event data
  static const testEvent = {
    'id': 'event-123',
    'title': 'Coffee Meetup',
    'description': 'Let\'s grab coffee and chat!',
    'date': '2025-02-01T15:00:00Z',
    'location': 'Starbucks Downtown',
    'category': 'SOCIAL',
    'maxAttendees': 10,
    'currentAttendees': 5,
    'hostId': 'test-user-123',
  };

  /// Test emergency contact
  static const testEmergencyContact = {
    'id': 'contact-123',
    'name': 'John Smith',
    'phoneNumber': '+1234567890',
    'relationship': 'Friend',
    'userId': 'test-user-123',
  };

  /// Test subscription plan
  static const testSubscriptionPlan = {
    'id': 'plan-premium',
    'name': 'Premium',
    'price': 9.99,
    'currency': 'USD',
    'interval': 'MONTHLY',
    'features': [
      'Unlimited likes',
      'See who liked you',
      'Advanced filters',
      'No ads',
    ],
  };

  /// Test auth tokens
  static const testAccessToken = 'test-access-token-123456789';
  static const testRefreshToken = 'test-refresh-token-987654321';

  /// Test API responses
  static Map<String, dynamic> successResponse(Map<String, dynamic> data) {
    return {
      'success': true,
      'data': data,
      'message': 'Success',
    };
  }

  static Map<String, dynamic> errorResponse(String message) {
    return {
      'success': false,
      'data': null,
      'message': message,
      'errors': [],
    };
  }
}
