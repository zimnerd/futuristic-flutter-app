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
import '../../navigation/app_router.dart';
import '../profile/profile_details_screen.dart';
import '../../widgets/common/robust_network_image.dart';
import '../../widgets/verification/verification_badge.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../theme/overlay_styling.dart';

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
      LoadWhoLikedYou(
        filters: DiscoveryFilters(verifiedOnly: _verifiedOnly),
        superLikesOnly: _superLikesOnly,
      ),
    );
  }

  bool _isPremiumUser(BuildContext context) {
    final premiumState = context.watch<PremiumBloc>().state;
    if (premiumState is PremiumLoaded) {
      final isActive = premiumState.subscription?.isActive ?? false;
      return isActive;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _isPremiumUser(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive: use 1 column on very small screens, 2 on normal
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Who Liked You',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: context.textPrimary),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _currentFilter != WhoLikedYouFilter.all,
              label: Text('!'),
              child: Icon(Icons.filter_list, color: context.textPrimary),
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
            return _buildUserGrid(state.userStack, isPremium, isSmallScreen);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildUserGrid(
    List<UserProfile> users,
    bool isPremium,
    bool isSmallScreen,
  ) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 1 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isSmallScreen ? 0.6 : 0.7,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _UserGridCard(
                  user: users[index],
                  isPremium: isPremium,
                  onTap: () {
                    if (isPremium) {
                      // Navigate to profile details using correct route
                      context.push(
                        AppRoutes.profileDetails.replaceFirst(
                          ':profileId',
                          users[index].id,
                        ),
                        extra: {
                          'profile': users[index],
                          'context': ProfileContext.general,
                          'onLike': () => _likeBack(users[index]),
                        },
                      );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor, width: 1),
        ),
        child: Row(
          children: [
            _buildFilterTab(
              label: 'All',
              filter: WhoLikedYouFilter.all,
              icon: Icons.layers,
            ),
            _buildFilterTab(
              label: '24h',
              filter: WhoLikedYouFilter.recent24h,
              icon: Icons.schedule,
            ),
            _buildFilterTab(
              label: 'Verified',
              filter: WhoLikedYouFilter.verifiedOnly,
              icon: Icons.verified,
            ),
            _buildFilterTab(
              label: 'Super ⭐',
              filter: WhoLikedYouFilter.superLikes,
              icon: Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required WhoLikedYouFilter filter,
    IconData? icon,
  }) {
    final isSelected = _currentFilter == filter;

    return GestureDetector(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.surfaceColor : Colors.transparent,
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? PulseColors.primary
                    : context.textSecondary,
              ),
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: PulseTypography.labelSmall.copyWith(
                color: isSelected
                    ? PulseColors.primary
                    : context.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
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
                color: context.onSurfaceVariantColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No one has liked you yet',
              style: PulseTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Keep swiping and someone will like you soon!',
              style: PulseTypography.bodyLarge.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: Icon(Icons.explore),
              label: Text('Start Swiping'),
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
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: PulseTypography.bodyLarge.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadWhoLikedYou,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
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
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                child: Icon(
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
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Upgrade to Premium to see who liked you and match instantly!',
                style: PulseTypography.bodyLarge.copyWith(
                  color: context.textSecondary,
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
                  child: Text(
                    'Upgrade to Premium',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Maybe Later'),
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
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: PulseTypography.bodyMedium.copyWith(
                  color: context.textSecondary,
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
                  color: context.borderColor.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: Container(
                  color: context.borderColor.shade300,
                  child: Icon(
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
                    gradient: OverlayStyling.getOverlayGradient(context),
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
                          child: Icon(
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
                          Icon(
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
                      child: Icon(
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
        color:context.borderColor.shade200,
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
                  context.borderColor.shade200,
                  context.borderColor.shade300,
                  context.borderColor.shade200,
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
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: context.borderColor.shade300,
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
                      color: context.textPrimary,
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
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: context.borderColor),
            
            // Filter options
            SwitchListTile(
              title: Text(
                'Verified only',
                style: PulseTypography.bodyMedium.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Show only verified users',
                style: PulseTypography.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              value: _verifiedOnly,
              onChanged: (value) {
                setState(() {
                  _verifiedOnly = value;
                });
              },
              activeTrackColor: PulseColors.primary,
            ),

            SwitchListTile(
              title: Text(
                'Super Likes only',
                style: PulseTypography.bodyMedium.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Show only users who super liked you',
                style: PulseTypography.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
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
                  child: Text(
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
