import 'package:flutter/material.dart';

/// Profile screen - user's own profile
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text('Profile Screen - TODO: Implement'),
      ),
    );
  }
}
