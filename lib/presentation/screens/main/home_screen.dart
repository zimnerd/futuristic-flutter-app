import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../data/services/discovery_service.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
import '../../blocs/filters/filter_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/responsive_filter_header.dart';
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
                    child: BlocProvider(
                      create: (context) => DiscoveryBloc(
                        discoveryService: DiscoveryService(
                          apiClient: ApiClient.instance,
                        ),
                      )..add(const LoadDiscoverableUsers()),
                      child: DiscoveryScreen(),
                    ),
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
      padding: const EdgeInsets.fromLTRB(
        PulseSpacing.lg,
        PulseSpacing.lg,
        PulseSpacing.lg,
        PulseSpacing.md,
      ),
      child: Row(
        children: [
          // Greeting - clean and minimal (no profile icon)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Ready to explore?',
                  style: PulseTextStyles.headlineSmall.copyWith(
                    color: PulseColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Filters button - more accessible and functional
          ResponsiveFilterHeader(
            showCompactView: true,
            backgroundColor: PulseColors.primaryContainer,
            foregroundColor: PulseColors.primary,
            onFiltersChanged: () {
              // Refresh discovery when filters change
              final discoveryBloc = context.read<DiscoveryBloc>();
              discoveryBloc.add(const LoadDiscoverableUsers(resetStack: true));
            },
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
              foregroundColor: PulseColors.onSurfaceVariant,
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
