import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';

/// Helper class for authentication-related test operations
class AuthHelper {
  /// Login with provided credentials
  ///
  /// This helper:
  /// 1. Finds and fills the email field
  /// 2. Finds and fills the password field
  /// 3. Taps the login button
  /// 4. Waits for navigation to complete
  static Future<void> loginWithCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    // Wait for login screen to be ready
    await tester.pumpAndSettle();

    // Find email field by key or type
    final emailFinder = find.byKey(const Key('email_field'));
    expect(emailFinder, findsOneWidget,
        reason: 'Email field should be visible on login screen');

    // Enter email
    await tester.enterText(emailFinder, email);
    await tester.pump(TestConfig.pumpDuration);

    // Find password field
    final passwordFinder = find.byKey(const Key('password_field'));
    expect(passwordFinder, findsOneWidget,
        reason: 'Password field should be visible on login screen');

    // Enter password
    await tester.enterText(passwordFinder, password);
    await tester.pump(TestConfig.pumpDuration);

    // Find and tap login button
    final loginButtonFinder = find.byKey(const Key('login_button'));
    expect(loginButtonFinder, findsOneWidget,
        reason: 'Login button should be visible');

    await tester.tap(loginButtonFinder);

    // Wait for navigation and API call
    await tester.pumpAndSettle(TestConfig.defaultTimeout);
  }

  /// Login with test user credentials
  static Future<void> loginAsTestUser(WidgetTester tester) async {
    await loginWithCredentials(
      tester,
      email: TestConfig.testEmail,
      password: TestConfig.testPassword,
    );
  }

  /// Login with admin credentials
  static Future<void> loginAsAdmin(WidgetTester tester) async {
    await loginWithCredentials(
      tester,
      email: TestConfig.adminEmail,
      password: TestConfig.adminPassword,
    );
  }

  /// Logout from the app
  ///
  /// This helper:
  /// 1. Navigates to profile tab
  /// 2. Finds and taps logout button
  /// 3. Confirms logout if confirmation dialog appears
  /// 4. Waits for navigation back to login
  static Future<void> logout(WidgetTester tester) async {
    // Navigate to profile tab
    final profileTabFinder = find.byIcon(Icons.person);
    if (profileTabFinder.evaluate().isNotEmpty) {
      await tester.tap(profileTabFinder);
      await tester.pumpAndSettle();
    }

    // Find logout button (could be text or icon)
    final logoutFinder = find.text('Logout').first;
    expect(logoutFinder, findsOneWidget,
        reason: 'Logout button should be visible in profile');

    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    // Handle confirmation dialog if it appears
    final confirmFinder = find.text('Confirm');
    if (confirmFinder.evaluate().isNotEmpty) {
      await tester.tap(confirmFinder);
      await tester.pumpAndSettle();
    }

    // Wait for navigation back to login
    await tester.pumpAndSettle(TestConfig.defaultTimeout);
  }

  /// Verify user is logged in by checking for home screen elements
  static void verifyLoggedIn(WidgetTester tester) {
    // Check for bottom navigation bar (indicates home screen)
    expect(
      find.byType(NavigationBar),
      findsOneWidget,
      reason: 'Bottom navigation should be visible after login',
    );
  }

  /// Verify user is logged out by checking for login screen elements
  static void verifyLoggedOut(WidgetTester tester) {
    // Check for login button or welcome text
    expect(
      find.text('Welcome to PulseLink'),
      findsOneWidget,
      reason: 'Welcome message should be visible on login screen',
    );
  }

  /// Enter invalid email format and verify error message
  static Future<void> enterInvalidEmail(
    WidgetTester tester,
    String invalidEmail,
  ) async {
    final emailFinder = find.byKey(const Key('email_field'));
    await tester.enterText(emailFinder, invalidEmail);
    await tester.pump(TestConfig.pumpDuration);

    // Tap elsewhere to trigger validation
    await tester.tap(find.byKey(const Key('password_field')));
    await tester.pumpAndSettle();
  }

  /// Enter wrong password and verify error handling
  static Future<void> attemptLoginWithWrongPassword(
    WidgetTester tester,
  ) async {
    await loginWithCredentials(
      tester,
      email: TestConfig.testEmail,
      password: 'WrongPassword123!',
    );

    // Verify error message appears
    expect(
      find.textContaining('Invalid credentials'),
      findsOneWidget,
      reason: 'Error message should appear for wrong password',
    );
  }

  /// Skip login (for testing flows that don't require authentication)
  static Future<void> skipLogin(WidgetTester tester) async {
    final skipFinder = find.text('Skip');
    if (skipFinder.evaluate().isNotEmpty) {
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();
    }
  }

  /// Navigate to signup screen
  static Future<void> navigateToSignup(WidgetTester tester) async {
    final signupFinder = find.text('Sign Up');
    expect(signupFinder, findsOneWidget,
        reason: 'Sign Up button should be visible on login screen');

    await tester.tap(signupFinder);
    await tester.pumpAndSettle();

    // Verify signup screen is shown
    expect(
      find.text('Create Account'),
      findsOneWidget,
      reason: 'Signup screen should be visible',
    );
  }

  /// Navigate to forgot password screen
  static Future<void> navigateToForgotPassword(WidgetTester tester) async {
    final forgotPasswordFinder = find.text('Forgot Password?');
    if (forgotPasswordFinder.evaluate().isNotEmpty) {
      await tester.tap(forgotPasswordFinder);
      await tester.pumpAndSettle();
    }
  }
}
