/// Test configuration for integration tests
class TestConfig {
  /// Backend API URL for testing
  static const String testApiUrl = 'http://localhost:3000/api/v1';

  /// Test user credentials
  static const String testEmail = 'user@pulselink.com';
  static const String testPassword = 'User123!';

  /// Admin credentials for elevated tests
  static const String adminEmail = 'admin@pulselink.com';
  static const String adminPassword = 'Admin123!';

  /// Default timeout for async operations
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Short timeout for quick operations
  static const Duration shortTimeout = Duration(seconds: 5);

  /// Long timeout for slow operations (uploads, etc.)
  static const Duration longTimeout = Duration(seconds: 60);

  /// Pump duration for animations
  static const Duration pumpDuration = Duration(milliseconds: 100);
}
