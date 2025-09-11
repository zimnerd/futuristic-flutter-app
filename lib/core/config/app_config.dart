/// Environment configuration for the app
class AppConfig {
  AppConfig._();

  // Environment flags
  static const bool isDevelopment = false; // Changed to production
  static const bool isProduction = true; // Changed to production

  // API Configuration - Using production backend
  static const String apiBaseUrl = isDevelopment
      ? 'http://localhost:3000/api/v1'
      : 'https://pulsetechnology.co.za:3000/api/v1'; // Production backend

  static const String websocketUrl = isDevelopment
      ? 'http://localhost:3000'
      : 'https://pulsetechnology.co.za:3000'; // Production WebSocket

  // PeachPayments Configuration
  static const String peachPaymentsBaseUrl = isDevelopment
      ? 'https://test.oppwa.com' // Test environment
      : 'https://oppwa.com'; // Production environment

  static const String peachPaymentsEntityId = isDevelopment
      ? '8a8294174e735d0c014e78cf26461790' // Test entity ID
      : 'YOUR_PRODUCTION_ENTITY_ID'; // TODO: Replace with production entity ID

  static const String peachPaymentsAccessToken = isDevelopment
      ? 'OGE4Mjk0MTc0ZTczNWQwYzAxNGU3OGNmMjY0NjE3OTB8c3k2S0pzVDg=' // Test access token
      : 'YOUR_PRODUCTION_ACCESS_TOKEN'; // TODO: Replace with production access token

  // Payment webhook configuration
  static const String webhookSecret = isDevelopment
      ? 'test_webhook_secret_key'
      : 'YOUR_PRODUCTION_WEBHOOK_SECRET'; // TODO: Replace with production webhook secret

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration websocketTimeout = Duration(seconds: 10);
  static const Duration paymentTimeout = Duration(seconds: 45);

  // App Info
  static const String appName = 'Pulse Dating';
  static const String appVersion = '1.0.0';
  static const String userAgent = 'PulseLink-Mobile/1.0.0';

  // Feature Flags
  static const bool enableLogging = isDevelopment;
  static const bool enableCrashReporting = isProduction;
  static const bool enableAnalytics = isProduction;
  static const bool enablePayments = true;
  static const bool enableSubscriptions = true;

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String deviceIdKey = 'device_id';
  static const String paymentMethodsKey = 'saved_payment_methods';
  static const String subscriptionKey = 'current_subscription';

  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Payment Configuration
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'ZAR'];
  static const String defaultCurrency = 'USD';

  // Subscription Configuration
  static const Duration subscriptionCacheExpiry = Duration(hours: 1);
  static const int maxRetryAttempts = 3;
}
