import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/swipeable_profile_card.dart' as swipe_widget;
import '../../blocs/matching/matching_bloc.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';

/// Enhanced matches screen with swipeable cards and modern UI
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late AnimationController _matchAnimationController;
  
  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Load initial matches
    context.read<MatchingBloc>().add(const LoadPotentialMatches());
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _matchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MatchingBloc, MatchingState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }

            if (state.lastSwipeWasMatch && state.matchedProfile != null) {
              _showMatchDialog(state.matchedProfile!);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header with stats
                _buildHeader(state),

                // Card stack
                Expanded(
                  child: _buildContent(state)),

                // Action buttons
                if (state.profiles.isNotEmpty) _buildActionButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(MatchingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${state.profiles.length} profiles nearby',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),
          // Filters button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: PulseColors.primary),
              onPressed: () => _showFiltersDialog(),
            ),
          ),
          const SizedBox(width: 8),
          // Super likes remaining
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PulseColors.primary, PulseColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${state.superLikesRemaining}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MatchingState state) {
    if (state.status == MatchingStatus.loading && state.profiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.profiles.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Stack of profile cards
        for (int i = state.profiles.length - 1; i >= 0; i--)
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.only(
                top: i * 8.0,
                left: i * 4.0,
                right: i * 4.0,
              ),
              child: _buildProfileCard(state.profiles[i], i),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileCard(UserProfile profile, int index) {
    return swipe_widget.SwipeableProfileCard(
      profile: swipe_widget.ProfileCardData(
        id: profile.id,
        name: profile.name,
        age: profile.age,
        bio: profile.bio,
        imageUrl: profile.primaryPhotoUrl,
        distance: profile.distanceString,
        isVerified: profile.isVerified,
        photoCount: profile.photos.length,
        interests: profile.interests,
      ),
      onSwipe: (direction) {
        HapticFeedback.lightImpact();
        // Convert widget SwipeDirection to bloc SwipeAction
        SwipeAction blocDirection;
        switch (direction) {
          case swipe_widget.SwipeDirection.left:
            blocDirection = SwipeAction.left;
            break;
          case swipe_widget.SwipeDirection.right:
            blocDirection = SwipeAction.right;
            break;
          case swipe_widget.SwipeDirection.up:
            blocDirection = SwipeAction.up;
            break;
        }
        
        context.read<MatchingBloc>().add(
          SwipeProfile(profileId: profile.id, direction: blocDirection),
        );
      },
      onTap: () {
        _showProfileDetails(profile);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_outline,
              size: 60,
              color: PulseColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No more profiles',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new matches',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.read<MatchingBloc>().add(const RefreshMatches());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo button
          _buildActionButton(
            icon: Icons.undo,
            color: Colors.grey[400]!,
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<MatchingBloc>().add(const UndoLastSwipe());
            },
          ),
          
          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red[400]!,
            onPressed: () => _handleSwipe(SwipeAction.left),
            size: 56,
          ),
          
          // Super like button
          _buildActionButton(
            icon: Icons.star,
            color: PulseColors.secondary,
            onPressed: () => _handleSuperLike(),
          ),
          
          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.green[400]!,
            onPressed: () => _handleSwipe(SwipeAction.right),
            size: 56,
          ),
          
          // Boost button
          _buildActionButton(
            icon: Icons.flash_on,
            color: PulseColors.primary,
            onPressed: () => _showBoostDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.4),
        onPressed: onPressed,
      ),
    );
  }

  void _handleSwipe(SwipeAction direction) {
    final state = context.read<MatchingBloc>().state;
    if (state.profiles.isNotEmpty) {
      HapticFeedback.lightImpact();
      context.read<MatchingBloc>().add(
        SwipeProfile(profileId: state.profiles.first.id, direction: direction),
      );
    }
  }

  void _handleSuperLike() {
    final state = context.read<MatchingBloc>().state;
    if (state.profiles.isNotEmpty) {
      HapticFeedback.mediumImpact();
      context.read<MatchingBloc>().add(
        SuperLikeProfile(profileId: state.profiles.first.id),
      );
    }
  }

  void _showMatchDialog(UserProfile matchedProfile) {
    _matchAnimationController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PulseColors.primary, PulseColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It's a Match!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: matchedProfile.photos.isNotEmpty
                        ? CachedNetworkImageProvider(
                            matchedProfile.photos.first.url,
                          )
                        : null,
                    child: matchedProfile.photos.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const Icon(Icons.favorite, color: Colors.white, size: 40),
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(
                      'assets/images/current_user.jpg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'You and ${matchedProfile.name} liked each other!',
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keep Swiping'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to chat
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: PulseColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Say Hello'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Filters'),
        content: const Text('Filter options will be available here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBoostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Boost Your Profile'),
        content: const Text('Boost feature will be available here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Age: ${profile.age}',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(profile.bio, style: const TextStyle(fontSize: 16)),
                    // Add more profile details here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
