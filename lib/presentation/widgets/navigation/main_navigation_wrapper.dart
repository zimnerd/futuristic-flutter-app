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

  const MainNavigationWrapper({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _unreadMessageCount = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: LineIcons.compassAlt,
      activeIcon: LineIcons.compass,
      label: 'Discover',
      route: '/home',
    ),
    NavigationItem(
      icon: LineIcons.heartbeat,
      activeIcon: LineIcons.heartAlt,
      label: 'Sparks',
      route: '/matches',
    ),
    NavigationItem(
      icon: LineIcons.thLarge,
      activeIcon: LineIcons.thLarge,
      label: 'Explore',
      route: '/explore',
    ),
    NavigationItem(
      icon: LineIcons.calendarCheck,
      activeIcon: LineIcons.calendarAlt,
      label: 'Events',
      route: '/events',
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

    // Handle messages tab - mark conversations as read
    if (index == 4) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFF2C1810).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernNavItem(_navigationItems[0], 0),
                _buildModernNavItem(_navigationItems[1], 1),
                _buildModernNavItem(_navigationItems[2], 2),
                _buildModernNavItem(_navigationItems[3], 3),
                _buildModernNavItem(
                  _navigationItems[4],
                  4,
                  badgeCount: _unreadMessageCount,
                ),
                _buildModernNavItem(_navigationItems[5], 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavItem(
    NavigationItem item,
    int index, {
    int? badgeCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = index == widget.navigationShell.currentIndex;
    
    // Use theme colors for active state
    final activeColor = PulseColors.backgroundDark;
    final inactiveColor = isDark ? PulseColors.grey500 : PulseColors.grey400;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale =
            index == widget.navigationShell.currentIndex &&
                _animationController.isAnimating
            ? 1.0 - (_animationController.value * 0.05)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () => _onItemTapped(index),
            borderRadius: BorderRadius.circular(22),
            child: isActive
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          PulseColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.8),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(1.5), // Border width
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.activeIcon, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(item.icon, color: inactiveColor, size: 24),
                        if (badgeCount != null && badgeCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? PulseColors.surfaceDark
                                      : PulseColors.white,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
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