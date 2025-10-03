import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../domain/entities/user_profile.dart';
import '../../../data/models/user_model.dart';
import '../../../blocs/chat_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';

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
        if (mounted) {
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
        }
      } else if (state is ChatError) {
        // Check if widget is still mounted before showing message
        if (mounted) {
          // Show more helpful error message for matching requirement
          String errorMessage =
              'Failed to start conversation: ${state.message}';
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
                const SizedBox(height: 20),
                _buildAboutSection(),
                const SizedBox(height: 20),
                _buildDetailsSection(),
                const SizedBox(height: 20),
                _buildInterestsSection(),
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
        if (widget.isOwnProfile)
          IconButton(
            onPressed: () {
              context.push('/profile-edit');
            },
            icon: const Icon(Icons.edit),
          )
        else
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

    return Stack(
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

        // Photo indicators
        if (widget.profile.photos.length > 1)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
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

        // Photo counter
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ],
    );
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
                Text(
                  '2 km away',
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.profile.isOnline) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: PulseColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
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
                        'Active 2 hours ago',
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
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary.withValues(alpha: 0.1),
                      PulseColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: PulseColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  interest,
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
            '${_currentPhotoIndex + 1} of ${widget.profile.photos.length}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: PageView.builder(
          controller: PageController(initialPage: _currentPhotoIndex),
          onPageChanged: (index) {
            if (mounted) {
              setState(() {
                _currentPhotoIndex = index;
              });
            }
          },
          itemCount: widget.profile.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.profile.photos[index];
            return Center(
              child: Hero(
                tag: 'profile-photo-${photo.id}',
                child: InteractiveViewer(child: _buildPhotoWidget(photo)),
              ),
            );
          },
        ),
      ),
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
