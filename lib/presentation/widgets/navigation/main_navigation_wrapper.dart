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
                      color: activeColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
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
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Satoshi',
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
    return Container(
      margin: const EdgeInsets.all(PulseSpacing.lg),
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height *
            0.7, // Limit height to prevent overflow
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseBorderRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PulseColors.surfaceLight,
                PulseColors.surfaceLight.withValues(alpha: 0.98),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(PulseBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: PulseColors.primary.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: PulseColors.grey800.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Header with gradient
                Container(
                  padding: const EdgeInsets.all(PulseSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PulseColors.primary, PulseColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(PulseBorderRadius.xl),
                      topRight: Radius.circular(PulseBorderRadius.xl),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Menu icon with background
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PulseColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            PulseBorderRadius.sm,
                          ),
                        ),
                        child: Icon(
                          LineIcons.thLarge,
                          color: PulseColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Menu',
                        style: PulseTypography.h3.copyWith(
                          color: PulseColors.white,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: PulseColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            PulseBorderRadius.sm,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            LineIcons.times,
                            color: PulseColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced Menu Items with optimized spacing
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PulseSpacing.lg,
                    vertical: PulseSpacing.sm, // Reduced vertical padding
                  ),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        icon: LineIcons.user,
                        title: 'Profile',
                      subtitle: 'Edit your profile',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/profile');
                      },
                    ),
                    _buildMenuTile(
                        icon: LineIcons.cog,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/settings');
                      },
                    ),
                    _buildMenuTile(
                        icon: LineIcons.filter,
                      title: 'Filters',
                      subtitle: 'Discovery preferences',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/filters');
                      },
                    ),
                    _buildMenuTile(
                        icon: LineIcons.barChart,
                        title: 'Statistics',
                        subtitle: 'Your dating insights',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/statistics');
                        },
                      ),
                      _buildMenuTile(
                        icon: LineIcons.robot,
                      title: 'AI Companion',
                      subtitle: 'Your virtual dating coach',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/ai-companion');
                      },
                    ),
                    _buildMenuTile(
                        icon: LineIcons.crown,
                      title: 'Premium',
                      subtitle: 'Unlock exclusive features',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/premium');
                      },
                    ),
                    _buildMenuTile(
                        icon: LineIcons.userShield,
                      title: 'Safety Center',
                      subtitle: 'Privacy and safety',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/safety');
                      },
                    ),
                      const SizedBox(height: PulseSpacing.sm),
                      // Divider before logout
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Divider(
                          color: PulseColors.grey600.withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                      const SizedBox(height: PulseSpacing.xs),
                      // Logout option
                      _buildMenuTile(
                        icon: LineIcons.alternateSignOut,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        onTap: () {
                          Navigator.of(context).pop();
                          _showLogoutConfirmation();
                        },
                      ),
                    ], // Close children array
                  ), // Close Column
                ), // Close Padding
              ], // Close children array for main Column
            ), // Close main Column
          ), // Close SingleChildScrollView
        ), // Close inner Container
      ), // Close ClipRRect
    ); // Close outer Container and return statement
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 4,
      ), // Reduced margins
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF3A1F15),
          ], // Warmer brown-burgundy tones
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(
          PulseBorderRadius.md,
        ), // Slightly smaller radius
        border: Border.all(
          color: PulseColors.primary.withValues(
            alpha: 0.2,
          ), // Warmer border using primary color
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PulseColors.primary.withValues(alpha: 0.1),
            blurRadius: 6, // Reduced shadow
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(PulseBorderRadius.md),
          splashColor: PulseColors.primary.withValues(alpha: 0.1),
          highlightColor: PulseColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
            child: Row(
              children: [
                Container(
                  width: 40, // Reduced from 50 to 40
                  height: 40, // Reduced from 50 to 40
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PulseColors.primary.withValues(alpha: 0.2),
                        PulseColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(PulseBorderRadius.sm),
                    border: Border.all(
                      color: PulseColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: PulseColors.primary,
                    size: 20,
                  ), // Reduced from 24 to 20
                ),
                const SizedBox(width: 12), // Reduced from 16 to 12
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PulseTypography.bodyMedium.copyWith(
                          // Changed from bodyLarge
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Satoshi',
                          color: Colors.white,
                        ),
                      ),
                      // Removed the SizedBox to save space
                      Text(
                        subtitle,
                        style: PulseTypography.bodySmall.copyWith(
                          color: PulseColors.grey400,
                          fontSize: 12, // Made slightly smaller
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24, // Reduced from 32 to 24
                  height: 24, // Reduced from 32 to 24
                  decoration: BoxDecoration(
                    color: Color(
                      0xFF4A2B1A,
                    ).withValues(alpha: 0.7), // Warmer background
                    borderRadius: BorderRadius.circular(PulseBorderRadius.sm),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12, // Reduced from 14 to 12
                    color: PulseColors.grey400,
                  ),
                ),
              ],
            ),
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
                fontFamily: 'Satoshi',
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
                fontFamily: 'Satoshi',
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
                fontFamily: 'Satoshi',
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