import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';

/// Helper class for navigation-related test operations
class NavigationHelper {
  /// Navigate to a specific tab in the bottom navigation
  ///
  /// Supports navigation by:
  /// - Tab text label
  /// - Tab icon
  /// - Tab index
  static Future<void> navigateToTab(
    WidgetTester tester,
    String tabName,
  ) async {
    final tabFinder = find.text(tabName);
    expect(tabFinder, findsOneWidget,
        reason: 'Tab "$tabName" should be visible in navigation');

    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  /// Navigate to tab by icon
  static Future<void> navigateToTabByIcon(
    WidgetTester tester,
    IconData icon,
  ) async {
    final iconFinder = find.byIcon(icon);
    expect(iconFinder, findsAtLeastNWidgets(1),
        reason: 'Icon should be visible in navigation');

    await tester.tap(iconFinder.first);
    await tester.pumpAndSettle();
  }

  /// Navigate to Discover tab
  static Future<void> navigateToDiscover(WidgetTester tester) async {
    await navigateToTab(tester, 'Discover');
  }

  /// Navigate to Chat tab
  static Future<void> navigateToChat(WidgetTester tester) async {
    await navigateToTab(tester, 'Chat');
  }

  /// Navigate to Events tab
  static Future<void> navigateToEvents(WidgetTester tester) async {
    await navigateToTab(tester, 'Events');
  }

  /// Navigate to Profile tab
  static Future<void> navigateToProfile(WidgetTester tester) async {
    await navigateToTabByIcon(tester, Icons.person);
  }

  /// Wait for a specific screen to load by checking for its title
  static Future<void> waitForScreen(
    WidgetTester tester,
    String screenTitle, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);

    expect(
      find.text(screenTitle),
      findsOneWidget,
      reason: 'Screen "$screenTitle" should be visible',
    );
  }

  /// Wait for a widget of specific type to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Type widgetType, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);

    expect(
      find.byType(widgetType),
      findsAtLeastNWidgets(1),
      reason: 'Widget of type $widgetType should be visible',
    );
  }

  /// Go back using the back button
  static Future<void> goBack(WidgetTester tester) async {
    final backButtonFinder = find.byTooltip('Back');
    if (backButtonFinder.evaluate().isEmpty) {
      // Try finding by icon
      final backIconFinder = find.byIcon(Icons.arrow_back);
      if (backIconFinder.evaluate().isNotEmpty) {
        await tester.tap(backIconFinder.first);
      }
    } else {
      await tester.tap(backButtonFinder);
    }

    await tester.pumpAndSettle();
  }

  /// Open drawer/menu if it exists
  static Future<void> openDrawer(WidgetTester tester) async {
    final drawerFinder = find.byTooltip('Open navigation menu');
    if (drawerFinder.evaluate().isNotEmpty) {
      await tester.tap(drawerFinder);
      await tester.pumpAndSettle();
    }
  }

  /// Close drawer/menu if it's open
  static Future<void> closeDrawer(WidgetTester tester) async {
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isNotEmpty) {
      // Tap outside drawer to close it
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
    }
  }

  /// Navigate to settings
  static Future<void> navigateToSettings(WidgetTester tester) async {
    // Usually settings is in profile tab
    await navigateToProfile(tester);

    final settingsFinder = find.text('Settings').last;
    if (settingsFinder.evaluate().isNotEmpty) {
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    }
  }

  /// Scroll to find a widget if it's not immediately visible
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder, {
    double scrollDelta = 300.0,
    int maxScrollAttempts = 10,
  }) async {
    int attempts = 0;

    while (finder.evaluate().isEmpty && attempts < maxScrollAttempts) {
      await tester.drag(
        find.byType(Scrollable).first,
        Offset(0, -scrollDelta),
      );
      await tester.pumpAndSettle();
      attempts++;
    }

    expect(
      finder,
      findsAtLeastNWidgets(1),
      reason: 'Widget should be visible after scrolling',
    );
  }

  /// Scroll to the top of a scrollable widget
  static Future<void> scrollToTop(WidgetTester tester) async {
    final scrollableFinder = find.byType(Scrollable);
    if (scrollableFinder.evaluate().isNotEmpty) {
      await tester.drag(
        scrollableFinder.first,
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Scroll to the bottom of a scrollable widget
  static Future<void> scrollToBottom(WidgetTester tester) async {
    final scrollableFinder = find.byType(Scrollable);
    if (scrollableFinder.evaluate().isNotEmpty) {
      await tester.drag(
        scrollableFinder.first,
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Verify current route/screen by checking for expected elements
  static void verifyOnScreen(WidgetTester tester, String screenTitle) {
    expect(
      find.text(screenTitle),
      findsOneWidget,
      reason: 'Should be on "$screenTitle" screen',
    );
  }

  /// Dismiss keyboard if visible
  static Future<void> dismissKeyboard(WidgetTester tester) async {
    // Tap outside any text field
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  /// Pull to refresh
  static Future<void> pullToRefresh(WidgetTester tester) async {
    final refreshIndicatorFinder = find.byType(RefreshIndicator);
    if (refreshIndicatorFinder.evaluate().isNotEmpty) {
      await tester.drag(
        refreshIndicatorFinder.first,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle(TestConfig.defaultTimeout);
    }
  }
}
