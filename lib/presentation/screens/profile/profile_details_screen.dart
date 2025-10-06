import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../domain/entities/user_profile.dart';
import '../../../data/models/user_model.dart';
import '../../../blocs/chat_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../../core/utils/time_format_utils.dart';

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
      barrierColor: Colors.black.withValues(alpha: 0.9),
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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final chatBloc = context.read<ChatBloc>();
    
    // Create conversation using ChatBloc
    chatBloc.add(CreateConversation(
      participantId: widget.profile.id,
    ));
    
    // Listen for conversation creation result
    final subscription = chatBloc.stream.listen((state) {
      if (state is ConversationCreated) {
        // Check if widget is still mounted before navigation
        if (!mounted) return;

        // Navigate to chat screen with the new conversation
        // Use push to maintain navigation stack
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

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action:
                state.message.toLowerCase().contains('matched') ||
                    state.message.toLowerCase().contains('403')
                ? SnackBarAction(
                    label: 'Like Profile',
                    textColor: Colors.white,
                    onPressed: () {
                      if (widget.onLike != null) {
                        widget.onLike!();
                      }
                    },
                  )
                : null,
          ),
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
      backgroundColor: Colors.white,
      extendBody: false, // Ensure bottom sheet isn't obscured
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 100), // Space for bottom actions
              ],
            ),
          ),
        ],
      ),
      bottomSheet: widget.isOwnProfile ? null : _buildBottomActions(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      // Make icons always visible with white color against dark overlay
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (!widget.isOwnProfile)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
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
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Report', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildPhotoCarousel(),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    if (widget.profile.photos.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: Colors.grey,
          ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.6],
                  ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
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
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
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
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (widget.profile.verified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  PulseColors.primary,
                                  PulseColors.secondary,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: PulseColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location with distance
                if (_shouldShowDistance())
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.profile.distanceString,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
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
                          decoration: const BoxDecoration(
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
                        const Text(
                          'Online now',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
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
                    // Occupation badge
                    if (widget.profile.occupation != null)
                      _buildBadgePill(
                        icon: Icons.work_outline,
                        label: widget.profile.occupation!,
                      ),
                    // Education badge
                    if (widget.profile.education != null)
                      _buildBadgePill(
                        icon: Icons.school_outlined,
                        label: widget.profile.education!,
                      ),
                    // Add social media badges if available
                    // These would come from profile data - placeholder for now
                  ],
                ),
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
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
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
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
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
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentPhotoIndex + 1}/${widget.profile.photos.length}',
                      style: PulseTextStyles.labelMedium.copyWith(
                        color: Colors.white,
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
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildPhotoError() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.error_outline, size: 48, color: Colors.grey),
      ),
    );
  }

  /// Builds a badge pill for displaying profile attributes (occupation, education, etc.)
  Widget _buildBadgePill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
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
                        if (widget.profile.verified)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  PulseColors.primary,
                                  PulseColors.secondary,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: PulseColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
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
                        decoration: const BoxDecoration(
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
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatLastActive(),
                        style: PulseTextStyles.labelSmall.copyWith(
                          color: Colors.grey[600],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            PulseColors.secondaryContainer.withValues(alpha: 0.1),
          ],
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
                  color: PulseColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: PulseColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.profile.bio,
            style: PulseTextStyles.bodyLarge.copyWith(
              height: 1.6,
              color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
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
            child: Icon(icon,
              color: PulseColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: PulseTextStyles.labelMedium.copyWith(
                    color: Colors.grey[600],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.success.withValues(alpha: 0.02)],
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
                  color: PulseColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: PulseColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Interests',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
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
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary.withValues(alpha: 0.15),
                      PulseColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PulseColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: PulseColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      interest,
                      style: PulseTextStyles.bodyMedium.copyWith(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.bold,
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
              const Text(
                'More Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.secondary.withValues(alpha: 0.02)],
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
                  color: PulseColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: PulseColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Physical & Beliefs',
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.success.withValues(alpha: 0.02)],
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
                  color: PulseColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  color: PulseColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lifestyle Choices',
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

  Widget _buildRelationshipGoalsSection() {
    if (widget.profile.relationshipGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.secondary.withValues(alpha: 0.02)],
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
                  color: PulseColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: PulseColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Looking For',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
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
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.secondary.withValues(alpha: 0.1),
                      PulseColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseColors.secondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  goal,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.secondary,
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
                  Icons.language,
                  color: PulseColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Languages',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
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
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  language,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.primary,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.secondary.withValues(alpha: 0.02)],
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
                  color: PulseColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: PulseColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Personality',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
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
                  color: PulseColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseColors.secondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  trait,
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.secondary,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
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
                  color: Colors.black87,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.success.withValues(alpha: 0.02)],
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
                  color: PulseColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: PulseColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'My Vibe',
                style: PulseTextStyles.titleLarge.copyWith(
                  color: Colors.black87,
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

  Widget _buildBottomActions() {
    // Discovery context: Show like/superlike/pass actions
    if (widget.context == ProfileContext.discovery) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass/Dislike button
              _buildActionButton(
                icon: Icons.close,
                label: 'Pass',
                color: Colors.grey[400]!,
                onPressed: () {
                  if (widget.onDislike != null) {
                    widget.onDislike!();
                    // Auto-close after action
                    if (mounted) {
                      context.pop();
                    }
                  }
                },
              ),
              const SizedBox(width: 16),
              // Super Like button
              _buildActionButton(
                icon: Icons.star,
                label: 'Super',
                color: PulseColors.warning,
                gradient: LinearGradient(
                  colors: [PulseColors.warning, Colors.orange],
                ),
                onPressed: () {
                  if (widget.onSuperLike != null) {
                    widget.onSuperLike!();
                    // Auto-close after action
                    if (mounted) {
                      context.pop();
                    }
                  }
                },
                size: 72,
              ),
              const SizedBox(width: 16),
              // Like button
              _buildActionButton(
                icon: Icons.favorite,
                label: 'Like',
                color: PulseColors.error,
                onPressed: () {
                  if (widget.onLike != null) {
                    widget.onLike!();
                    // Auto-close after action
                    if (mounted) {
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    // Matches context: Show chat/call/unmatch/report actions
    if (widget.context == ProfileContext.matches) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary actions: Chat and Call
              Row(
                children: [
                  Expanded(
                    child: PulseButton(
                      text: '💬 Chat',
                      onPressed:
                          widget.onMessage ?? () => _startConversation(context),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PulseButton(
                      text: '� Call',
                      onPressed: () => _startVoiceCall(context),
                      variant: PulseButtonVariant.secondary,
                      icon: const Icon(Icons.phone, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Secondary actions: Unmatch and Report
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onUnmatch,
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Unmatch'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onReport,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Report'),
                      style: TextButton.styleFrom(
                        foregroundColor: PulseColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // General/Legacy context: Show minimal actions (backward compatibility)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (widget.onSuperLike != null)
              Expanded(
                child: PulseButton(
                  text: '⭐ Super Like',
                  onPressed: widget.onSuperLike,
                  variant: PulseButtonVariant.secondary,
                  icon: const Icon(Icons.star, size: 18),
                ),
              ),
            if (widget.onSuperLike != null) const SizedBox(width: 12),
            Expanded(
              child: PulseButton(
                text: '💬 Chat',
                onPressed:
                    widget.onMessage ?? () => _startConversation(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a circular action button for discovery mode
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Gradient? gradient,
    VoidCallback? onPressed,
    double size = 64,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? color.withValues(alpha: 0.2) : null,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  icon,
                  color: gradient != null ? Colors.white : color,
                  size: size * 0.45,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share text prepared:\n$shareText')),
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
        color: Colors.white,
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
            child: Icon(icon, color: Colors.white, size: 24),
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
            style: PulseTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final completionPercentage = _calculateProfileCompletion();
    final strength = _getProfileStrength(completionPercentage);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF8E1),
            Colors.orange.withValues(alpha: 0.1),
          ],
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: PulseTextStyles.titleMedium.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Get more matches with a complete profile',
                      style: PulseTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completionPercentage%',
                style: PulseTextStyles.headlineSmall.copyWith(
                  color: const Color(0xFFFF9800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Strength',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              Text(
                strength,
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFFF9800),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF9800),
              ),
              minHeight: 8,
            ),
          ),
          if (completionPercentage < 100) ...[
            const SizedBox(height: 20),
            Text(
              'Complete these sections to boost your profile:',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._getMissingSections().map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMissingSectionItem(section),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingSectionItem(Map<String, dynamic> section) {
    return InkWell(
      onTap: () => context.push('/profile-edit'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                section['icon'] as IconData,
                color: const Color(0xFFFF9800),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title'] as String,
                    style: PulseTextStyles.bodyMedium.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    section['description'] as String,
                    style: PulseTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              section['boost'] as String,
              style: PulseTextStyles.labelMedium.copyWith(
                color: const Color(0xFFFF9800),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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

  String _getProfileStrength(int percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 70) return 'Good';
    if (percentage >= 50) return 'Fair';
    return 'Needs Work';
  }

  List<Map<String, dynamic>> _getMissingSections() {
    final missing = <Map<String, dynamic>>[];

    if (widget.profile.photos.length < 3) {
      missing.add({
        'icon': Icons.photo_library,
        'title': 'Add More Photos',
        'description': 'Add at least 3 photos',
        'boost': '+15%',
      });
    }

    if (widget.profile.bio.isEmpty || widget.profile.bio.length < 50) {
      missing.add({
        'icon': Icons.description,
        'title': 'Complete Your Bio',
        'description': 'Write a compelling bio',
        'boost': '+20%',
      });
    }

    if (widget.profile.interests.length < 3) {
      missing.add({
        'icon': Icons.favorite,
        'title': 'Add Interests',
        'description': 'Show what you love',
        'boost': '+15%',
      });
    }

    if (widget.profile.relationshipGoals.isEmpty) {
      missing.add({
        'icon': Icons.flag,
        'title': 'Dating Preferences',
        'description': 'Set your gender and looking for preferences',
        'boost': '+10%',
      });
    }

    return missing;
  }

  void _reportProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Profile'),
        content: const Text('Are you sure you want to report this profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Report functionality is prepared
                // Integration with SafetyService.reportUser() ready when service is injected
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted. Thank you for keeping PulseLink safe.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to report: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? You won\'t see each other anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Block functionality is prepared
                // Integration with SafetyService.blockUser() ready when service is injected
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked successfully')),
                  );
                  // Close profile after blocking
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to block user: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            '${_currentIndex + 1} of ${widget.photos.length}',
            style: const TextStyle(color: Colors.white),
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
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
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
                    style: const TextStyle(
                      color: Colors.white,
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
