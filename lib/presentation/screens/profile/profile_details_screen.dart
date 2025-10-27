import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../domain/entities/user_profile.dart';
import '../../../data/models/user_model.dart';
import '../../../blocs/chat_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/block_report/block_report_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../theme/pulse_profile_colors.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/verification/verification_badge.dart';
import '../../widgets/dialogs/block_user_dialog.dart';
import '../../widgets/dialogs/report_user_dialog.dart';
import '../../../core/utils/time_format_utils.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../widgets/profile/profile_strength_indicator.dart';
import '../../theme/overlay_styling.dart';

/// Context for profile viewing - determines which actions to show
enum ProfileContext {
  /// Discovery screen - show like/superlike/pass actions
  discovery,

  /// Matches screen - show chat/call/unmatch/report actions
  matches,

  /// General viewing - show minimal actions
  general,
}

/// Comprehensive profile details screen with social media style layout
class ProfileDetailsScreen extends StatefulWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final ProfileContext context;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperLike;
  final VoidCallback? onMessage;
  final VoidCallback? onUnmatch;
  final VoidCallback? onReport;
  @Deprecated('Use context parameter instead')
  final bool showStartConversation;

  const ProfileDetailsScreen({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.context = ProfileContext.general,
    this.onLike,
    this.onDislike,
    this.onSuperLike,
    this.onMessage,
    this.onUnmatch,
    this.onReport,
    @Deprecated('Use context parameter instead')
    this.showStartConversation = false,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;

  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Load stats if viewing own profile
    if (widget.isOwnProfile) {
      context.read<ProfileBloc>().add(const LoadProfileStats());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPhotoTap() {
    if (!mounted) return;
    _showPhotoModal();
  }

  void _showPhotoModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: context.onSurfaceColor.withValues(alpha: 0.9),
      builder: (context) => _buildPhotoModal(),
    );
  }

  /// Handles starting a voice call with the user
  void _startVoiceCall(BuildContext context) {
    if (!mounted) return;

    final callId =
        'call_${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Convert UserProfile to UserModel for AudioCallScreen
    final remoteUser = UserModel(
      id: widget.profile.id,
      email: '', // Not available in UserProfile
      username: widget.profile.name,
      firstName: widget.profile.name.split(' ').first,
      lastName: widget.profile.name.split(' ').length > 1
          ? widget.profile.name.split(' ').last
          : null,
      photos: widget.profile.photos.map((p) => p.url).toList(),
      createdAt: DateTime.now(), // Not available in UserProfile
    );

    context.push(
      '/audio-call/$callId',
      extra: {'remoteUser': remoteUser, 'isIncoming': false},
    );
  }

  /// Handles starting a conversation with the user
  void _startConversation(BuildContext context) {
    if (!mounted) return;

    final chatBloc = context.read<ChatBloc>();

    // Create conversation using ChatBloc
    chatBloc.add(CreateConversation(participantId: widget.profile.id));

    // Listen for conversation creation result
    final subscription = chatBloc.stream.listen((state) {
      if (state is ConversationCreated) {
        // Check if widget is still mounted before navigation
        if (!mounted) return;

        // Navigate to chat screen with the new conversation
        // Use push to maintain navigation stack
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        context.push(
          '/chat/${state.conversation.id}',
          extra: {
            'otherUserId': widget.profile.id,
            'otherUserName': widget.profile.name,
            'otherUserPhoto': widget.profile.photos.isNotEmpty
                ? widget.profile.photos.first.url
                : null,
          },
        );
      } else if (state is ChatError) {
        // Check if widget is still mounted before showing message
        if (!mounted) return;

        // Show more helpful error message for matching requirement
        String errorMessage = 'Failed to start conversation: ${state.message}';
        if (state.message.toLowerCase().contains('matched') ||
            state.message.toLowerCase().contains('403')) {
          errorMessage =
              "You can only message people you've matched with. Try liking this profile first!";
        }

        PulseToast.error(
          context,
          message: errorMessage,
          duration: const Duration(seconds: 4),
          action:
              state.message.toLowerCase().contains('matched') ||
                  state.message.toLowerCase().contains('403')
              ? ToastAction(
                  label: 'Like Profile',
                  onPressed: () {
                    if (widget.onLike != null) {
                      widget.onLike!();
                    }
                  },
                )
              : null,
        );
      }
    });

    // Auto-cancel subscription after reasonable timeout
    Future.delayed(const Duration(seconds: 10), () {
      subscription.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStatsRow(),
                const SizedBox(height: 12),
                _buildProfileHeader(),
                if (widget.isOwnProfile) ...[
                  const SizedBox(height: 20),
                  _buildStatsCards(),
                  const SizedBox(height: 20),
                  _buildProfileCompletionCard(),
                ],
                const SizedBox(height: 20),
                _buildAboutSection(),
                const SizedBox(height: 20),
                _buildPhysicalAttributesSection(),
                const SizedBox(height: 20),
                _buildLifestyleSection(),
                const SizedBox(height: 20),
                _buildRelationshipGoalsSection(),
                const SizedBox(height: 20),
                _buildDetailsSection(),
                const SizedBox(height: 20),
                _buildInterestsSection(),
                const SizedBox(height: 20),
                _buildLanguagesSection(),
                const SizedBox(height: 20),
                _buildPersonalityTraitsSection(),
                const SizedBox(height: 20),
                _buildPromptQuestionsSection(),
                const SizedBox(height: 20),
                if (widget.profile.photos.length > 1) ...[
                  _buildPhotosGrid(),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: widget.isOwnProfile ? null : _buildStickyActionBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      // Transparent when expanded (over image), surface color when collapsed
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      // Always light text/icons for visibility over image
      foregroundColor: context.textOnPrimary,
      // Custom leading button with background
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.onSurfaceColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: context.textOnPrimary,
        ),
      ),
      // Add semi-transparent dark background when pinned for better contrast
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            _buildPhotoCarousel(),
            // Semi-transparent overlay at top for icon visibility when pinned
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 56, // AppBar height
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.onSurfaceColor.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Remove the top-level title - use FlexibleSpaceBar title instead
      actions: [
        if (!widget.isOwnProfile)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.onSurfaceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _shareProfile();
                    break;
                  case 'report':
                    _reportProfile();
                    break;
                  case 'block':
                    _blockUser();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 12),
                      Text('Share Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: context.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Report',
                        style: TextStyle(color: context.errorColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 20, color: context.errorColor),
                      const SizedBox(width: 12),
                      Text(
                        'Block User',
                        style: TextStyle(color: context.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoCarousel() {
    if (widget.profile.photos.isEmpty) {
      return Container(
        color: context.outlineColor.withValues(alpha: 0.15),
        child: Center(
          child: Icon(Icons.person, size: 80, color: context.outlineColor),
        ),
      );
    }

    // Wrap the entire Stack in a GestureDetector to handle swipe gestures properly
    // This prevents the parent CustomScrollView from intercepting horizontal swipes
    return GestureDetector(
      // Block vertical scrolling when user is swiping photos horizontally
      onHorizontalDragStart: (_) {}, // Claim horizontal gesture
      onHorizontalDragUpdate: (details) {
        // Let PageView handle the actual swipe
      },
      onHorizontalDragEnd: (_) {},
      child: Stack(
        children: [
          // Photo carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemCount: widget.profile.photos.length,
            itemBuilder: (context, index) {
              final photo = widget.profile.photos[index];
              return GestureDetector(
                onTap: _onPhotoTap,
                child: Hero(
                  tag: 'profile-photo-${photo.id}',
                  child: _buildPhotoWidget(photo),
                ),
              );
            },
          ),

          // Dark gradient overlay for icon visibility (top-down fade)
          Positioned.fill(
            child: IgnorePointer(
              // Allow gestures to pass through to PageView
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: OverlayStyling.getTopFadeGradient(context),
                ),
              ),
            ),
          ),

          // Bottom gradient overlay with profile info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              // Allow gestures to pass through to PageView
              child: Container(
                decoration: BoxDecoration(
                  gradient: OverlayStyling.getOverlayGradient(context),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and verification badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.profile.name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: context.textOnPrimary,
                              shadows: [
                                Shadow(
                                  color: context.onSurfaceColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_shouldShowAge())
                          Text(
                            ', ${widget.profile.age}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: context.textOnPrimary,
                              shadows: [
                                Shadow(
                                  color: context.onSurfaceColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        VerificationBadge(
                          isVerified: widget.profile.verified,
                          size: VerificationBadgeSize.medium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location with distance
                    if (_shouldShowDistance())
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: context.textOnPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.profile.distanceString,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textOnPrimary,
                              shadows: [
                                Shadow(
                                  color: context.onSurfaceColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_shouldShowOnlineStatus() &&
                              widget.profile.isOnline) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: PulseColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: PulseColors.success,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Online now',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textOnPrimary,
                                shadows: [
                                  Shadow(
                                    color: context.onSurfaceColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Bio preview
                    if (widget.profile.bio.isNotEmpty)
                      Text(
                        widget.profile.bio.length > 100
                            ? '${widget.profile.bio.substring(0, 100)}...'
                            : widget.profile.bio,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textOnPrimary,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: context.onSurfaceColor.withValues(
                                alpha: 0.5,
                              ),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    // Badges row (occupation, social media, etc)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Note: Work/Education badges removed from image overlay
                        // They're displayed in the Details section below
                        // Add social media badges if available
                        // These would come from profile data - placeholder for now
                      ],
                    ),
                    const SizedBox(
                      height: 60,
                    ), // Spacing from bottom to keep pills away from action bar
                  ],
                ),
              ),
            ),
          ),

          // Photo indicators
          if (widget.profile.photos.length > 1)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: IgnorePointer(
                // Allow gestures to pass through
                child: Row(
                  children: widget.profile.photos.asMap().entries.map((entry) {
                    final isActive = entry.key == _currentPhotoIndex;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: entry.key < widget.profile.photos.length - 1
                              ? 6
                              : 0,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? context.textOnPrimary
                              : context.textOnPrimary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: context.onSurfaceColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Photo counter
          Positioned(
            bottom: 20,
            right: 20,
            child: IgnorePointer(
              // Allow gestures to pass through
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.onSurfaceColor.withValues(alpha: 0.7),
                      context.onSurfaceColor.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.textOnPrimary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.onSurfaceColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: context.textOnPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentPhotoIndex + 1}/${widget.profile.photos.length}',
                      style: PulseTextStyles.labelMedium.copyWith(
                        color: context.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ); // Close GestureDetector
  }

  Widget _buildPhotoWidget(ProfilePhoto photo) {
    if (photo.url.startsWith('/') || photo.url.startsWith('file://')) {
      return Image.file(
        File(photo.url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPhotoError(),
      );
    }

    return CachedNetworkImage(
      imageUrl: photo.url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => _buildPhotoLoading(),
      errorWidget: (context, url, error) => _buildPhotoError(),
    );
  }

  Widget _buildPhotoLoading() {
    return Container(
      color: context.outlineColor.withValues(alpha: 0.15),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildPhotoError() {
    return Container(
      color: context.outlineColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.error_outline, size: 48, color: context.outlineColor),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            PulseColors.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.profile.name,
                            style: PulseTextStyles.headlineMedium.copyWith(
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        VerificationBadge(
                          isVerified: widget.profile.verified,
                          size: VerificationBadgeSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_shouldShowAge())
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: PulseColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${widget.profile.age} years old',
                          style: PulseTextStyles.labelMedium.copyWith(
                            color: PulseColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLocationRow(),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.outlineColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PulseColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
              color: PulseColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_shouldShowDistance())
                  Text(
                    widget.profile.distanceString,
                    style: PulseTextStyles.bodyMedium.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (_shouldShowDistance()) const SizedBox(height: 4),
                Row(
                  children: [
                    if (_shouldShowOnlineStatus() &&
                        widget.profile.isOnline) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: PulseColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_shouldShowOnlineStatus())
                        Text(
                          'Online now',
                          style: PulseTextStyles.labelSmall.copyWith(
                            color: PulseColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ] else ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.outlineColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatLastActive(),
                        style: PulseTextStyles.labelSmall.copyWith(
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    if (widget.profile.bio.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.purpleTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconAbout,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.profile.bio,
            style: PulseTextStyles.bodyLarge.copyWith(
              height: 1.6,
              color: context.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final details = <Widget>[];

    if (widget.profile.job?.isNotEmpty == true) {
      details.add(
        _buildDetailItem(Icons.work_outline, 'Job', widget.profile.job!),
      );
    }
    if (widget.profile.company?.isNotEmpty == true) {
      details.add(
        _buildDetailItem(
          Icons.business_outlined,
          'Company',
          widget.profile.company!,
        ),
      );
    }
    if (widget.profile.school?.isNotEmpty == true) {
      details.add(
        _buildDetailItem(
          Icons.school_outlined,
          'Education',
          widget.profile.school!,
        ),
      );
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.primary.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: PulseColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Details',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.outlineColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                  label,
                  style: PulseTextStyles.labelMedium.copyWith(
                    color: context.onSurfaceVariantColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: PulseTextStyles.bodyLarge.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    if (widget.profile.interests.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.tealTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentSuccess.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconInterests,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Interests',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.profile.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseProfileColors.accentPrimary.withValues(
                      alpha: 0.3,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PulseProfileColors.accentPrimary.withValues(
                        alpha: 0.1,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✓',
                      style: TextStyle(
                        color: PulseProfileColors.accentSuccess,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      interest.name,
                      style: PulseTextStyles.bodyMedium.copyWith(
                        color: context.onSurfaceColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    final remainingPhotos = widget.profile.photos.skip(1).take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'More Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _onPhotoTap,
                child: Text(
                  'See All (${widget.profile.photos.length})',
                  style: TextStyle(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: remainingPhotos.length,
            itemBuilder: (context, index) {
              final photo = remainingPhotos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPhotoIndex = index + 1;
                    });
                    _showPhotoModal();
                  },
                  child: Hero(
                    tag: 'grid-photo-${photo.id}',
                    child: _buildPhotoWidget(photo),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Privacy helper methods
  bool _shouldShowAge() => widget.profile.showAge ?? true;
  bool _shouldShowDistance() => widget.profile.showDistance ?? true;
  bool _shouldShowOnlineStatus() => widget.profile.showOnlineStatus ?? true;

  /// Format last active time for display
  String _formatLastActive() {
    return formatLastActive(widget.profile.lastActiveAt);
  }

  String _formatHeight(int cm) {
    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$cm cm ($feet\' $inches")';
  }

  Widget _buildPhysicalAttributesSection() {
    final hasData =
        widget.profile.height != null ||
        widget.profile.religion != null ||
        widget.profile.politics != null ||
        widget.profile.zodiacSign != null;

    if (!hasData) return const SizedBox.shrink();

    final details = <Widget>[];

    if (widget.profile.height != null) {
      details.add(
        _buildDetailItem(
          Icons.height,
          'Height',
          _formatHeight(widget.profile.height!),
        ),
      );
    }

    if (widget.profile.religion != null) {
      details.add(
        _buildDetailItem(
          Icons.church_outlined,
          'Religion',
          widget.profile.religion!,
        ),
      );
    }

    if (widget.profile.politics != null) {
      details.add(
        _buildDetailItem(
          Icons.how_to_vote_outlined,
          'Political Views',
          widget.profile.politics!,
        ),
      );
    }

    if (widget.profile.zodiacSign != null) {
      details.add(
        _buildDetailItem(
          Icons.star_outline,
          'Zodiac Sign',
          widget.profile.zodiacSign!,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.brownTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconLifestyle,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Physical & Beliefs',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...details,
        ],
      ),
    );
  }

  Widget _buildLifestyleSection() {
    final hasData =
        widget.profile.lifestyleChoice != null ||
        widget.profile.drinking != null ||
        widget.profile.smoking != null ||
        widget.profile.exercise != null ||
        widget.profile.drugs != null ||
        widget.profile.children != null;

    if (!hasData) return const SizedBox.shrink();

    final details = <Widget>[];

    if (widget.profile.lifestyleChoice != null) {
      details.add(
        _buildDetailItem(
          Icons.wb_sunny_outlined,
          'Lifestyle',
          widget.profile.lifestyleChoice!,
        ),
      );
    }

    if (widget.profile.drinking != null) {
      details.add(
        _buildDetailItem(
          Icons.local_bar_outlined,
          'Drinking',
          widget.profile.drinking!,
        ),
      );
    }

    if (widget.profile.smoking != null) {
      details.add(
        _buildDetailItem(
          Icons.smoking_rooms_outlined,
          'Smoking',
          widget.profile.smoking!,
        ),
      );
    }

    if (widget.profile.exercise != null) {
      details.add(
        _buildDetailItem(
          Icons.fitness_center_outlined,
          'Exercise',
          widget.profile.exercise!,
        ),
      );
    }

    if (widget.profile.drugs != null) {
      details.add(
        _buildDetailItem(
          Icons.warning_amber_outlined,
          'Drugs',
          widget.profile.drugs!,
        ),
      );
    }

    if (widget.profile.children != null) {
      details.add(
        _buildDetailItem(
          Icons.child_care_outlined,
          'Children',
          widget.profile.children!,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.brownTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconLifestyle,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lifestyle Choices',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...details,
        ],
      ),
    );
  }

  Widget _buildRelationshipGoalsSection() {
    if (widget.profile.relationshipGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.goldTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconGoals,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Looking For',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.profile.relationshipGoals.map((goal) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseProfileColors.accentPrimary.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: Text(
                  goal,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    if (widget.profile.languages.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.purpleTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconLanguages,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Languages',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.profile.languages.map((language) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseProfileColors.accentPrimary.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: Text(
                  language,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityTraitsSection() {
    if (widget.profile.personalityTraits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.purpleTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconPersonality,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Personality',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.profile.personalityTraits.map((trait) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseProfileColors.accentPrimary.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: Text(
                  trait,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptQuestionsSection() {
    if (widget.profile.promptQuestions.isEmpty ||
        widget.profile.promptAnswers.isEmpty) {
      return const SizedBox.shrink();
    }

    final prompts = <Widget>[];
    final count =
        widget.profile.promptQuestions.length <
            widget.profile.promptAnswers.length
        ? widget.profile.promptQuestions.length
        : widget.profile.promptAnswers.length;

    for (var i = 0; i < count; i++) {
      prompts.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.onSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.outlineColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.profile.promptQuestions[i],
                style: PulseTextStyles.labelLarge.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.profile.promptAnswers[i],
                style: PulseTextStyles.bodyLarge.copyWith(
                  color: context.onSurfaceColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.purpleTintedGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.outlineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseProfileColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PulseProfileColors.iconPrompts,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'My Vibe',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: context.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...prompts,
        ],
      ),
    );
  }

  /// Quick stats row - Shows key profile info at a glance
  Widget _buildQuickStatsRow() {
    final stats = <_StatItem>[
      if (widget.profile.occupation != null)
        _StatItem(icon: '🏢', label: widget.profile.occupation!),
      if (widget.profile.education != null)
        _StatItem(icon: '📚', label: widget.profile.education!),
      if (widget.profile.height != null)
        _StatItem(icon: '📏', label: _formatHeight(widget.profile.height!)),
      if (widget.profile.zodiacSign != null)
        _StatItem(icon: '♈', label: widget.profile.zodiacSign!),
    ];

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(
          stats.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < stats.length - 1 ? 8 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(stats[index].icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    stats[index].label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sticky action bar - Always visible, context-aware buttons
  Widget _buildStickyActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: context.borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: widget.context == ProfileContext.discovery
            ? _buildDiscoveryActions()
            : _buildMatchesActions(),
      ),
    );
  }

  /// Discovery mode actions: Pass, Super Like, Like
  Widget _buildDiscoveryActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleActionButton(
          icon: Icons.close,
          label: 'Pass',
          backgroundColor: context.borderColor,
          iconColor: context.textSecondary,
          onPressed: widget.onDislike,
        ),
        _buildCircleActionButton(
          icon: Icons.star,
          label: 'Super',
          backgroundColor: PulseColors.warning,
          iconColor: Colors.white,
          size: 64,
          onPressed: widget.onSuperLike,
        ),
        _buildCircleActionButton(
          icon: Icons.favorite,
          label: 'Like',
          backgroundColor: PulseColors.error,
          iconColor: Colors.white,
          onPressed: widget.onLike,
        ),
      ],
    );
  }

  /// Matches mode actions: Chat, Call, More
  Widget _buildMatchesActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildRoundedActionButton(
            icon: Icons.message,
            label: 'Chat',
            onPressed: widget.onMessage ?? () => _startConversation(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoundedActionButton(
            icon: Icons.call,
            label: 'Call',
            onPressed: () => _startVoiceCall(context),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.undo, color: context.textPrimary),
                      title: Text(
                        'Unmatch',
                        style: TextStyle(color: context.textPrimary),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onUnmatch != null) widget.onUnmatch!();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.flag, color: PulseColors.error),
                      title: Text(
                        'Report',
                        style: TextStyle(color: PulseColors.error),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _reportProfile();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.more_vert, color: context.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Circle action button - for discovery mode
  Widget _buildCircleActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback? onPressed,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onPressed != null
          ? () {
              onPressed();
              if (mounted) {
                context.pop();
              }
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.4),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Rounded action button - for matches mode
  Widget _buildRoundedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: PulseColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: PulseColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoModal() {
    return _FullScreenPhotoViewer(
      photos: widget.profile.photos,
      initialIndex: _currentPhotoIndex,
    );
  }

  // Context menu actions
  void _shareProfile() {
    final profile = widget.profile;
    final shareText =
        '''Check out ${profile.name}'s profile on PulseLink!

Age: ${profile.age}
Location: ${profile.location.city}

Join PulseLink to connect!''';

    // Share functionality ready - requires share_plus package
    // Add to pubspec.yaml: share_plus: ^7.0.0
    // Then uncomment: Share.share(shareText, subject: '${profile.name} on PulseLink');

    PulseToast.info(
      context,
      message: 'Share text prepared:\n$shareText',
      duration: const Duration(seconds: 3),
    );
  }

  Widget _buildStatsCards() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // Show loading shimmer while fetching stats
        if (state.statsStatus == ProfileStatus.loading || state.stats == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatsLoadingSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatsLoadingSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatsLoadingSkeleton()),
              ],
            ),
          );
        }

        // Display real stats from API
        final stats = state.stats!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  label: 'Matches',
                  value: '${stats.matchesCount}',
                  color: PulseColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.thumb_up,
                  label: 'Likes',
                  value: '${stats.likesReceived}',
                  color: PulseColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility,
                  label: 'Visits',
                  value: '${stats.profileViews}',
                  color: PulseColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: context.onSurfaceColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: PulseTextStyles.headlineMedium.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PulseTextStyles.bodyMedium.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 14,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final completionPercentage = _calculateProfileCompletion();
    final completedSections = _getCompletedSections();
    final missingSections = _getMissingSectionsAsStrings();

    return ProfileStrengthIndicator(
      completionPercentage: completionPercentage,
      completedSections: completedSections,
      missingSections: missingSections,
    );
  }

  int _calculateProfileCompletion() {
    int completed = 0;
    int total = 10;

    // Basic info (always completed if profile exists)
    completed += 1;

    // Photos
    if (widget.profile.photos.length >= 3) completed += 1;

    // Bio
    if (widget.profile.bio.isNotEmpty && widget.profile.bio.length > 50) {
      completed += 1;
    }

    // Physical attributes
    if (widget.profile.height != null) {
      completed += 1;
    }

    // Lifestyle
    if (widget.profile.drinking != null || widget.profile.smoking != null) {
      completed += 1;
    }

    // Relationship goals
    if (widget.profile.relationshipGoals.isNotEmpty) {
      completed += 1;
    }

    // Job/Education
    if (widget.profile.job?.isNotEmpty == true ||
        widget.profile.education?.isNotEmpty == true) {
      completed += 1;
    }

    // Interests
    if (widget.profile.interests.length >= 3) completed += 1;

    // Languages
    if (widget.profile.languages.isNotEmpty) completed += 1;

    // Personality traits or prompts
    if (widget.profile.personalityTraits.isNotEmpty ||
        widget.profile.promptQuestions.isNotEmpty) {
      completed += 1;
    }

    return ((completed / total) * 100).round();
  }

  /// Get list of completed profile sections as strings
  List<String> _getCompletedSections() {
    final completed = <String>[];

    if (widget.profile.photos.length >= 3) {
      completed.add('Photos');
    }

    if (widget.profile.bio.isNotEmpty && widget.profile.bio.length > 50) {
      completed.add('Bio');
    }

    if (widget.profile.height != null) {
      completed.add('Physical Attributes');
    }

    if (widget.profile.drinking != null || widget.profile.smoking != null) {
      completed.add('Lifestyle');
    }

    if (widget.profile.relationshipGoals.isNotEmpty) {
      completed.add('Dating Goals');
    }

    if (widget.profile.job?.isNotEmpty == true ||
        widget.profile.education?.isNotEmpty == true) {
      completed.add('Work & Education');
    }

    if (widget.profile.interests.length >= 3) {
      completed.add('Interests');
    }

    if (widget.profile.languages.isNotEmpty) {
      completed.add('Languages');
    }

    if (widget.profile.personalityTraits.isNotEmpty ||
        widget.profile.promptQuestions.isNotEmpty) {
      completed.add('Personality');
    }

    return completed;
  }

  /// Get list of missing profile sections as strings
  List<String> _getMissingSectionsAsStrings() {
    final missing = <String>[];

    if (widget.profile.photos.length < 3) {
      missing.add('Add Photos');
    }

    if (widget.profile.bio.isEmpty || widget.profile.bio.length < 50) {
      missing.add('Complete Bio');
    }

    if (widget.profile.interests.length < 3) {
      missing.add('Add Interests');
    }

    if (widget.profile.relationshipGoals.isEmpty) {
      missing.add('Set Dating Goals');
    }

    if ((widget.profile.job?.isEmpty ?? true) &&
        (widget.profile.education?.isEmpty ?? true)) {
      missing.add('Add Work/Education');
    }

    if (widget.profile.personalityTraits.isEmpty &&
        widget.profile.promptQuestions.isEmpty) {
      missing.add('Add Personality');
    }

    return missing;
  }

  void _reportProfile() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<BlockReportBloc>(),
        child: BlocListener<BlockReportBloc, BlockReportState>(
          listener: (context, state) {
            if (state is UserReported) {
              Navigator.pop(dialogContext);
              PulseToast.success(
                context,
                message:
                    'Report submitted. Thank you for keeping PulseLink safe.',
                duration: const Duration(seconds: 3),
              );
            } else if (state is BlockReportError) {
              PulseToast.error(
                context,
                message: 'Failed to report: ${state.message}',
              );
            }
          },
          child: ReportUserDialog(
            userId: widget.profile.id,
            userName: widget.profile.name,
          ),
        ),
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<BlockReportBloc>(),
        child: BlocListener<BlockReportBloc, BlockReportState>(
          listener: (context, state) {
            if (state is UserBlocked) {
              Navigator.pop(dialogContext);
              PulseToast.success(
                context,
                message: 'User blocked successfully',
                duration: const Duration(seconds: 2),
              );
              // Close profile after blocking
              this.context.pop();
            } else if (state is BlockReportError) {
              PulseToast.error(
                context,
                message: 'Failed to block user: ${state.message}',
              );
            }
          },
          child: BlockUserDialog(
            userId: widget.profile.id,
            userName: widget.profile.name,
          ),
        ),
      ),
    );
  }
}

/// Full screen photo viewer with independent index tracking and description display
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    final hasDescription =
        currentPhoto.description != null &&
        currentPhoto.description!.isNotEmpty;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            '${_currentIndex + 1} of ${widget.photos.length}',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Stack(
          children: [
            // Photo viewer
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return Center(
                  child: Hero(
                    tag: 'profile-photo-${photo.id}',
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: photo.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.error,
                            color: context.onSurfaceColor,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Description overlay at bottom (if available)
            if (hasDescription)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                  child: Text(
                    currentPhoto.description!,
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper class for quick stats
class _StatItem {
  final String icon;
  final String label;

  _StatItem({required this.icon, required this.label});
}
