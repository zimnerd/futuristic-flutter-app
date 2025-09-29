import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../data/services/discovery_service.dart';
import '../../../data/services/preferences_service.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
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
              child: BlocProvider(
                create: (context) => DiscoveryBloc(
                  discoveryService: DiscoveryService(
                    apiClient: ApiClient.instance,
                  ),
                  preferencesService: PreferencesService(ApiClient.instance),
                )..add(const LoadDiscoverableUsers()),
                child: const DiscoveryScreen(),
              ),
            ),
          );
        },
      ),
    );
  }
}
