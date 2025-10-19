import 'package:flutter/material.dart';

/// Helper class for managing form field scrolling and keyboard visibility
///
/// **Purpose**: Automatically scroll to focused fields when keyboard appears
/// to ensure they're visible and accessible on both iOS and Android.
///
/// **Usage**:
/// ```dart
/// class _MyFormState extends State<MyForm> {
///   final _scrollHelper = FormScrollHelper();
///
///   @override
///   Widget build(BuildContext context) {
///     return SingleChildScrollView(
///       controller: _scrollHelper.scrollController,
///       child: Column(
///         children: [
///           FormScrollHelper.buildScrollableField(
///             context: context,
///             scrollHelper: _scrollHelper,
///             focusNode: _nameFocusNode,
///             child: TextField(focusNode: _nameFocusNode),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
class FormScrollHelper {
  final ScrollController scrollController;
  final Map<FocusNode, GlobalKey> _fieldKeys = {};

  FormScrollHelper({ScrollController? controller})
    : scrollController = controller ?? ScrollController();

  /// Register a field with its focus node for auto-scrolling
  void registerField(FocusNode focusNode, GlobalKey key) {
    _fieldKeys[focusNode] = key;

    // Add listener to scroll to field when it gains focus
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _scrollToField(key);
      }
    });
  }

  /// Scroll to make a specific field visible when keyboard appears
  void _scrollToField(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) return;

      // Get field position and size
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final fieldOffset = renderBox.localToGlobal(Offset.zero).dy;
      final scrollOffset = scrollController.offset;
      final viewportHeight = scrollController.position.viewportDimension;
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

      // Calculate visible area (viewport minus keyboard)
      final visibleHeight = viewportHeight - keyboardHeight;

      // Calculate where the field should be positioned (25% from top of visible area)
      final targetPosition = visibleHeight * 0.25;

      // Calculate new scroll position
      final newScrollOffset = scrollOffset + fieldOffset - targetPosition;

      // Ensure we don't scroll beyond bounds
      final maxScroll = scrollController.position.maxScrollExtent;
      final clampedOffset = newScrollOffset.clamp(0.0, maxScroll);

      // Animate to new position
      scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Helper method to build a scrollable form field
  ///
  /// Automatically handles field registration and keyboard scrolling
  static Widget buildScrollableField({
    required BuildContext context,
    required FormScrollHelper scrollHelper,
    required FocusNode focusNode,
    required Widget child,
  }) {
    final key = GlobalKey();
    scrollHelper.registerField(focusNode, key);

    return Container(key: key, child: child);
  }

  /// Get keyboard-aware padding for bottom content
  ///
  /// Use this for buttons or content that should stay above keyboard
  static double getKeyboardPadding(BuildContext context, {double extra = 16}) {
    return MediaQuery.of(context).viewInsets.bottom + extra;
  }

  /// Check if keyboard is currently visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Dismiss keyboard
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Move focus to next field
  static void nextField(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous field
  static void previousField(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Clean up resources
  void dispose() {
    scrollController.dispose();
    for (final focusNode in _fieldKeys.keys) {
      focusNode.dispose();
    }
    _fieldKeys.clear();
  }
}

/// Extension on BuildContext for easy keyboard utilities access
extension KeyboardUtils on BuildContext {
  /// Get keyboard height
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;

  /// Dismiss keyboard
  void dismissKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Get safe padding that accounts for keyboard
  EdgeInsets get keyboardSafePadding => EdgeInsets.only(bottom: keyboardHeight);

  /// Get safe padding with extra space
  EdgeInsets keyboardPaddingWith({double extra = 16}) =>
      EdgeInsets.only(bottom: keyboardHeight + extra);
}
