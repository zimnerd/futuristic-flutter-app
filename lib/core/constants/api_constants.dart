/// API constants for backend communication
class ApiConstants {
  // Base URLs - Always use production API
  static const String baseUrl = 'https://apilink.pulsetek.co.za/api/v1';
  static const String websocketUrl = 'wss://apilink.pulsetek.co.za';
  
  // API Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String matching = '/matching';
  static const String messaging = '/messaging';
  static const String conversations = '/conversations';
  static const String media = '/media';
  static const String notifications = '/notifications';
  static const String premium = '/premium';
  static const String socialGaming = '/social-gaming';
  static const String analytics = '/analytics';
  static const String payment = '/payment';
  
  // Analytics endpoints
  static const String analyticsEvents = '$analytics/events';
  static const String analyticsInsights = '$analytics/insights';
  static const String analyticsUserProperties = '$analytics/user-properties';

  // Payment endpoints
  static const String paymentMethods = '$payment/methods';
  static const String subscriptions = '$payment/subscriptions';
  static const String refunds = '$payment/refunds';
  
  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String sendOtp = '$auth/send-otp';
  static const String verifyOtp = '$auth/verify-otp';
  static const String refreshToken = '$auth/refresh';
  static const String logout = '$auth/logout';
  
  // User endpoints - Aligned with backend structure
  static const String profile = '$users/me';
  static const String getCurrentProfile = '$users/me';
  static const String updateProfile = '$users/me';
  static const String extendedProfile = '$users/me/profile';
  static const String uploadPhoto = '$media/upload';
  static const String deletePhoto = '$media/files';
  
  // Matching endpoints
  static const String discover = '$matching/suggestions';
  static const String matches = '$matching/matches';
  static const String likeUser = '$matching/like';
  static const String passUser = '$matching/pass';
  static const String reportProfile = '/reports';
  static const String blockProfile = '$users/block';
  
  // Messaging endpoints - Aligned with backend structure
  static const String getConversations = '$messaging/conversations';
  static const String getMessages =
      '$messaging/conversations'; // Use with /:conversationId/messages
  static const String sendMessage =
      '$messaging/conversations'; // Use with /:conversationId/messages
  static const String markAsRead =
      '$messaging/conversations'; // Use with /:conversationId/messages
  static const String deleteMessage =
      '$messaging/conversations'; // Use with /:conversationId/messages
  
  // Media endpoints - Unified upload structure
  static const String uploadImage = '$media/upload';
  static const String uploadVideo = '$media/upload';
  static const String uploadAudio = '$media/upload';
  static const String uploadFile = '$media/upload';
  static const String deleteFile = '$media/files';
  
  // WebSocket events
  static const String wsNewMessage = 'new_message';
  static const String wsMessageRead = 'message_read';
  static const String wsUserOnline = 'user_online';
  static const String wsUserOffline = 'user_offline';
  static const String wsNewMatch = 'new_match';
  static const String wsCallOffer = 'call_offer';
  static const String wsCallAnswer = 'call_answer';
  static const String wsCallEnd = 'call_end';
  
  // Preferences endpoints
  static const String filterPreferences = '$users/preferences/filters';
  static const String interests = '$users/interests';
  static const String educationLevels = '$users/education-levels';
  
  // Request timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File upload limits
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int maxAudioSize = 20 * 1024 * 1024; // 20MB
}
