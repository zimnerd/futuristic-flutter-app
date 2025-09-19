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
      bottomNavigationBar: _buildModernBottomBar(),
      floatingActionButton: _buildBurgerMenuFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildModernBottomBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: PulseColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: PulseColors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ..._navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = index == _currentIndex;

                return Expanded(
                  child: _buildNavigationItem(item, index, isActive),
                );
              }),
              // Space for FAB
              const SizedBox(width: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item, int index, bool isActive) {
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
            borderRadius: BorderRadius.circular(PulseBorderRadius.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: PulseSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with active indicator
                  Container(
                    width: 28,
                    height: 28,
                    decoration: isActive
                        ? BoxDecoration(
                            color: PulseColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(PulseBorderRadius.sm),
                          )
                        : null,
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive ? PulseColors.primary : PulseColors.grey600,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: PulseTypography.labelSmall.copyWith(
                      color: isActive ? PulseColors.primary : PulseColors.grey600,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBurgerMenuFAB() {
    return ScaleTransition(
      scale: _fabController,
      child: FloatingActionButton(
        onPressed: _onBurgerMenuTapped,
        backgroundColor: PulseColors.primary,
        foregroundColor: PulseColors.white,
        elevation: 8,
        child: const Icon(
          Icons.menu_rounded,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBurgerMenu() {
    return Container(
      margin: const EdgeInsets.all(PulseSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseBorderRadius.xl),
        child: Container(
          decoration: PulseDecorations.glassmorphism(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(PulseSpacing.lg),
                decoration: BoxDecoration(
                  gradient: PulseGradients.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(PulseBorderRadius.xl),
                    topRight: Radius.circular(PulseBorderRadius.xl),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Menu',
                      style: PulseTypography.h3.copyWith(
                        color: PulseColors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: PulseColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Padding(
                padding: const EdgeInsets.all(PulseSpacing.md),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(PulseBorderRadius.md),
          ),
          child: Icon(
            icon,
            color: PulseColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: PulseTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: PulseTypography.bodySmall.copyWith(
            color: PulseColors.grey600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: PulseColors.grey600,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseBorderRadius.md),
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