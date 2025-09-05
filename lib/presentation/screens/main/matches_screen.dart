import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

/// Enhanced matches screen with swipe interface
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final PageController _pageController = PageController();

  // Mock data for demo
  final List<_MatchProfile> _profiles = [
    _MatchProfile(
      name: 'Emma',
      age: 24,
      bio: 'Love hiking and coffee ☕️',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
      distance: '2 km away',
    ),
    _MatchProfile(
      name: 'Sarah',
      age: 27,
      bio: 'Artist & yoga enthusiast 🧘‍♀️',
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
      distance: '5 km away',
    ),
    _MatchProfile(
      name: 'Maya',
      age: 22,
      bio: 'Photographer exploring the world 📸',
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      distance: '8 km away',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Card stack
            Expanded(
              child: _profiles.isEmpty ? _buildEmptyState() : _buildCardStack(),
            ),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Row(
        children: [
          Text(
            'Discover',
            style: PulseTextStyles.headlineLarge.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Open filters
            },
            icon: const Icon(Icons.tune),
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

  Widget _buildCardStack() {
    return Stack(
      children: [
        // Background cards for depth
        for (int i = _profiles.length - 1; i >= 0; i--)
          Positioned(
            left: PulseSpacing.lg + (i * 4.0),
            right: PulseSpacing.lg + (i * 4.0),
            top: i * 8.0,
            bottom: 120 + (i * 8.0),
            child: _buildProfileCard(_profiles[i], i),
          ),
      ],
    );
  }

  Widget _buildProfileCard(_MatchProfile profile, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: profile.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: PulseColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: PulseColors.surfaceVariant,
                  child: const Icon(Icons.person, size: 64),
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Profile info
            Positioned(
              bottom: PulseSpacing.xl,
              left: PulseSpacing.lg,
              right: PulseSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${profile.name}, ${profile.age}',
                        style: PulseTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: PulseSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PulseSpacing.sm,
                          vertical: PulseSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.success,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PulseSpacing.sm),
                  Text(
                    profile.bio,
                    style: PulseTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: PulseSpacing.sm),
                  Text(
                    profile.distance,
                    style: PulseTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _ActionButton(
            onPressed: () => _handleSwipe(false),
            icon: Icons.close,
            color: PulseColors.error,
            size: 56,
          ),

          // Super like button
          _ActionButton(
            onPressed: () => _handleSuperLike(),
            icon: Icons.star,
            color: PulseColors.warning,
            size: 48,
          ),

          // Like button
          _ActionButton(
            onPressed: () => _handleSwipe(true),
            icon: Icons.favorite,
            color: PulseColors.success,
            size: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: PulseColors.onSurfaceVariant,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'No more profiles',
            style: PulseTextStyles.headlineMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Check back later for new matches',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PulseSpacing.xl),
          PulseButton(
            text: 'Adjust Filters',
            onPressed: () {
              // TODO: Open filter settings
            },
            variant: PulseButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  void _handleSwipe(bool liked) {
    if (_profiles.isNotEmpty) {
      setState(() {
        _profiles.removeAt(0);
      });

      if (liked) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile liked! 💕'),
            backgroundColor: PulseColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _handleSuperLike() {
    if (_profiles.isNotEmpty) {
      setState(() {
        _profiles.removeAt(0);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Super liked! ⭐️'),
          backgroundColor: PulseColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.size,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(icon, color: color, size: size * 0.4),
        ),
      ),
    );
  }
}

class _MatchProfile {
  const _MatchProfile({
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrl,
    required this.distance,
  });

  final String name;
  final int age;
  final String bio;
  final String imageUrl;
  final String distance;
}
