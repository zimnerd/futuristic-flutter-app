import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_state.dart';
import '../../theme/pulse_colors.dart';
import '../main/matches_screen.dart';
import '../main/messages_screen.dart';
import '../main/profile_screen.dart';

/// Modern home screen with tab navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [PulseColors.surface, PulseColors.surfaceVariant],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom header
                  _buildHeader(context, state),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        MatchesScreen(),
                        MessagesScreen(),
                        ProfileScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // Custom bottom navigation
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(BuildContext context, UserState state) {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: PulseColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: PulseSpacing.md),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: PulseTextStyles.bodySmall.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Welcome!',
                  style: PulseTextStyles.headlineSmall.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Notification button
          IconButton(
            onPressed: () {
              // TODO: Show notifications
            },
            icon: const Icon(Icons.notifications_outlined),
            style: IconButton.styleFrom(
              backgroundColor: PulseColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      _NavItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Matches',
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PulseSpacing.lg,
            vertical: PulseSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == _currentIndex;

              return GestureDetector(
                onTap: () {
                  _tabController.animateTo(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PulseSpacing.md,
                    vertical: PulseSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? PulseColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(PulseRadii.lg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? PulseColors.primary
                            : PulseColors.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: PulseSpacing.xs),
                      Text(
                        item.label,
                        style: PulseTextStyles.labelSmall.copyWith(
                          color: isActive
                              ? PulseColors.primary
                              : PulseColors.onSurfaceVariant,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
