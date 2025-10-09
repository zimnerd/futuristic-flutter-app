// Core constants for the Pulse Dating App
// Contains API endpoints, app configuration, and global settings
import 'dart:io';

class AppConstants {
  // App Information
  static const String appName = 'Pulse Dating';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Modern dating app with offline-first architecture';

  // API Configuration
  static String get baseUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000';
  }
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // WebSocket Configuration
  static String get websocketUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'ws://$host:3000';
  }

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String appSettingsKey = 'app_settings';
  static const String offlineQueueKey = 'offline_queue';

  // Cache Configuration
  static const Duration cacheValidityDuration = Duration(hours: 24);
  static const Duration shortCacheDuration = Duration(minutes: 15);
  static const int maxCacheSize = 100; // MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Media Configuration
  static const int maxImageFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];

  // Location Configuration
  static const double defaultLocationRadius = 50.0; // km
  static const double maxLocationRadius = 500.0; // km

  // External API Keys
  static const String googleMapsApiKey =
      'AIzaSyD2iddVKdqoPrCPs5O8LdWR1ltaTKy2ZJo';

  // Dating App Specific
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int maxPhotos = 6;
  static const int maxBioLength = 500;
  static const int maxInterests = 10;

  // Premium Features
  static const int freeSwipesPerDay = 100;
  static const int premiumSwipesPerDay = -1; // Unlimited
  static const int superLikesPerDay = 1;
  static const int premiumSuperLikesPerDay = 5;

  // Call Configuration
  static const int maxCallDuration = 60 * 60; // 1 hour in seconds
  static const List<String> stunServers = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
  ];

  // Chat Configuration
  static const String aiCompanionId = 'ai_companion_system';
  static const String systemUserId = 'system_user';
  static const int maxMessageLength = 1000;
  static const int messageLoadBatchSize = 50;
}

/// API endpoint constants
class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User Management
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadPhoto = '/users/photos';
  static const String deletePhoto = '/users/photos';
  static const String updateLocation =
      '/users/me/location'; // Fixed: was /users/location, now /me/location
  static const String preferences = '/users/preferences';

  // Discovery & Matching
  static const String discover = '/discover';
  static const String swipe = '/swipe';
  static const String matches = '/matches';
  static const String match = '/matches';
  static const String unmatch = '/matches';

  // Messaging
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String sendMessage = '/messages';
  static const String markAsRead = '/messages/read';

  // Calls
  static const String initiateCall = '/calls/initiate';
  static const String answerCall = '/calls/answer';
  static const String endCall = '/calls/end';
  static const String callHistory = '/calls/history';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/read';
  static const String updatePushToken = '/notifications/push-token';

  // Events
  static const String events = '/events';
  static const String joinEvent = '/events/join';
  static const String leaveEvent = '/events/leave';

  // Premium
  static const String subscriptions = '/subscriptions';
  static const String purchasePremium = '/subscriptions/purchase';

  // Safety & Reporting
  static const String reportUser = '/safety/report';
  static const String blockUser = '/safety/block';
  static const String unblockUser = '/safety/unblock';
}

/// WebSocket event constants
class SocketEvents {
  // Connection
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String error = 'error';

  // Authentication
  static const String authenticate = 'authenticate';
  static const String authenticated = 'authenticated';

  // Messaging
  static const String joinConversation = 'join_conversation';
  static const String leaveConversation = 'leave_conversation';
  static const String newMessage = 'new_message';
  static const String messageDelivered = 'message_delivered';
  static const String messageRead = 'message_read';
  static const String typingStart = 'typing_start';
  static const String typingStop = 'typing_stop';

  // Calls
  static const String incomingCall = 'incoming_call';
  static const String callAnswer = 'call_answer';
  static const String callEnd = 'call_end';
  static const String callSignaling = 'call_signaling';

  // Matches
  static const String newMatch = 'new_match';
  static const String matchExpired = 'match_expired';

  // Notifications
  static const String newNotification = 'new_notification';

  // Presence
  static const String userOnline = 'user_online';
  static const String userOffline = 'user_offline';
  static const String userTyping = 'user_typing';
}

/// Error message constants
class ErrorMessages {
  static const String networkError =
      'Network connection error. Please check your internet connection.';
  static const String serverError =
      'Server error occurred. Please try again later.';
  static const String unauthorizedError =
      'Session expired. Please log in again.';
  static const String validationError =
      'Please check your input and try again.';
  static const String notFoundError = 'Requested resource not found.';
  static const String permissionDeniedError =
      'Permission denied. Please check your settings.';
  static const String locationDisabledError =
      'Location services are disabled. Please enable them in settings.';
  static const String cameraPermissionError =
      'Camera permission is required to take photos.';
  static const String storagePermissionError =
      'Storage permission is required to save photos.';
  static const String microphonePermissionError =
      'Microphone permission is required for calls.';
  static const String fileUploadError =
      'Failed to upload file. Please try again.';
  static const String fileSizeError =
      'File size is too large. Please choose a smaller file.';
  static const String unsupportedFileError = 'File format is not supported.';
  static const String ageRestrictionError =
      'You must be at least 18 years old to use this app.';
  static const String maxPhotosError = 'You can upload a maximum of 6 photos.';
  static const String profileIncompleteError =
      'Please complete your profile before continuing.';
}

/// Success message constants
class SuccessMessages {
  static const String profileUpdated = 'Profile updated successfully';
  static const String photoUploaded = 'Photo uploaded successfully';
  static const String messageDeleted = 'Message deleted successfully';
  static const String userBlocked = 'User blocked successfully';
  static const String userUnblocked = 'User unblocked successfully';
  static const String reportSubmitted = 'Report submitted successfully';
  static const String passwordChanged = 'Password changed successfully';
  static const String emailVerified = 'Email verified successfully';
  static const String locationUpdated = 'Location updated successfully';
  static const String premiumActivated = 'Premium subscription activated';
  static const String notificationSettingsUpdated =
      'Notification settings updated';
}
