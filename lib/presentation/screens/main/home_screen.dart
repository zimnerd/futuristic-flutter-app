import 'package:flutter/material.dart';

/// Home screen - main discovery interface
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: const Center(
        child: Text('Home Screen - TODO: Implement'),
      ),
    );
  }
}
