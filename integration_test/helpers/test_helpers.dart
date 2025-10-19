import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_dating_app/main.dart';
import 'package:pulse_dating_app/core/storage/hive_storage_service.dart';
import 'test_config.dart';
import 'auth_helper.dart';

/// Common test helper utilities
class TestHelpers {
  /// Initialize and pump the app for testing
  static Future<void> pumpApp(WidgetTester tester) async {
    // Initialize HiveStorageService for testing
    final hiveStorage = HiveStorageService();
    await hiveStorage.initialize();
    
    await tester.pumpWidget(PulseDatingApp(hiveStorage: hiveStorage));
    await tester.pumpAndSettle(TestConfig.defaultTimeout);
  }

  /// Setup authenticated app (login first, then pump)
  static Future<void> setupAuthenticatedApp(WidgetTester tester) async {
    await pumpApp(tester);

    // Login as test user
    await AuthHelper.loginAsTestUser(tester);

    // Verify we're on home screen
    expect(
      find.byType(NavigationBar),
      findsOneWidget,
      reason: 'Should be on home screen after login',
    );
  }

  /// Wait for loading indicator to disappear
  static Future<void> waitForLoadingToFinish(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final startTime = DateTime.now();

    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      if (DateTime.now().difference(startTime) > timeout) {
        throw Exception('Timeout waiting for loading to finish');
      }

      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.pumpAndSettle();
  }

  /// Find text containing a substring (case-insensitive)
  static Finder findTextContaining(String substring) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.toLowerCase().contains(substring.toLowerCase()),
    );
  }

  /// Tap and wait for navigation/animation
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(TestConfig.defaultTimeout);
  }

  /// Enter text and wait for validation
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump(TestConfig.pumpDuration);
  }

  /// Verify error message is displayed
  static void verifyErrorMessage(WidgetTester tester, String message) {
    expect(
      findTextContaining(message),
      findsAtLeastNWidgets(1),
      reason: 'Error message "$message" should be displayed',
    );
  }

  /// Verify success message is displayed
  static void verifySuccessMessage(WidgetTester tester, String message) {
    expect(
      findTextContaining(message),
      findsAtLeastNWidgets(1),
      reason: 'Success message "$message" should be displayed',
    );
  }

  /// Dismiss snackbar if visible
  static Future<void> dismissSnackbar(WidgetTester tester) async {
    final snackbarFinder = find.byType(SnackBar);
    if (snackbarFinder.evaluate().isNotEmpty) {
      // Wait for snackbar to auto-dismiss
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  }

  /// Dismiss dialog if visible
  static Future<void> dismissDialog(WidgetTester tester) async {
    final dialogFinder = find.byType(AlertDialog);
    if (dialogFinder.evaluate().isNotEmpty) {
      // Try to find and tap dismiss button
      Finder? dismissFinder;
      
      if (find.text('OK').evaluate().isNotEmpty) {
        dismissFinder = find.text('OK');
      } else if (find.text('Close').evaluate().isNotEmpty) {
        dismissFinder = find.text('Close');
      } else if (find.text('Dismiss').evaluate().isNotEmpty) {
        dismissFinder = find.text('Dismiss');
      } else if (find.text('Cancel').evaluate().isNotEmpty) {
        dismissFinder = find.text('Cancel');
      }

      if (dismissFinder != null) {
        await tester.tap(dismissFinder.first);
        await tester.pumpAndSettle();
      }
    }
  }

  /// Verify widget is visible on screen
  static void verifyWidgetVisible(WidgetTester tester, Finder finder) {
    expect(
      finder,
      findsAtLeastNWidgets(1),
      reason: 'Widget should be visible',
    );
  }

  /// Verify widget is NOT visible on screen
  static void verifyWidgetNotVisible(WidgetTester tester, Finder finder) {
    expect(
      finder,
      findsNothing,
      reason: 'Widget should NOT be visible',
    );
  }

  /// Simulate swipe gesture (for discovery cards, etc.)
  static Future<void> swipeRight(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(300, 0));
    await tester.pumpAndSettle();
  }

  /// Simulate swipe left gesture
  static Future<void> swipeLeft(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  /// Simulate swipe up gesture
  static Future<void> swipeUp(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  /// Simulate swipe down gesture
  static Future<void> swipeDown(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.drag(finder, const Offset(0, 300));
    await tester.pumpAndSettle();
  }

  /// Take a screenshot (for debugging)
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String filename,
  ) async {
    // This requires additional setup with integration_test
    // For now, just a placeholder
    debugPrint('📸 Screenshot: $filename');
  }

  /// Print current widget tree (for debugging)
  static void printWidgetTree(WidgetTester tester) {
    debugPrint('🌳 Widget Tree:');
    debugPrint(tester.allWidgets.toString());
  }

  /// Wait for a specific duration
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Verify list has expected number of items
  static void verifyListItemCount(
    WidgetTester tester,
    Type listItemType,
    int expectedCount,
  ) {
    final items = find.byType(listItemType);
    expect(
      items.evaluate().length,
      expectedCount,
      reason: 'List should have $expectedCount items of type $listItemType',
    );
  }

  /// Find widget by key string
  static Finder findByKeyString(String keyString) {
    return find.byKey(Key(keyString));
  }

  /// Verify form field has error
  static void verifyFieldError(WidgetTester tester, String errorText) {
    expect(
      findTextContaining(errorText),
      findsOneWidget,
      reason: 'Field error "$errorText" should be displayed',
    );
  }

  /// Verify button is enabled
  static void verifyButtonEnabled(WidgetTester tester, Finder buttonFinder) {
    final button = tester.widget(buttonFinder);
    if (button is ElevatedButton) {
      expect(button.enabled, isTrue, reason: 'Button should be enabled');
    }
  }

  /// Verify button is disabled
  static void verifyButtonDisabled(WidgetTester tester, Finder buttonFinder) {
    final button = tester.widget(buttonFinder);
    if (button is ElevatedButton) {
      expect(button.enabled, isFalse, reason: 'Button should be disabled');
    }
  }

  /// Clear text field
  static Future<void> clearTextField(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.enterText(finder, '');
    await tester.pump(TestConfig.pumpDuration);
  }

  /// Long press on widget
  static Future<void> longPress(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }
}
