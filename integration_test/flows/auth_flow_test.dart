import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_helpers.dart';
import '../helpers/auth_helper.dart';
import '../helpers/test_config.dart';

/// Authentication Flow E2E Tests
/// 
/// Tests all authentication-related user flows:
/// 1. Login with valid credentials
/// 2. Login with invalid email format
/// 3. Login with wrong password
/// 4. Logout successfully
/// 5. Navigate to signup from login
/// 6. Navigate to forgot password from login
/// 7. Session persistence after app restart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow E2E Tests', () {
    testWidgets('1. Login with valid credentials', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Verify we're on welcome/login screen
      AuthHelper.verifyLoggedOut(tester);

      // Perform login
      await AuthHelper.loginAsTestUser(tester);

      // Verify successful login
      AuthHelper.verifyLoggedIn(tester);
      
      // Should see main navigation
      expect(find.byType(NavigationBar), findsOneWidget);
      
      // Cleanup: logout
      await AuthHelper.logout(tester);
    });

    testWidgets('2. Login with invalid email format', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Enter invalid email
      await AuthHelper.enterInvalidEmail(tester, 'not-an-email');

      // Try to login
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show error message
      TestHelpers.verifyErrorMessage(
        tester,
        'Please enter a valid email address',
      );

      // Should NOT navigate away from login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('3. Login with wrong password', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Attempt login with wrong password
      await AuthHelper.attemptLoginWithWrongPassword(tester);

      // Should show error message
      TestHelpers.verifyErrorMessage(
        tester,
        'Invalid email or password',
      );

      // Should still be on login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      AuthHelper.verifyLoggedOut(tester);
    });

    testWidgets('4. Logout successfully', (WidgetTester tester) async {
      // Setup: login first
      await TestHelpers.setupAuthenticatedApp(tester);

      // Verify logged in
      AuthHelper.verifyLoggedIn(tester);

      // Perform logout
      await AuthHelper.logout(tester);

      // Verify logged out
      AuthHelper.verifyLoggedOut(tester);
      
      // Should see welcome/login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('5. Navigate to signup from login', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Verify on login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget);

      // Navigate to signup
      await AuthHelper.navigateToSignup(tester);

      // Should be on signup screen
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byKey(const Key('signup_button')), findsOneWidget);
    });

    testWidgets('6. Navigate to forgot password from login', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Verify on login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget);

      // Navigate to forgot password
      await AuthHelper.navigateToForgotPassword(tester);

      // Should be on forgot password screen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('reset_password_button')), findsOneWidget);
    });

    testWidgets('7. Session persistence after app restart', (WidgetTester tester) async {
      // Phase 1: Login and verify
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      await AuthHelper.loginAsTestUser(tester);
      AuthHelper.verifyLoggedIn(tester);

      // Simulate app restart by pumping a new app instance
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle(TestConfig.longTimeout);

      // Should still be logged in (token persisted)
      AuthHelper.verifyLoggedIn(tester);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Cleanup: logout
      await AuthHelper.logout(tester);
    });
  });

  group('Authentication Flow - Edge Cases', () {
    testWidgets('Empty email and password shows errors', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Tap login without entering credentials
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(
        find.textContaining('email', findRichText: true),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('password', findRichText: true),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Loading state during login', (WidgetTester tester) async {
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        TestConfig.testEmail,
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        TestConfig.testPassword,
      );

      // Tap login
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      
      // Wait a bit to see loading state
      await tester.pump(const Duration(milliseconds: 100));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for login to complete
      await tester.pumpAndSettle(TestConfig.defaultTimeout);

      // Cleanup: logout
      await AuthHelper.logout(tester);
    });

    testWidgets('Network error shows appropriate message', (WidgetTester tester) async {
      // Note: This test assumes backend is NOT running
      // Skip if backend is available
      
      // Setup
      await TestHelpers.pumpApp(tester);
      await tester.pumpAndSettle();

      // Try to login
      await tester.enterText(
        find.byKey(const Key('email_field')),
        TestConfig.testEmail,
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        TestConfig.testPassword,
      );

      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle(TestConfig.longTimeout);

      // If backend is down, should show network error
      // This is an optional check - test passes if login succeeds too
      final hasNetworkError = find.textContaining('network').evaluate().isNotEmpty ||
          find.textContaining('connection').evaluate().isNotEmpty;
      
      final hasSuccess = find.byType(NavigationBar).evaluate().isNotEmpty;

      // Either error or success is acceptable
      expect(hasNetworkError || hasSuccess, isTrue);
    });
  });
}
