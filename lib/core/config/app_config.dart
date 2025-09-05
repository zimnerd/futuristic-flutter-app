/// Environment configuration for the app
class AppConfig {
  AppConfig._();

  // Environment flags
  static const bool isDevelopment = true;
  static const bool isProduction = false;

  // API Configuration
  static const String apiBaseUrl = isDevelopment
      ? 'http://localhost:3000/api/v1'
      : 'https://api.pulselink.com/v1';

  static const String websocketUrl = isDevelopment
      ? 'http://localhost:3000'
      : 'https://api.pulselink.com';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration websocketTimeout = Duration(seconds: 10);

  // App Info
  static const String appName = 'Pulse Dating';
  static const String appVersion = '1.0.0';
  static const String userAgent = 'PulseLink-Mobile/1.0.0';

  // Feature Flags
  static const bool enableLogging = isDevelopment;
  static const bool enableCrashReporting = isProduction;
  static const bool enableAnalytics = isProduction;

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String deviceIdKey = 'device_id';

  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
