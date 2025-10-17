import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../data/models/premium.dart';
import '../../../domain/entities/user_profile.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../../blocs/premium/premium_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../widgets/common/robust_network_image.dart';

/// Profile Viewers Screen - Premium Feature
/// 
/// Displays users who have viewed the current user's profile in a grid layout.
/// Features:
/// - 2-column grid of viewer cards
/// - Sorted by most recent first
/// - Tap to view full profile
/// - Empty state when no viewers
/// - Loading state with shimmer effect
/// - Premium subscription required
class ProfileViewersScreen extends StatefulWidget {
  const ProfileViewersScreen({super.key});

  @override
  State<ProfileViewersScreen> createState() => _ProfileViewersScreenState();
}

class _ProfileViewersScreenState extends State<ProfileViewersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Check premium access for this feature
    context.read<PremiumBloc>().add(
          const CheckFeatureAccess(PremiumFeatureType.profileViewers),
        );
    _loadProfileViewers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProfileViewers() {
    context.read<ProfileBloc>().add(const LoadProfileViewers(limit: 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Viewed You'),
        backgroundColor: PulseColors.backgroundLight,
        elevation: 0,
      ),
      body: BlocBuilder<PremiumBloc, PremiumState>(
        builder: (context, premiumState) {
          // Check if premium access check is complete
          if (premiumState is PremiumFeatureAccessResult &&
              premiumState.feature == PremiumFeatureType.profileViewers.name) {
            // User doesn't have premium access
            if (!premiumState.hasAccess) {
              return _buildPremiumUpsell();
            }
          }

          // User has premium access or check is still in progress
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              // Check viewers-specific status
              if (state.viewersStatus == ProfileStatus.loading) {
                return _buildLoadingGrid();
              }

              if (state.viewersStatus == ProfileStatus.loaded) {
                if (state.viewers.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildViewersGrid(state.viewers, state.viewersTotalCount);
              }

              if (state.viewersStatus == ProfileStatus.error) {
                return _buildErrorState(state.error ?? 'Failed to load viewers');
              }

              return _buildEmptyState();
            },
          );
        },
      ),
    );
  }

  Widget _buildViewersGrid(List<UserProfile> viewers, int totalCount) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadProfileViewers();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: Column(
        children: [
          // Total count header
          Container(
            padding: const EdgeInsets.all(16),
            color: PulseColors.backgroundLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility,
                  size: 20,
                  color: PulseColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalCount ${totalCount == 1 ? 'person has' : 'people have'} viewed your profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PulseColors.grey900,
                      ),
                ),
              ],
            ),
          ),

          // Grid of viewers
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: viewers.length,
              itemBuilder: (context, index) {
                return _ViewerGridCard(
                  user: viewers[index],
                  onTap: () {
                    context.push('/profile/${viewers[index].id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const _LoadingCard();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No profile views yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your profile and stay active to get more views!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProfileViewers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpsell() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium crown icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PulseColors.primary,
                    PulseColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Premium Feature',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PulseColors.grey900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'See Who Viewed Your Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: PulseColors.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to premium to see who\'s checking you out and boost your matches!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: PulseColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Features list
            _buildFeatureItem(Icons.visibility, 'See who viewed your profile'),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.favorite, 'See who liked you'),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.bolt, 'Unlimited likes & super likes'),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.filter_alt, 'Advanced filters'),
            
            const SizedBox(height: 40),
            
            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/premium');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Upgrade to Premium',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Maybe later button
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: PulseColors.grey600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: PulseColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: PulseColors.grey800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Icon(
          Icons.check_circle,
          size: 20,
          color: PulseColors.primary,
        ),
      ],
    );
  }
}

/// Viewer Grid Card Widget
class _ViewerGridCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _ViewerGridCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Profile photo
              RobustNetworkImage(
                imageUrl: user.primaryPhotoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // User info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.nameWithAge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified)
                          const Icon(
                            Icons.verified,
                            color: PulseColors.accent,
                            size: 18,
                          ),
                      ],
                    ),
                    if (user.distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.distanceString,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading Card with Shimmer Effect
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
