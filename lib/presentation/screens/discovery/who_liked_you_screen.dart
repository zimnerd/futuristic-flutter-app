import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../../domain/entities/user_profile.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
import '../../blocs/discovery/discovery_state.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../../blocs/premium/premium_state.dart';
import '../../widgets/common/robust_network_image.dart';
import '../../widgets/verification/verification_badge.dart';

/// Who Liked You Screen - Premium Feature
///
/// Displays users who have liked the current user in a grid layout.
/// Features:
/// - 2-column grid of user cards with blur effect for free users
/// - Profile cards with photo, name, age, location
/// - Premium gate with upgrade prompt
/// - Filter options (All, Recent 24h, Verified Only, Super Likes)
/// - Empty state when no one has liked you
/// - Pull-to-refresh functionality
/// - Loading skeleton while fetching
/// - Action buttons for premium users (like back, view profile)
class WhoLikedYouScreen extends StatefulWidget {
  const WhoLikedYouScreen({super.key});

  @override
  State<WhoLikedYouScreen> createState() => _WhoLikedYouScreenState();
}

class _WhoLikedYouScreenState extends State<WhoLikedYouScreen> {
  WhoLikedYouFilter _currentFilter = WhoLikedYouFilter.all;
  bool _verifiedOnly = false;
  bool _superLikesOnly = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Refresh premium status to ensure we have the latest subscription data
    context.read<PremiumBloc>().add(LoadPremiumData());
    _loadWhoLikedYou();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadWhoLikedYou() {
    context.read<DiscoveryBloc>().add(
      LoadWhoLikedYou(filters: DiscoveryFilters(verifiedOnly: _verifiedOnly)),
    );
  }

  bool _isPremiumUser(BuildContext context) {
    final premiumState = context.watch<PremiumBloc>().state;
    print('🔍 WHO_LIKED_YOU: Premium state type: ${premiumState.runtimeType}');
    
    if (premiumState is PremiumLoaded) {
      final hasSubscription = premiumState.subscription != null;
      final isActive = premiumState.subscription?.isActive ?? false;
      print(
        '🎫 WHO_LIKED_YOU: HasSubscription: $hasSubscription, IsActive: $isActive',
      );

      if (hasSubscription) {
        print(
          '📋 WHO_LIKED_YOU: Subscription - ID: ${premiumState.subscription!.id}, Status: ${premiumState.subscription!.status}',
        );
      }
      
      return isActive;
    }

    print(
      '⚠️  WHO_LIKED_YOU: Premium state is NOT PremiumLoaded, returning false',
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _isPremiumUser(context);

    return Scaffold(
      backgroundColor: PulseColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Who Liked You'),
        backgroundColor: PulseColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _currentFilter != WhoLikedYouFilter.all,
              label: const Text('!'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilters,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading) {
            return _buildLoadingGrid();
          }

          if (state is DiscoveryEmpty) {
            return _buildEmptyState();
          }

          if (state is DiscoveryError) {
            return _buildErrorState(state.message);
          }

          if (state is DiscoveryLoaded) {
            if (state.userStack.isEmpty) {
              return _buildEmptyState();
            }
            return _buildUserGrid(state.userStack, isPremium);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildUserGrid(List<UserProfile> users, bool isPremium) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadWhoLikedYou();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),

          // Grid of users
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
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _UserGridCard(
                  user: users[index],
                  isPremium: isPremium,
                  onTap: () {
                    if (isPremium) {
                      // Navigate to profile view
                      context.push('/profile/${users[index].id}');
                    } else {
                      // Show premium upgrade prompt
                      _showPremiumPrompt();
                    }
                  },
                  onLikeBack: isPremium ? () => _likeBack(users[index]) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PulseColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterTab(label: 'All', filter: WhoLikedYouFilter.all),
          _buildFilterTab(label: 'Recent', filter: WhoLikedYouFilter.recent24h),
          _buildFilterTab(
            label: 'Verified',
            filter: WhoLikedYouFilter.verifiedOnly,
          ),
          _buildFilterTab(
            label: 'Super',
            filter: WhoLikedYouFilter.superLikes,
            icon: Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required WhoLikedYouFilter filter,
    IconData? icon,
  }) {
    final isSelected = _currentFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentFilter = filter;
            _verifiedOnly = filter == WhoLikedYouFilter.verifiedOnly;
            _superLikesOnly = filter == WhoLikedYouFilter.superLikes;
          });
          _loadWhoLikedYou();
        },
        child: AnimatedContainer(
          duration: PulseAnimations.fast,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? PulseColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? PulseColors.primary : PulseColors.grey600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: PulseTypography.labelMedium.copyWith(
                  color: isSelected ? PulseColors.primary : PulseColors.grey600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    PulseColors.primary.withValues(alpha: 0.1),
                    PulseColors.accent.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: PulseColors.grey400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No one has liked you yet',
              style: PulseTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Keep swiping and someone will like you soon!',
              style: PulseTypography.bodyLarge.copyWith(
                color: PulseColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.explore),
              label: const Text('Start Swiping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: PulseColors.white,
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
            Icon(Icons.error_outline, size: 80, color: PulseColors.error),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: PulseTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: PulseTypography.bodyLarge.copyWith(
                color: PulseColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadWhoLikedYou,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: PulseColors.white,
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

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        verifiedOnly: _verifiedOnly,
        superLikesOnly: _superLikesOnly,
        onApply: (verified, superLikes) {
          setState(() {
            _verifiedOnly = verified;
            _superLikesOnly = superLikes;

            // Update filter based on selections
            if (superLikes) {
              _currentFilter = WhoLikedYouFilter.superLikes;
            } else if (verified) {
              _currentFilter = WhoLikedYouFilter.verifiedOnly;
            } else {
              _currentFilter = WhoLikedYouFilter.all;
            }
          });
          _loadWhoLikedYou();
        },
      ),
    );
  }

  void _showPremiumPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: PulseColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PulseGradients.primary,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 40,
                  color: PulseColors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Unlock Who Liked You',
                style: PulseTypography.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PulseColors.grey900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Upgrade to Premium to see who liked you and match instantly!',
                style: PulseTypography.bodyLarge.copyWith(
                  color: PulseColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Premium features
              _buildPremiumFeature(
                icon: Icons.visibility,
                title: 'See Who Likes You',
                description: 'View all profiles of people who liked you',
              ),
              const SizedBox(height: 16),
              _buildPremiumFeature(
                icon: Icons.bolt,
                title: 'Instant Matches',
                description: 'Like them back for instant matches',
              ),
              const SizedBox(height: 16),
              _buildPremiumFeature(
                icon: Icons.filter_alt,
                title: 'Advanced Filters',
                description: 'Filter by verified users and super likes',
              ),
              const SizedBox(height: 32),

              // Upgrade button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/premium');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: PulseColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: PulseColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PulseTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PulseColors.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: PulseTypography.bodyMedium.copyWith(
                  color: PulseColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _likeBack(UserProfile user) {
    // Like the user back
    context.read<DiscoveryBloc>().add(SwipeRight(user));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liked ${user.name} back!'),
        backgroundColor: PulseColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reload the list
    _loadWhoLikedYou();
  }
}

/// User Grid Card - Displays user photo and basic info
class _UserGridCard extends StatelessWidget {
  const _UserGridCard({
    required this.user,
    required this.isPremium,
    required this.onTap,
    this.onLikeBack,
  });

  final UserProfile user;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback? onLikeBack;

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
              // User photo
              RobustNetworkImage(
                imageUrl: user.primaryPhotoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: Container(
                  color: PulseColors.grey300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: Container(
                  color: PulseColors.grey300,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: PulseColors.white,
                  ),
                ),
              ),

              // Blur effect for non-premium users
              if (!isPremium)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
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
                        Colors.black.withValues(alpha: isPremium ? 0.8 : 0.5),
                      ],
                    ),
                  ),
                ),
              ),

              // Premium upgrade overlay
              if (!isPremium)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PulseColors.primary.withValues(alpha: 0.3),
                          PulseColors.primary.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PulseColors.white.withValues(alpha: 0.9),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: PulseColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PulseColors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Upgrade to see',
                            style: PulseTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: PulseColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // User info (always visible but blurred for non-premium)
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
                            isPremium ? user.nameWithAge : '•••',
                            style: const TextStyle(
                              color: PulseColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium)
                          VerificationBadge(
                            isVerified: user.isVerified,
                            size: VerificationBadgeSize.small,
                          ),
                      ],
                    ),
                    if (user.distanceKm != null && isPremium) ...[
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

              // Like back button (premium only)
              if (isPremium && onLikeBack != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      onLikeBack?.call();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: PulseColors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: PulseColors.success,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading Card - Shimmer placeholder
class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: PulseColors.grey200,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value, 0),
                colors: [
                  PulseColors.grey200,
                  PulseColors.grey300,
                  PulseColors.grey200,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Filter Bottom Sheet
class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.verifiedOnly,
    required this.superLikesOnly,
    required this.onApply,
  });

  final bool verifiedOnly;
  final bool superLikesOnly;
  final Function(bool verifiedOnly, bool superLikesOnly) onApply;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late bool _verifiedOnly;
  late bool _superLikesOnly;

  @override
  void initState() {
    super.initState();
    _verifiedOnly = widget.verifiedOnly;
    _superLikesOnly = widget.superLikesOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PulseColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PulseColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: PulseTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PulseColors.grey900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _verifiedOnly = false;
                        _superLikesOnly = false;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Filter options
            SwitchListTile(
              title: const Text('Verified only'),
              subtitle: const Text('Show only verified users'),
              value: _verifiedOnly,
              onChanged: (value) {
                setState(() {
                  _verifiedOnly = value;
                });
              },
              activeTrackColor: PulseColors.primary,
            ),

            SwitchListTile(
              title: const Text('Super Likes only'),
              subtitle: const Text('Show only users who super liked you'),
              value: _superLikesOnly,
              onChanged: (value) {
                setState(() {
                  _superLikesOnly = value;
                });
              },
              activeTrackColor: PulseColors.primary,
            ),

            const SizedBox(height: 16),

            // Apply button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_verifiedOnly, _superLikesOnly);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: PulseColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Filter options for Who Liked You
enum WhoLikedYouFilter { all, recent24h, verifiedOnly, superLikes }
