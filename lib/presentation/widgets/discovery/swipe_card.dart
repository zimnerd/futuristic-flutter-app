import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/user_profile.dart';

/// Swipeable card widget that displays user profile information
/// 
/// Features:
/// - Beautiful photo display with smooth animations
/// - User information overlay
/// - Swipe gestures (left/right/up)
/// - Loading and error states
/// - Premium features indicators
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.user,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onTap,
    this.isAnimating = false,
    this.swipeProgress = 0.0,
    this.swipeDirection,
    this.showDetails = true,
  });

  final UserProfile user;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onTap;
  final bool isAnimating;
  final double swipeProgress; // -1.0 to 1.0 (left to right)
  final SwipeDirection? swipeDirection;
  final bool showDetails;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with TickerProviderStateMixin {
  late AnimationController _photoController;
  late AnimationController _overlayController;
  late Animation<double> _scaleAnimation;
  
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _photoController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _photoController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _photoController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _nextPhoto() {
    if (_currentPhotoIndex < widget.user.photos.length - 1) {
      setState(() {
        _currentPhotoIndex++;
      });
    }
  }

  void _previousPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() {
        _currentPhotoIndex--;
      });
    }
  }

  void _toggleOverlay() {
    if (_overlayController.isCompleted) {
      _overlayController.reverse();
    } else {
      _overlayController.forward();
    }
  }

  Widget _buildPhotoIndicators() {
    if (widget.user.photos.length <= 1) return const SizedBox.shrink();
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(
          widget.user.photos.length,
          (index) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(
                right: index < widget.user.photos.length - 1 ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: index == _currentPhotoIndex 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeOverlay() {
    if (widget.swipeDirection == null || widget.swipeProgress.abs() < 0.1) {
      return const SizedBox.shrink();
    }

    final opacity = (widget.swipeProgress.abs() * 2).clamp(0.0, 1.0);
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: _getSwipeColor().withValues(alpha: opacity * 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _getSwipeColor(),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSwipeIcon(),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _getSwipeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSwipeColor() {
    switch (widget.swipeDirection) {
      case SwipeDirection.left:
        return const Color(0xFFFF4458);
      case SwipeDirection.right:
        return const Color(0xFF66D7A2);
      case SwipeDirection.up:
        return const Color(0xFF4FC3F7);
      default:
        return Colors.grey;
    }
  }

  IconData _getSwipeIcon() {
    switch (widget.swipeDirection) {
      case SwipeDirection.left:
        return Icons.close;
      case SwipeDirection.right:
        return Icons.favorite;
      case SwipeDirection.up:
        return Icons.star;
      default:
        return Icons.help;
    }
  }

  String _getSwipeLabel() {
    switch (widget.swipeDirection) {
      case SwipeDirection.left:
        return 'NOPE';
      case SwipeDirection.right:
        return 'LIKE';
      case SwipeDirection.up:
        return 'SUPER LIKE';
      default:
        return '';
    }
  }

  Widget _buildUserInfo() {
    if (!widget.showDetails) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.user.nameWithAge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                if (widget.user.isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.user.distanceString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.user.distanceString,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (widget.user.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.user.bio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.user.interests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.user.interests.take(3).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.user.photos.isNotEmpty 
        ? widget.user.photos[_currentPhotoIndex]
        : null;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap ?? _toggleOverlay,
            onTapDown: (_) => _photoController.forward(),
            onTapUp: (_) => _photoController.reverse(),
            onTapCancel: () => _photoController.reverse(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Photo background
                    Positioned.fill(
                      child: currentPhoto != null
                          ? CachedNetworkImage(
                              imageUrl: currentPhoto.url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                    
                    // Photo navigation areas (invisible)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 100, // Leave space for user info
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: GestureDetector(
                        onTap: _previousPhoto,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 100,
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: GestureDetector(
                        onTap: _nextPhoto,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    
                    // Photo indicators
                    _buildPhotoIndicators(),
                    
                    // Swipe overlay
                    _buildSwipeOverlay(),
                    
                    // User information
                    _buildUserInfo(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Direction of swipe gesture
enum SwipeDirection {
  left,
  right,
  up,
}
