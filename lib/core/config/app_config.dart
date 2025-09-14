/// Environment configuration for the app
class AppConfig {
  AppConfig._();

  // Environment flags
  static const bool isDevelopment =
      true; // Changed back to development for local testing
  static const bool isProduction =
      false; // Changed back to development for local testing

  // API Configuration - Updated to match backend configuration
  static const String apiBaseUrl = isDevelopment
      ? 'http://localhost:3000/api/v1' // Local backend matching .env.example
      : 'https://apilink.pulsetek.co.za/api/v1'; // Production backend

  static const String websocketUrl = isDevelopment
      ? 'http://localhost:3000' // Local WebSocket
      : 'https://apilink.pulsetek.co.za'; // Production WebSocket

  // PeachPayments Configuration - Updated from .env
  static const String peachPaymentsBaseUrl = isDevelopment
      ? 'https://test.oppwa.com' // Test environment from .env
      : 'https://oppwa.com'; // Production environment

  static const String peachPaymentsEntityId = isDevelopment
      ? 'your-peach-entity-id' // From .env - needs to be replaced with actual value
      : 'YOUR_PRODUCTION_ENTITY_ID'; // TODO: Replace with production entity ID

  static const String peachPaymentsAccessToken = isDevelopment
      ? 'your-peach-access-token' // From .env - needs to be replaced with actual value
      : 'YOUR_PRODUCTION_ACCESS_TOKEN'; // TODO: Replace with production access token

  // Payment webhook configuration
  static const String webhookSecret = isDevelopment
      ? 'test_webhook_secret_key'
      : 'YOUR_PRODUCTION_WEBHOOK_SECRET'; // TODO: Replace with production webhook secret

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration websocketTimeout = Duration(seconds: 10);
  static const Duration paymentTimeout = Duration(seconds: 45);

  // App Info - Updated from .env
  static const String appName = 'PulseLink'; // From .env APP_NAME
  static const String appVersion = '1.0.0'; // From .env APP_VERSION
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

  // Payment Configuration - Updated for South African market
  static const List<String> supportedCurrencies = ['ZAR', 'USD', 'EUR', 'GBP'];
  static const String defaultCurrency =
      'ZAR'; // Primary currency for South Africa

  // Subscription Configuration
  static const Duration subscriptionCacheExpiry = Duration(hours: 1);
  static const int maxRetryAttempts = 3;
}
