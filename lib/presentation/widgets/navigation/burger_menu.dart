import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pulse_design_system.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

/// Modern burger menu with sliding drawer animation
/// Provides access to profile, settings, and other user features
class BurgerMenu extends StatefulWidget {
  const BurgerMenu({super.key});

  @override
  State<BurgerMenu> createState() => _BurgerMenuState();
}

class _BurgerMenuState extends State<BurgerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _navigateAndClose(String route) {
    _closeMenu();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Backdrop
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          
          // Menu content
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildMenuContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PulseColors.backgroundLight,
            PulseColors.surfaceLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            _buildMenuHeader(),
            
            // User profile section
            _buildUserSection(),
            
            // Menu items
            Expanded(
              child: _buildMenuItems(),
            ),
            
            // Footer
            _buildMenuFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menu',
            style: PulseTypography.h3.copyWith(
              color: PulseColors.grey800,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _closeMenu,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PulseColors.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.close,
                color: PulseColors.grey600,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        String displayName = 'User';
        if (state is UserProfileLoaded) {
          if (state.user.firstName?.isNotEmpty == true) {
            displayName = state.user.firstName!;
          } else if (state.user.username.isNotEmpty) {
            displayName = state.user.username;
          }
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PulseColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PulseColors.grey200,
            ),
            boxShadow: PulseShadows.card,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary,
                      PulseColors.accent,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: PulseTypography.h3.copyWith(
                      color: PulseColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: PulseTypography.bodyLarge.copyWith(
                        color: PulseColors.grey800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View Profile',
                      style: PulseTypography.bodySmall.copyWith(
                        color: PulseColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: PulseColors.grey500,
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      _MenuItem(
        icon: Icons.person,
        title: 'Profile',
        subtitle: 'Edit your profile',
        route: '/profile',
      ),
      _MenuItem(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'App preferences',
        route: '/settings',
      ),
      _MenuItem(
        icon: Icons.workspace_premium,
        title: 'Premium',
        subtitle: 'Upgrade your experience',
        route: '/subscription',
        isHighlighted: true,
      ),
      _MenuItem(
        icon: Icons.security,
        title: 'Safety',
        subtitle: 'Safety center',
        route: '/safety',
      ),
      _MenuItem(
        icon: Icons.filter_alt,
        title: 'Filters',
        subtitle: 'Discovery preferences',
        route: '/filters',
      ),
      _MenuItem(
        icon: Icons.map,
        title: 'Heat Map',
        subtitle: 'Activity visualization',
        route: '/heat-map',
      ),
      _MenuItem(
        icon: Icons.smart_toy,
        title: 'AI Companion',
        subtitle: 'Your virtual assistant',
        route: '/ai-companion',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItem(item, index);
      },
    );
  }

  Widget _buildMenuItem(_MenuItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateAndClose(item.route),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isHighlighted
                  ? PulseColors.primary.withValues(alpha: 0.1)
                  : PulseColors.grey50,
              borderRadius: BorderRadius.circular(16),
              border: item.isHighlighted
                  ? Border.all(
                      color: PulseColors.primary.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.isHighlighted
                        ? PulseColors.primary.withValues(alpha: 0.2)
                        : PulseColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.isHighlighted
                        ? PulseColors.primary
                        : PulseColors.grey600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: PulseTypography.bodyLarge.copyWith(
                          color: item.isHighlighted
                              ? PulseColors.primary
                              : PulseColors.grey800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: PulseTypography.bodySmall.copyWith(
                            color: PulseColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: PulseColors.grey500,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // App version
          Text(
            'PulseLink v1.0.0',
            style: PulseTypography.bodySmall.copyWith(
              color: PulseColors.grey500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Sign out button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                // Show confirmation dialog
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (shouldSignOut == true && mounted) {
                  // Trigger sign out event
                  context.read<AuthBloc>().add(const AuthSignOutRequested());
                  _closeMenu();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PulseColors.reject.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout,
                      color: PulseColors.reject,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: PulseTypography.bodyMedium.copyWith(
                        color: PulseColors.reject,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu item data class
class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;
  final bool isHighlighted;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.route,
    this.isHighlighted = false,
  });
}