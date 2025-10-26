import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/pulse_colors.dart';
import '../../../core/utils/logger.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Quick Reply Chip Bar Widget
///
/// Displays AI-generated reply suggestions as horizontal scrollable chips
/// Features:
/// - One-tap to populate message field
/// - Long-press to send directly
/// - Swipe to dismiss individual chips
/// - Auto-refresh on new messages
/// - Shimmer loading effect while generating
class QuickReplyChipBar extends StatefulWidget {
  final List<String> suggestions;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(String) onChipTap;
  final Function(String) onChipLongPress;
  final Function(String) onChipDismiss;

  const QuickReplyChipBar({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.onChipTap,
    required this.onChipLongPress,
    required this.onChipDismiss,
    this.onRefresh,
  });

  @override
  State<QuickReplyChipBar> createState() => _QuickReplyChipBarState();
}

class _QuickReplyChipBarState extends State<QuickReplyChipBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(QuickReplyChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestions != oldWidget.suggestions) {
      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if no suggestions and not loading
    if (widget.suggestions.isEmpty && !widget.isLoading) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.formFieldBackground,
          border: Border(
            top: BorderSide(
              color: context.outlineColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: widget.isLoading ? _buildShimmerLoading() : _buildChipList(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: context.outlineColor.withValues(alpha: 0.3),
          highlightColor: context.formFieldBackground,
          child: Container(
            width: 120,
            height: 36,
            decoration: BoxDecoration(
              color: context.onSurfaceColor,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipList() {
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.suggestions.length + 1, // +1 for refresh button
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        // Last item is refresh button
        if (index == widget.suggestions.length) {
          return _buildRefreshButton();
        }

        final suggestion = widget.suggestions[index];
        return _buildDismissibleChip(suggestion);
      },
    );
  }

  Widget _buildDismissibleChip(String suggestion) {
    return Dismissible(
      key: ValueKey(suggestion),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        widget.onChipDismiss(suggestion);
        AppLogger.debug('Quick reply chip dismissed: $suggestion');
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(Icons.delete_outline, color: context.errorColor, size: 20),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_outline, color: context.errorColor, size: 20),
      ),
      child: _buildSuggestionChip(suggestion),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        widget.onChipTap(suggestion);
        AppLogger.debug('Quick reply chip tapped: $suggestion');
      },
      onLongPress: () {
        widget.onChipLongPress(suggestion);
        AppLogger.debug('Quick reply chip long pressed (send): $suggestion');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PulseColors.primary.withValues(alpha: 0.1),
              PulseColors.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: PulseColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: PulseColors.primary),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                suggestion,
                style: TextStyle(
                  color: PulseColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: widget.onRefresh,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: PulseColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: PulseColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: 20,
          color: PulseColors.primary,
        ),
      ),
    );
  }
}
