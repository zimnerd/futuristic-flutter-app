import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_state.dart';
import '../../theme/pulse_colors.dart';
import '../discovery/discovery_screen.dart';

/// Modern home screen with tab navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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

                  // Discovery content
                  Expanded(
                    child: DiscoveryScreen(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
              // Show notifications screen/modal
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  height: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: const [
                            ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.favorite),
                              ),
                              title: Text('You have a new match!'),
                              subtitle: Text('Sarah liked your profile'),
                              trailing: Text('5m ago'),
                            ),
                            ListTile(
                              leading: CircleAvatar(child: Icon(Icons.message)),
                              title: Text('New message'),
                              subtitle: Text('Hey! How are you doing?'),
                              trailing: Text('1h ago'),
                            ),
                            ListTile(
                              leading: CircleAvatar(child: Icon(Icons.event)),
                              title: Text('Date reminder'),
                              subtitle: Text(
                                'Your coffee date is tomorrow at 3pm',
                              ),
                              trailing: Text('2h ago'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
