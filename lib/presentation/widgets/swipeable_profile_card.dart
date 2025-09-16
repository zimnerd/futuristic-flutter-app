import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common/robust_network_image.dart';

/// Enhanced swipeable card for dating profiles with gesture recognition
/// Supports like, pass, and super like actions with smooth animations
class SwipeableProfileCard extends StatefulWidget {
  const SwipeableProfileCard({
    super.key,
    required this.profile,
    required this.onSwipe,
    this.onTap,
    this.isTop = false,
  });

  final ProfileCardData profile;
  final Function(SwipeDirection direction) onSwipe;
  final VoidCallback? onTap;
  final bool isTop;

  @override
  State<SwipeableProfileCard> createState() => _SwipeableProfileCardState();
}

class _SwipeableProfileCardState extends State<SwipeableProfileCard>
    with TickerProviderStateMixin {
  late AnimationController _positionController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  Offset _panStart = Offset.zero;
  Offset _panUpdate = Offset.zero;
  bool _isDragging = false;

  // Swipe thresholds
  static const double _swipeThreshold = 100.0;
  static const double _superLikeThreshold = -150.0;
  static const double _rotationFactor = 0.3;

  @override
  void initState() {
    super.initState();
    
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _panStart = details.localPosition;
    _isDragging = true;
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _panUpdate = details.localPosition - _panStart;
    });

    // Provide haptic feedback for swipe directions
    if (_panUpdate.dx.abs() > 50 || _panUpdate.dy.abs() > 50) {
      if (_panUpdate.dx > 50) {
        // Like direction
        HapticFeedback.selectionClick();
      } else if (_panUpdate.dx < -50) {
        // Pass direction
        HapticFeedback.selectionClick();
      } else if (_panUpdate.dy < -100) {
        // Super like direction
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _scaleController.reverse();

    final velocity = details.velocity.pixelsPerSecond;
    final cardSize = MediaQuery.of(context).size;

    // Determine swipe direction based on position and velocity
    SwipeDirection? direction;

    if (_panUpdate.dy < _superLikeThreshold && velocity.dy < -300) {
      direction = SwipeDirection.up; // Super like
    } else if (_panUpdate.dx > _swipeThreshold || velocity.dx > 300) {
      direction = SwipeDirection.right; // Like
    } else if (_panUpdate.dx < -_swipeThreshold || velocity.dx < -300) {
      direction = SwipeDirection.left; // Pass
    }

    if (direction != null) {
      _animateCardExit(direction, cardSize);
    } else {
      _resetCard();
    }
  }

  void _animateCardExit(SwipeDirection direction, Size cardSize) {
    Offset endPosition;
    double endRotation = 0;

    switch (direction) {
      case SwipeDirection.right:
        endPosition = Offset(cardSize.width, _panUpdate.dy);
        endRotation = 0.3;
        break;
      case SwipeDirection.left:
        endPosition = Offset(-cardSize.width, _panUpdate.dy);
        endRotation = -0.3;
        break;
      case SwipeDirection.up:
        endPosition = Offset(_panUpdate.dx, -cardSize.height);
        endRotation = _panUpdate.dx * 0.001;
        break;
    }

    _positionAnimation = Tween<Offset>(
      begin: _panUpdate,
      end: endPosition,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _panUpdate.dx * _rotationFactor / 1000,
      end: endRotation,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    _positionController.forward().then((_) {
      widget.onSwipe(direction);
    });
    _rotationController.forward();

    // Haptic feedback for completed swipe
    HapticFeedback.heavyImpact();
  }

  void _resetCard() {
    _positionAnimation = Tween<Offset>(
      begin: _panUpdate,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _panUpdate.dx * _rotationFactor / 1000,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    setState(() {
      _panUpdate = Offset.zero;
    });

    _positionController.forward();
    _rotationController.forward();
  }

  Color _getSwipeIndicatorColor() {
    if (_panUpdate.dy < _superLikeThreshold) {
      return Colors.blue;
    } else if (_panUpdate.dx > _swipeThreshold) {
      return Colors.green;
    } else if (_panUpdate.dx < -_swipeThreshold) {
      return Colors.red;
    }
    return Colors.transparent;
  }

  String _getSwipeIndicatorText() {
    if (_panUpdate.dy < _superLikeThreshold) {
      return 'SUPER LIKE';
    } else if (_panUpdate.dx > _swipeThreshold) {
      return 'LIKE';
    } else if (_panUpdate.dx < -_swipeThreshold) {
      return 'PASS';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _positionController,
        _scaleController,
        _rotationController,
      ]),
      builder: (context, child) {
        final position = _isDragging ? _panUpdate : _positionAnimation.value;
        final scale = _scaleAnimation.value;
        final rotation = _isDragging
            ? _panUpdate.dx * _rotationFactor / 1000
            : _rotationAnimation.value;

        return Transform.translate(
          offset: position,
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotation,
              child: GestureDetector(
                onPanStart: widget.isTop ? _onPanStart : null,
                onPanUpdate: widget.isTop ? _onPanUpdate : null,
                onPanEnd: widget.isTop ? _onPanEnd : null,
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // Main card
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildCardContent(),
                      ),
                    ),
                    
                    // Swipe indicator overlay
                    if (_isDragging && _getSwipeIndicatorText().isNotEmpty)
                      _buildSwipeIndicator(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: RobustNetworkImage(
            imageUrl: widget.profile.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
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
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Profile info
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.profile.name}, ${widget.profile.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.profile.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (widget.profile.bio.isNotEmpty)
                Text(
                  widget.profile.bio,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Text(
                widget.profile.distance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Photo dots indicator
        if (widget.profile.photoCount > 1)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildPhotoIndicator(),
          ),
      ],
    );
  }

  Widget _buildPhotoIndicator() {
    return Row(
      children: List.generate(
        widget.profile.photoCount,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(
              right: index < widget.profile.photoCount - 1 ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: index == widget.profile.currentPhotoIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final color = _getSwipeIndicatorColor();
    final text = _getSwipeIndicatorText();
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withValues(alpha: 0.1),
          border: Border.all(
            color: color,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Data model for profile cards
class ProfileCardData {
  const ProfileCardData({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrl,
    required this.distance,
    this.isVerified = false,
    this.photoCount = 1,
    this.currentPhotoIndex = 0,
    this.interests = const [],
  });

  final String id;
  final String name;
  final int age;
  final String bio;
  final String imageUrl;
  final String distance;
  final bool isVerified;
  final int photoCount;
  final int currentPhotoIndex;
  final List<String> interests;
}

/// Swipe direction enum
enum SwipeDirection {
  left,  // Pass
  right, // Like
  up,    // Super like
}
