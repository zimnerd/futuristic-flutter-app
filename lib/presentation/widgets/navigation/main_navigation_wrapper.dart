import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/network/api_client.dart';

/// Modern Main Navigation Wrapper with PulseLink Design
///
/// Clean, minimal navigation bar with:
/// - 5 horizontal tabs (Home, Search, Recent, Messages, Profile)
/// - Purple pill styling for active tab with label text
/// - Smooth animations and haptic feedback
/// - Dark/light mode support
/// - Active tab shows icon + label, inactive shows icon only
/// - Profile tab opens menu modal
/// - StatefulShellRoute integration for tab state preservation
class MainNavigationWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationWrapper({super.key, required this.navigationShell});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _unreadMessageCount = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: LineIcons.compass,
      activeIcon: LineIcons.compassAlt,
      label: 'Discover',
      route: '/home',
    ),
    NavigationItem(
      icon: LineIcons.heart,
      activeIcon: LineIcons.heartAlt,
      label: 'Sparks',
      route: '/matches',
    ),
    NavigationItem(
      icon: LineIcons.bars,
      activeIcon: LineIcons.bars,
      label: 'Explore',
      route: '/explore',
    ),
    NavigationItem(
      icon: LineIcons.comment,
      activeIcon: LineIcons.commentDotsAlt,
      label: 'Messages',
      route: '/messages',
    ),
    NavigationItem(
      icon: LineIcons.user,
      activeIcon: LineIcons.userAlt,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _loadUnreadMessageCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh unread count when app comes to foreground
    _loadUnreadMessageCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final response = await ApiClient.instance.getUnreadMessageCount();
      if (response.statusCode == 200 && response.data != null) {
        final count = response.data['count'] ?? 0;
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      // Handle error silently, keep current count
    }
  }

  Future<void> _markAllConversationsAsRead() async {
    try {
      // Call API to mark all conversations as read
      await ApiClient.instance.markAllConversationsAsRead();
      // Refresh the count after marking as read
      await _loadUnreadMessageCount();
    } catch (e) {
      // Handle error silently
    }
  }

  void _onItemTapped(int index) {
    // Prevent unnecessary navigation if already on the tab
    if (widget.navigationShell.currentIndex == index) {
      return;
    }

    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Handle messages tab (index 3) - mark conversations as read
    if (index == 3) {
      _markAllConversationsAsRead();
    }

    // Use navigationShell.goBranch for tab switching (preserves state)
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: _buildCurvedBottomBar(),
    );
  }

  Widget _buildCurvedBottomBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(_navigationItems[0], 0),
            _buildNavItem(_navigationItems[1], 1),
            _buildNavItem(_navigationItems[2], 2),
            _buildNavItem(
              _navigationItems[3],
              3,
              badgeCount: _unreadMessageCount,
            ),
            _buildNavItem(_navigationItems[4], 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    NavigationItem item,
    int index, {
    int? badgeCount,
  }) {
    final isActive = index == widget.navigationShell.currentIndex;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale =
            index == widget.navigationShell.currentIndex &&
                _animationController.isAnimating
            ? 1.0 - (_animationController.value * 0.08)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Expanded(
            child: InkWell(
              onTap: () => _onItemTapped(index),
              borderRadius: BorderRadius.circular(8),
              splashColor: PulseColors.primary.withValues(alpha: 0.1),
              highlightColor: PulseColors.primary.withValues(alpha: 0.05),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? PulseColors.primary
                              : const Color(0xFF999999),
                          size: 24,
                        ),
                        if (badgeCount != null && badgeCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isActive
                            ? PulseColors.primary
                            : const Color(0xFF999999),
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int? badgeCount;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badgeCount,
  });
}
