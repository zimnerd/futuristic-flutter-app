import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import '../../../core/theme/pulse_design_system.dart';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 70,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModernNavItem(_navigationItems[0], 0),
              _buildModernNavItem(_navigationItems[1], 1),
              _buildModernNavItem(_navigationItems[2], 2),
              _buildModernNavItem(_navigationItems[3], 3),
              _buildModernNavItem(_navigationItems[4], 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavItem(NavigationItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = index == widget.navigationShell.currentIndex;
    
    // Use theme colors for active state
    final activeColor = PulseColors.primary;
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
            borderRadius: BorderRadius.circular(25),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: 10,
              ),
              decoration: isActive
                  ? BoxDecoration(
                      color: activeColor.withValues(alpha: 0.01),
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? Colors.white : inactiveColor,
                    size: 24,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        
                      ),
                    ),
                  ],
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
              // Logout functionality ready
              // TODO: Integrate with AuthService/TokenService to clear auth state
              // Example: await TokenService.clearTokens();
              context.go('/welcome');
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

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}