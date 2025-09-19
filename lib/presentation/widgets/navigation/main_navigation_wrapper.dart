import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/pulse_design_system.dart';

/// Modern Main Navigation Wrapper with PulseLink Design
/// 
/// Inspired by fitness app tab design with:
/// - Curved, elevated bottom navigation
/// - Smooth animations and haptic feedback
/// - PulseLink brand colors and theming
/// - Burger menu integration
class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabController;
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department,
      label: 'Sparks',
      route: '/matches',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Events',
      route: '/events',
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'DMs',
      route: '/messages',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Navigate to the selected route
    context.go(_navigationItems[index].route);
  }

  void _onBurgerMenuTapped() {
    HapticFeedback.mediumImpact();
    _showBurgerMenu();
  }

  void _showBurgerMenu() {
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
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: _buildCurvedBottomBar(),
    );
  }

  Widget _buildCurvedBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: PulseColors.grey900,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: PulseColors.grey900.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCurvedNavItem(_navigationItems[0], 0),
              _buildCurvedNavItem(_navigationItems[1], 1),
              _buildCentralBurgerButton(),
              _buildCurvedNavItem(_navigationItems[2], 2),
              _buildCurvedNavItem(_navigationItems[3], 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedNavItem(NavigationItem item, int index) {
    final isActive = index == _currentIndex;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale = index == _currentIndex && _animationController.isAnimating
            ? 1.0 - (_animationController.value * 0.1)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () => _onItemTapped(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 50,
              height: 50,
              decoration: isActive
                  ? BoxDecoration(
                      color: PulseColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? PulseColors.white : PulseColors.grey400,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCentralBurgerButton() {
    return ScaleTransition(
      scale: _fabController,
      child: GestureDetector(
        onTap: _onBurgerMenuTapped,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: PulseColors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: PulseColors.grey800.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.menu_rounded, color: PulseColors.primary, size: 28),
        ),
      ),
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
                          Icons.apps_rounded,
                          color: PulseColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Menu',
                        style: PulseTypography.h3.copyWith(
                          color: PulseColors.white,
                          fontWeight: FontWeight.w600,
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
                            Icons.close_rounded,
                            color: PulseColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced Menu Items with better spacing
                Padding(
                  padding: const EdgeInsets.all(PulseSpacing.lg),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                      subtitle: 'Edit your profile',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/profile');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/settings');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.filter_list_rounded,
                      title: 'Filters',
                      subtitle: 'Discovery preferences',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/filters');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.psychology_outlined,
                      title: 'AI Companion',
                      subtitle: 'Your virtual dating coach',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/ai-companion');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.card_membership_outlined,
                      title: 'Premium',
                      subtitle: 'Unlock exclusive features',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/premium');
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.safety_check_outlined,
                      title: 'Safety Center',
                      subtitle: 'Privacy and safety',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/safety');
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(PulseBorderRadius.lg),
        border: Border.all(
          color: PulseColors.grey800.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PulseColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
          borderRadius: BorderRadius.circular(PulseBorderRadius.lg),
          splashColor: PulseColors.primary.withValues(alpha: 0.1),
          highlightColor: PulseColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PulseColors.primary.withValues(alpha: 0.2),
                        PulseColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(PulseBorderRadius.md),
                    border: Border.all(
                      color: PulseColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: PulseColors.primary,
                    size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PulseTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: PulseTypography.bodySmall.copyWith(
                          color: PulseColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PulseColors.grey800.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(PulseBorderRadius.sm),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
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