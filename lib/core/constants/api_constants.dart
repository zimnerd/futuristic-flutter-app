/// API constants for backend communication
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://localhost:3001/api';
  static const String websocketUrl = 'ws://localhost:3001';
  
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
  
  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String sendOtp = '$auth/send-otp';
  static const String verifyOtp = '$auth/verify-otp';
  static const String refreshToken = '$auth/refresh';
  static const String logout = '$auth/logout';
  
  // User endpoints
  static const String profile = '$users/profile';
  static const String getCurrentProfile = '$users/profile';
  static const String updateProfile = '$users/profile';
  static const String uploadPhoto = '$users/photos';
  static const String deletePhoto = '$users/photos';
  
  // Matching endpoints
  static const String discover = '$matching/discover';
  static const String swipe = '$matching/swipe';
  static const String matches = '$matching/matches';
  static const String reportProfile = '$matching/report';
  static const String blockProfile = '$matching/block';
  
  // Messaging endpoints
  static const String getConversations = '$messaging/conversations';
  static const String getMessages = '$messaging/conversations';
  static const String sendMessage = '$messaging/conversations';
  static const String markAsRead = '$messaging/conversations';
  static const String deleteMessage = '$messaging/messages';
  
  // Media endpoints
  static const String uploadImage = '$media/images';
  static const String uploadVideo = '$media/videos';
  static const String uploadAudio = '$media/audio';
  static const String uploadFile = '$media/files';
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
