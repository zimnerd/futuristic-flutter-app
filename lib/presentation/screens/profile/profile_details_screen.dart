import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../../domain/entities/user_profile.dart';
import 'enhanced_profile_edit_screen.dart';

/// Comprehensive profile details screen with social media style layout
class ProfileDetailsScreen extends StatefulWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onLike;
  final VoidCallback? onMessage;
  final VoidCallback? onSuperLike;

  const ProfileDetailsScreen({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onLike,
    this.onMessage,
    this.onSuperLike,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  
  int _currentPhotoIndex = 0;
  bool _showPhotosFullscreen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _onPhotoTap() {
    setState(() {
      _showPhotosFullscreen = true;
    });
  }

  void _onLikeTap() {
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_showPhotosFullscreen) {
      return _buildFullscreenPhotos();
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        if (widget.isOwnProfile)
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EnhancedProfileEditScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          )
        else
          IconButton(
            onPressed: () {
              // Show more options
            },
            icon: const Icon(Icons.more_vert),
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
                    height: 3,
                    margin: EdgeInsets.only(
                      right: entry.key < widget.profile.photos.length - 1 ? 4 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isActive 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentPhotoIndex + 1}/${widget.profile.photos.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
    return Padding(
      padding: const EdgeInsets.all(20),
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
                        Text(
                          widget.profile.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.profile.verified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: PulseColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.profile.age} years old',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isOwnProfile)
                AnimatedBuilder(
                  animation: _likeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _likeAnimation.value,
                      child: InkWell(
                        onTap: _onLikeTap,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [PulseColors.primary, PulseColors.secondary],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: PulseColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationRow(),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.grey[500],
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '2 km away', // This would be calculated
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        if (widget.profile.isOnline) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: PulseColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Online now',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ] else ...[
          Icon(
            Icons.access_time,
            color: Colors.grey[500],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Active 2 hours ago', // This would be calculated
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutSection() {
    if (widget.profile.bio.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.profile.bio,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
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
      details.add(_buildDetailItem(Icons.work, 'Job', widget.profile.job!));
    }
    if (widget.profile.company?.isNotEmpty == true) {
      details.add(_buildDetailItem(Icons.business, 'Company', widget.profile.company!));
    }
    if (widget.profile.school?.isNotEmpty == true) {
      details.add(_buildDetailItem(Icons.school, 'Education', widget.profile.school!));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.profile.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary.withValues(alpha: 0.1),
                      PulseColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PulseColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: PulseColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                      _showPhotosFullscreen = true;
                    });
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: PulseButton(
              text: 'Super Like',
              onPressed: widget.onSuperLike,
              variant: PulseButtonVariant.secondary,
              icon: const Icon(Icons.star, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PulseButton(
              text: 'Message',
              onPressed: widget.onMessage,
              icon: const Icon(Icons.chat_bubble, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenPhotos() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            setState(() {
              _showPhotosFullscreen = false;
            });
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
          setState(() {
            _currentPhotoIndex = index;
          });
        },
        itemCount: widget.profile.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.profile.photos[index];
          return Center(
            child: Hero(
              tag: 'profile-photo-${photo.id}',
              child: InteractiveViewer(
                child: _buildPhotoWidget(photo),
              ),
            ),
          );
        },
      ),
    );
  }
}
