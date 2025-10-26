class AppConfig {
  AppConfig._();

  // ================================
  // 🎯 MANUAL ENVIRONMENT CONTROL
  // ================================
  // Change this manually to switch between dev/prod
  static const bool _useProductionEnvironment =
      true; // Set to true for production

  // Environment flags based on manual setting
  static const bool isDevelopment = !_useProductionEnvironment;
  static const bool isProduction = _useProductionEnvironment;
  static const bool isStaging = false; // Can be controlled separately if needed

  // Environment detection based on flavor or debug mode (for legacy support)
  static const String _flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: _useProductionEnvironment ? 'production' : 'development',
  );

  // API Configuration - Environment-based for development
  static String get apiBaseUrl {
    if (isDevelopment) {
      final host = 'localhost';
      return 'http://$host:3000/api/v1';
    }
    return 'https://apilink.pulsetek.co.za/api/v1';
  }

  static String get websocketUrl {
    if (isDevelopment) {
      final host = 'localhost';
      return 'ws://$host:3000';
    }
    return 'wss://apilink.pulsetek.co.za';
  }

  static String get aiCompanionWebSocketUrl {
    if (isDevelopment) {
      final host = 'localhost';
      return 'http://$host:3000';
    }
    return 'https://apilink.pulsetek.co.za';
  }

  // PeachPayments Configuration - Environment-based
  static const String peachPaymentsBaseUrl = isDevelopment || isStaging
      ? 'https://test.oppwa.com' // Test environment
      : 'https://oppwa.com'; // Production environment

  static const String peachPaymentsEntityId = isDevelopment || isStaging
      ? String.fromEnvironment(
          'PEACH_TEST_ENTITY_ID',
          defaultValue: 'test-entity-id',
        )
      : String.fromEnvironment('PEACH_PROD_ENTITY_ID', defaultValue: '');

  static const String peachPaymentsAccessToken = isDevelopment || isStaging
      ? String.fromEnvironment(
          'PEACH_TEST_ACCESS_TOKEN',
          defaultValue: 'test-access-token',
        )
      : String.fromEnvironment('PEACH_PROD_ACCESS_TOKEN', defaultValue: '');

  // Payment webhook configuration
  static const String webhookSecret = isDevelopment || isStaging
      ? String.fromEnvironment(
          'WEBHOOK_TEST_SECRET',
          defaultValue: 'test_webhook_secret_key',
        )
      : String.fromEnvironment('WEBHOOK_PROD_SECRET', defaultValue: '');

  // Timeouts - Environment-based
  static const Duration apiTimeout = Duration(
    seconds: isDevelopment
        ? 60
        : 30, // Longer timeout for development debugging
  );
  static const Duration websocketTimeout = Duration(seconds: 10);
  static const Duration paymentTimeout = Duration(
    seconds: isDevelopment ? 60 : 45, // Longer timeout for development
  );

  // App Info - Environment-based
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'PulseLink',
  );
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  static const String userAgent = 'PulseLink-Mobile/$appVersion';

  // Feature Flags - Environment-based
  static const bool enableLogging = isDevelopment || isStaging;
  static const bool enableCrashReporting = isProduction || isStaging;
  static const bool enableAnalytics = isProduction || isStaging;
  static const bool enablePayments = true;
  static const bool enableSubscriptions = true;
  static const bool enableDebugTools = isDevelopment;

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

  // Configuration validation and debugging
  static bool get isConfigValid {
    if (isProduction) {
      return peachPaymentsEntityId.isNotEmpty &&
          peachPaymentsAccessToken.isNotEmpty &&
          webhookSecret.isNotEmpty;
    }
    return true; // Allow incomplete config in development/staging
  }

  static Map<String, dynamic> get configSummary {
    return {
      'environment': isDevelopment
          ? 'development'
          : isStaging
          ? 'staging'
          : 'production',
      'apiBaseUrl': apiBaseUrl,
      'websocketUrl': websocketUrl,
      'paymentsEnabled': enablePayments,
      'subscriptionsEnabled': enableSubscriptions,
      'loggingEnabled': enableLogging,
      'configValid': isConfigValid,
    };
  }

  // Environment-specific debug information (only available in development)
  static String get debugInfo {
    if (!isDevelopment) return 'Debug info only available in development';

    return '''
Environment Configuration:
- Flavor: $_flavor
- Development: $isDevelopment
- Staging: $isStaging  
- Production: $isProduction
- API Base URL: $apiBaseUrl
- WebSocket URL: $websocketUrl
- Payments Base URL: $peachPaymentsBaseUrl
- Config Valid: $isConfigValid
- Logging Enabled: $enableLogging
- Debug Tools Enabled: $enableDebugTools
''';
  }
}
