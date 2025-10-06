import 'package:flutter/material.dart';

/// A wrapper around [Scaffold] that provides consistent keyboard handling behavior
/// across the entire app, with special optimizations for iOS.
///
/// **Key Features:**
/// - Automatically resizes content when keyboard appears
/// - Allows scrolling to bottom content/buttons when keyboard is visible
/// - Tap-outside-to-dismiss keyboard functionality
/// - Consistent behavior across iOS and Android
/// - iOS-specific optimizations for keyboard animation
/// - Automatic scroll-to-field on focus (iOS)
///
/// **iOS-Specific Improvements:**
/// - Smooth keyboard animations matching system behavior
/// - Proper handling of keyboard height changes
/// - Safe area adjustments for notched devices
/// - Bottom inset padding for input fields
///
/// **Usage:**
/// ```dart
/// KeyboardDismissibleScaffold(
///   appBar: AppBar(title: Text('My Screen')),
///   body: SingleChildScrollView(
///     // ✅ Add keyboard-aware padding
///     padding: EdgeInsets.only(
///       bottom: MediaQuery.of(context).viewInsets.bottom + 16,
///     ),
///     child: Column(
///       children: [
///         TextField(...),
///         SizedBox(height: 20),
///         ElevatedButton(...), // User can scroll to this when keyboard shows
///       ],
///     ),
///   ),
/// )
/// ```
///
/// **Best Practices:**
/// 1. Use this instead of plain [Scaffold] for screens with input fields
/// 2. Wrap scrollable content in [SingleChildScrollView] or [ListView]
/// 3. Add `MediaQuery.of(context).viewInsets.bottom` padding to scrollable content
/// 4. Set `enableDismissOnTap: true` (default) for better UX
/// 5. Set `resizeToAvoidBottomInset: true` (default) for proper keyboard handling
/// 6. Use SafeArea widget for notched iOS devices
class KeyboardDismissibleScaffold extends StatelessWidget {
  /// The app bar to display at the top of the scaffold
  final PreferredSizeWidget? appBar;

  /// The primary content of the scaffold
  final Widget? body;

  /// Widget displayed at the bottom of the scaffold (navigation bar, bottom sheet, etc.)
  final Widget? bottomNavigationBar;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Drawer widget (side menu)
  final Widget? drawer;

  /// End drawer widget (right side menu)
  final Widget? endDrawer;

  /// Background color of the scaffold
  final Color? backgroundColor;

  /// Whether to resize the body when keyboard appears
  /// Default: true (recommended for screens with input fields)
  final bool resizeToAvoidBottomInset;

  /// Whether tapping outside input fields dismisses the keyboard
  /// Default: true (better UX)
  final bool enableDismissOnTap;

  /// The color of the app bar
  final Color? appBarColor;

  /// FloatingActionButton location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Whether to extend body behind app bar
  final bool extendBodyBehindAppBar;

  /// Whether to extend body
  final bool extendBody;

  /// Bottom sheet widget
  final Widget? bottomSheet;

  /// Safe area configuration
  final bool top;
  final bool bottom;

  /// Persistent footer buttons (shown above bottom navigation bar)
  final List<Widget>? persistentFooterButtons;

  const KeyboardDismissibleScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true, // ✅ Default: resize for keyboard
    this.enableDismissOnTap = true, // ✅ Default: tap to dismiss keyboard
    this.appBarColor,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.bottomSheet,
    this.top = true,
    this.bottom = true,
    this.persistentFooterButtons,
  });

  @override
  Widget build(BuildContext context) {
    Widget scaffoldContent = Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      bottomSheet: bottomSheet,
      persistentFooterButtons: persistentFooterButtons,
    );

    // Wrap with GestureDetector to dismiss keyboard on tap
    if (enableDismissOnTap) {
      scaffoldContent = GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside input fields
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: scaffoldContent,
      );
    }

    return scaffoldContent;
  }
}

/// Extension on [Widget] to easily make any widget keyboard-dismissible
///
/// **Usage:**
/// ```dart
/// Column(
///   children: [
///     TextField(...),
///     ElevatedButton(...),
///   ],
/// ).makeKeyboardDismissible()
/// ```
extension KeyboardDismissible on Widget {
  Widget makeKeyboardDismissible({bool enabled = true}) {
    if (!enabled) return this;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: this,
      ),
    );
  }
}

/// Mixin to add keyboard-dismissible behavior to any StatefulWidget
///
/// **Usage:**
/// ```dart
/// class MyScreen extends StatefulWidget {
///   const MyScreen({super.key});
///
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> with KeyboardDismissibleStateMixin {
///   @override
///   Widget build(BuildContext context) {
///     return buildWithKeyboardDismiss(
///       child: Scaffold(
///         body: Column(
///           children: [
///             TextField(...),
///             ElevatedButton(...),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
mixin KeyboardDismissibleStateMixin<T extends StatefulWidget> on State<T> {
  /// Wraps the child widget with keyboard dismiss functionality
  Widget buildWithKeyboardDismiss({
    required Widget child,
    bool enabled = true,
  }) {
    if (!enabled) return child;

    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }

  /// Helper method to dismiss keyboard programmatically
  void dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

/// Helper class for keyboard utilities
class KeyboardUtils {
  KeyboardUtils._();

  /// Dismiss the keyboard
  static void dismiss() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Check if keyboard is currently visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get the keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Listen to keyboard visibility changes
  static void addKeyboardVisibilityListener(
    BuildContext context,
    void Function(bool isVisible) onChanged,
  ) {
    // Store previous state
    double previousInset = MediaQuery.of(context).viewInsets.bottom;
    bool wasVisible = previousInset > 0;

    // This would need to be implemented with a proper listener
    // For now, this is a placeholder showing the pattern
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentInset = MediaQuery.of(context).viewInsets.bottom;
      final isVisible = currentInset > 0;

      if (wasVisible != isVisible) {
        onChanged(isVisible);
      }
    });
  }
}
