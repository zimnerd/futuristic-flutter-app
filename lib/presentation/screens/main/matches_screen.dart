import 'package:flutter/material.dart';

/// Matches screen - show user matches
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
      body: const Center(
        child: Text('Matches Screen - TODO: Implement'),
      ),
    );
  }
}
