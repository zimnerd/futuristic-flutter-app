import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/network/api_client.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

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

    // Handle profile tab specially - show menu options
    if (index == 4) {
      _showProfileMenu();
      return;
    }

    // Handle messages tab - mark conversations as read
    if (index == 3) {
      _markAllConversationsAsRead();
    }

    // Use navigationShell.goBranch for tab switching (preserves state)
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _showProfileMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBurgerMenu(),
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
                _buildModernNavItem(
                  _navigationItems[3],
                  3,
                  badgeCount: _unreadMessageCount,
                ),
                _buildModernNavItem(_navigationItems[4], 4),
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

  Widget _buildBurgerMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? PulseColors.surfaceDark : PulseColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PulseColors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PulseColors.primary, PulseColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(LineIcons.thLarge, color: PulseColors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Menu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    LineIcons.times,
                    color: PulseColors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Menu items - full width with line dividers
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSimpleMenuTile(
                    icon: LineIcons.user,
                    title: 'Profile',
                    subtitle: 'Edit your profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/profile');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.cog,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.filter,
                    title: 'Filters',
                    subtitle: 'Discovery preferences',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/filters');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.barChart,
                    title: 'Statistics',
                    subtitle: 'Your dating insights',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/statistics');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.history,
                    title: 'Call History',
                    subtitle: 'View past calls',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/call-history');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.robot,
                    title: 'AI Companion',
                    subtitle: 'Your virtual dating coach',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/ai-companion');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.crown,
                    title: 'Premium',
                    subtitle: 'Unlock exclusive features',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/premium');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.userShield,
                    title: 'Safety Center',
                    subtitle: 'Privacy and safety',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/safety');
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(),
                  _buildSimpleMenuTile(
                    icon: LineIcons.alternateSignOut,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showLogoutConfirmation();
                    },
                    isDark: isDark,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: PulseColors.grey300.withValues(alpha: 0.3),
      indent: 0,
      endIndent: 0,
    );
  }

  Widget _buildSimpleMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive
        ? PulseColors.reject
        : (isDark ? PulseColors.white : PulseColors.grey900);
    final iconColor = isDestructive ? PulseColors.reject : PulseColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? PulseColors.grey400
                            : PulseColors.grey600,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? PulseColors.grey500 : PulseColors.grey400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PulseColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseBorderRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PulseColors.reject.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(PulseBorderRadius.sm),
              ),
              child: Icon(
                LineIcons.exclamationTriangle,
                color: PulseColors.reject,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: PulseTypography.h3.copyWith(
                color: PulseColors.grey900,
                fontWeight: FontWeight.w300,
                
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You\'ll need to sign in again to access your account.',
          style: PulseTypography.bodyMedium.copyWith(
            color: PulseColors.grey600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: PulseColors.grey600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: PulseTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w300,
                
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              // Trigger proper logout through AuthBloc
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.reject,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseBorderRadius.sm),
              ),
            ),
            child: Text(
              'Logout',
              style: PulseTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w300,
                
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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