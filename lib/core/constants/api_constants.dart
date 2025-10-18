import '../config/app_config.dart';

/// API constants for backend communication - aligned with NestJS controllers
class ApiConstants {
  // Base URLs - Uses AppConfig for environment-aware URLs
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get websocketUrl => AppConfig.websocketUrl;
  
  // ================================
  // CORE MODULE ENDPOINTS
  // ================================

  // Auth endpoints (auth.controller.ts)
  static const String auth = '/auth';
  static const String authRegister = '$auth/register';
  static const String authLogin = '$auth/login';
  static const String authAdminLogin = '$auth/admin/login';
  static const String authRefresh = '$auth/refresh';
  static const String authLogout = '$auth/logout';
  static const String authForgotPassword = '$auth/forgot-password';
  static const String authResetPassword = '$auth/reset-password';
  static const String authSendOTP = '$auth/send-otp';
  static const String authVerifyOTP = '$auth/verify-otp';
  static const String authResendOTP = '$auth/resend-otp';
  static const String authChangePassword = '$auth/change-password';

  // Users endpoints (users.controller.ts)
  static const String users = '/users';
  static const String usersMe = '$users/me';
  static const String usersProfile = '$users/profile';
  static const String usersSearch = '$users/search';
  static const String usersBlock = '$users/block';
  static const String usersUnblock = '$users/unblock';
  static const String usersReport = '$users/report';
  static const String usersLocation =
      '$users/me/location'; // Fixed: was /users/location, now /me/location
  static const String usersPreferences = '$users/preferences';
  static const String usersPrivacy =
      '$users/me/privacy'; // Fixed: now /me/privacy
  static const String usersDiscovery = '$users/discovery';
  static const String usersVerification = '$users/verification';

  // Matching endpoints (matching.controller.ts)
  static const String matching = '/matching';
  static const String matchingLike = '$matching/like';
  static const String matchingPass = '$matching/pass';
  static const String matchingSuperLike = '$matching/super-like';
  static const String matchingUndo = '$matching/undo';
  static const String matchingSuggestions = '$matching/suggestions';
  static const String matchingMatches = '$matching/matches';
  static const String matchingWhoLikedMe = '$matching/who-liked-me';
  static const String matchingPreferences = '$matching/preferences';
  static const String matchingFeedback = '$matching/feedback';

  // Messaging endpoints (messaging.controller.ts)
  static const String messaging = '/messaging';
  static const String messagingConversations = '$messaging/conversations';
  static const String messagingMessages = '$messaging/messages';
  static const String messagingSend = '$messaging/send';
  static const String messagingMarkRead = '$messaging/mark-read';
  static const String messagingDelete = '$messaging/delete';

  // Media endpoints (media.controller.ts)
  static const String media = '/media';
  static const String mediaUpload = '$media/upload';
  static const String mediaFiles = '$media/files';
  static const String mediaDelete = '$media/delete';

  // Photo management endpoints
  static const String usersPhotos = '$users/me/photos';
  static const String usersPhotosReorder = '$users/me/photos/reorder';
  static const String usersPhotosSyncPhotos =
      '$users/me/photos'; // PUT for sync

  // Statistics endpoints (statistics.controller.ts)
  static const String statistics = '/statistics';
  static const String statisticsUser = '$statistics/me';
  static const String statisticsHeatMap = '$statistics/heatmap';
  static const String statisticsLocationCoverage =
      '$statistics/location-coverage';

  // ================================
  // PREMIUM & MONETIZATION
  // ================================

  // Premium endpoints (premium.controller.ts)
  static const String premium = '/premium';
  static const String premiumSubscribe = '$premium/subscribe';
  static const String premiumSubscription = '$premium/subscription';
  static const String premiumStats = '$premium/stats';
  static const String premiumBoost = '$premium/boost';
  static const String premiumBoostStatus = '$premium/boost/status';
  static const String premiumCancel = '$premium/cancel';
  static const String premiumPause = '$premium/pause';
  static const String premiumResume = '$premium/resume';
  static const String premiumAdminSubscriptions =
      '$premium/admin/subscriptions';
  static const String premiumAdminAnalytics = '$premium/admin/analytics';

  // Payment endpoints (payment.controller.ts)
  static const String payment = '/payment';
  static const String paymentMethods = '$payment/methods';
  static const String paymentSubscriptions = '$payment/subscriptions';
  static const String paymentRefunds = '$payment/refunds';
  static const String paymentCreateIntent = '$payment/create-intent';
  static const String paymentWebhook = '$payment/webhook';
  static const String paymentHistory = '$payment/history';

  // Virtual Gifts endpoints (virtual-gifts.controller.ts)
  static const String virtualGifts = '/virtual-gifts';
  static const String virtualGiftsCatalog = '$virtualGifts/catalog';
  static const String virtualGiftsSend = '$virtualGifts/send';
  static const String virtualGiftsReceived = '$virtualGifts/received';
  static const String virtualGiftsSent = '$virtualGifts/sent';

  // ================================
  // COMMUNICATION & SOCIAL
  // ================================

  // Voice Messages endpoints (voice-messages.controller.ts)
  static const String voiceMessages = '/voice-messages';
  static const String voiceMessagesSend = '$voiceMessages/send';
  static const String voiceMessagesGet = '$voiceMessages/messages';
  static const String voiceMessagesDelete = '$voiceMessages/delete';

  // WebRTC endpoints (webrtc.controller.ts)
  static const String webrtc = '/webrtc';
  static const String webrtcOffer = '$webrtc/offer';
  static const String webrtcAnswer = '$webrtc/answer';
  static const String webrtcCandidate = '$webrtc/candidate';
  static const String webrtcEndCall = '$webrtc/end-call';
  static const String webrtcCallHistory = '$webrtc/call-history';
  static const String webrtcRtcToken = '$webrtc/rtc-token';

  // Social Gaming endpoints (social-gaming.controller.ts)
  static const String socialGaming = '/social-gaming';
  static const String socialGamingGames = '$socialGaming/games';
  static const String socialGamingJoin = '$socialGaming/join';
  static const String socialGamingLeaderboard = '$socialGaming/leaderboard';
  static const String socialGamingAchievements = '$socialGaming/achievements';

  // ================================
  // ADVANCED FEATURES
  // ================================

  // AI Companion endpoints (ai-companion.controller.ts)
  static const String aiCompanion = '/ai-companion';
  static const String aiCompanionChat = '$aiCompanion/chat';
  static const String aiCompanionPersonality = '$aiCompanion/personality';
  static const String aiCompanionSettings = '$aiCompanion/settings';

  // AI Matching endpoints (ai-matching.controller.ts)
  static const String aiMatching = '/ai-matching';
  static const String aiMatchingAnalyze = '$aiMatching/analyze';
  static const String aiMatchingRecommendations = '$aiMatching/recommendations';
  static const String aiMatchingCompatibility = '$aiMatching/compatibility';

  // AI Services endpoints (ai.controller.ts)
  static const String ai = '/ai';
  static const String aiChatAssistance = '$ai/chat-assistance';
  static const String aiConversationAnalyze = '$ai/conversation/analyze';
  static const String aiProfileAnalyze = '$ai/profile/analyze';
  static const String aiProfileConversationStarters =
      '$ai/profile/conversation-starters';
  static const String aiProfileCompatibility = '$ai/profile/compatibility';
  static const String aiPhotosAnalyze = '$ai/photos/analyze';
  static const String aiFeedback = '$ai/feedback';

  // AR Features endpoints (ar-features.controller.ts)
  static const String arFeatures = '/ar-features';
  static const String arFeaturesIcebreakers = '$arFeatures/icebreakers';
  static const String arFeaturesAssets = '$arFeatures/assets';
  static const String arFeaturesSessions = '$arFeatures/sessions';
  static const String arFeaturesPresets = '$arFeatures/presets';

  // Travel Planning endpoints (travel-planning.controller.ts)
  static const String travelPlanning = '/travel-planning';
  static const String travelPlanningPlans = '$travelPlanning/plans';
  static const String travelPlanningDestinations =
      '$travelPlanning/destinations';
  static const String travelPlanningInvite =
      '$travelPlanning/plans'; // POST /:planId/invite
  static const String travelPlanningBookings =
      '$travelPlanning/plans'; // POST /:planId/bookings

  // Speed Dating endpoints (speed-dating.controller.ts)
  static const String speedDating = '/api/v1/speed-dating';
  static const String speedDatingSessions = '$speedDating/sessions';
  static const String speedDatingJoin = '$speedDating/join';
  static const String speedDatingResults = '$speedDating/results';

  // ================================
  // SAFETY & MODERATION
  // ================================

  // Safety endpoints (safety.controller.ts)
  static const String safety = '/api/v1/safety';
  static const String safetyReports = '$safety/reports';
  static const String safetyReportUser = '$safetyReports/user';
  static const String safetyReportContent = '$safetyReports/content';
  static const String safetyBlockUser = '$safety/block';
  static const String safetyUnblockUser = '$safety/unblock';
  static const String safetyBlockedUsers = '$safety/blocked';
  static const String safetySettings = '$safety/settings';
  static const String safetyScore = '$safety/score';
  static const String safetyVerifyPhoto = '$safety/verify-photo';
  static const String safetyVerifyIdFront = '$safety/verify-id/front';
  static const String safetyVerifyIdBack = '$safety/verify-id/back';
  static const String safetyTips = '$safety/tips';
  static const String safetyReportDateConcern = '$safety/report-date-concern';
  static const String safetyEmergencyContact = '$safety/emergency-contact';
  static const String safetyEmergencyContacts =
      '$safety/emergency-contacts'; // GET/POST
  static const String safetyEmergencyContactsTest =
      '$safety/emergency-contacts/test'; // POST test notification
  static const String safetyCheckUser = '$safety/check-user';
  static const String safetyMyReports = '$safety/my-reports';
  static const String safetyStats = '$safety/stats';
  static const String safetyDashboard = '$safety/dashboard';

  // Reports endpoints (reports.controller.ts)
  static const String reports = '/reports';
  static const String reportsCreate = '$reports/create';
  static const String reportsStats = '$reports/stats';

  // ================================
  // ANALYTICS & MONITORING
  // ================================

  // Analytics endpoints (analytics.controller.ts)
  static const String analytics = '/analytics';
  static const String analyticsEvents = '$analytics/events';
  static const String analyticsTrack = '$analytics/track';
  static const String analyticsInsights = '$analytics/insights';
  static const String analyticsUserProperties = '$analytics/user-properties';
  
  // Notifications endpoints (notifications.controller.ts)
  static const String notifications = '/notifications';
  static const String notificationsSettings = '$notifications/settings';
  static const String notificationsMarkRead = '$notifications/mark-read';
  static const String notificationsPush = '$notifications/push';

  // ================================
  // ADDITIONAL SERVICES
  // ================================
  
  // Maps endpoints (maps.controller.ts)
  static const String maps = '/maps';
  static const String mapsNearby = '$maps/nearby';
  static const String mapsGeocoding = '$maps/geocoding';
  
  // Email endpoints (email.controller.ts)
  static const String email = '/email';
  static const String emailSend = '$email/send';
  static const String emailTemplates = '$email/templates';
  
  // WhatsApp endpoints (whatsapp.controller.ts)
  static const String whatsapp = '/whatsapp';
  static const String whatsappSend = '$whatsapp/send';
  static const String whatsappStatus = '$whatsapp/status';
  static const String whatsappWebhook = '$whatsapp/webhook';
  
  // Events endpoints (events.controller.ts)
  static const String events = '/events';
  static const String eventsCreate = '$events/create';
  static const String eventsJoin = '$events/join';
  static const String eventsNearby = '$events/nearby';
  
  // ================================
  // WEBSOCKET EVENTS
  // ================================
  
  static const String wsNewMessage = 'new_message';
  static const String wsMessageRead = 'message_read';
  static const String wsUserOnline = 'user_online';
  static const String wsUserOffline = 'user_offline';
  static const String wsNewMatch = 'new_match';
  static const String wsCallOffer = 'call_offer';
  static const String wsCallAnswer = 'call_answer';
  static const String wsCallEnd = 'call_end';
  static const String wsTyping = 'typing';
  static const String wsStopTyping = 'stop_typing';
  
  // ================================
  // CONFIGURATION
  // ================================
  
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
