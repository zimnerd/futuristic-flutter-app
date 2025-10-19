import 'package:integration_test/integration_test_driver.dart';

/// Test driver entry point for integration tests
/// 
/// This file serves as the entry point for running integration tests.
/// It uses the integrationDriver() function which automatically
/// connects to the Flutter Driver and runs all integration tests.
/// 
/// To run integration tests:
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/flows/auth_flow_test.dart
/// ```
/// 
/// Or run all tests:
/// ```bash
/// flutter test integration_test/
/// ```
Future<void> main() => integrationDriver();
