import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
import '../../blocs/discovery/discovery_state.dart';
import '../../widgets/discovery/swipe_card.dart' as swipe_widget;

/// Modern Discovery Screen - PulseLink's unique swipe interface
/// 
/// Features:
/// - Smooth Tinder-like card animations with improved physics
/// - Modern action buttons with rewind functionality
/// - Glassmorphism header design with curved aesthetics
/// - Enhanced performance with optimized gesture handling
/// - Unique PulseLink branding and color scheme
///
/// Design Philosophy:
/// - Maximum screen real estate utilization
/// - Intuitive gesture controls with haptic feedback
/// - Modern curved UI elements inspired by fitness apps
/// - Accessible and inclusive design patterns
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _actionController;
  late AnimationController _headerController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardRotationAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _actionScaleAnimation;
  late Animation<double> _headerOpacityAnimation;
  
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  SwipeAction? _currentSwipeDirection;
  final List<SwipeAction> _rewindHistory = [];

  @override
  void initState() {
    super.initState();
    
    // Enhanced animation controllers for smoother interactions
    _cardController = AnimationController(
      duration: PulseAnimations.cardSwipe,
      vsync: this,
    );
    
    _actionController = AnimationController(
      duration: PulseAnimations.buttonPress,
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: PulseAnimations.cardEntry,
      vsync: this,
    );

    // Improved card animations with better easing
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _cardController,
            curve: PulseAnimations.smoothCurve,
    ));
    
    _cardRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _cardController,
        curve: PulseAnimations.smoothCurve,
      ),
    );

    _cardScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: PulseAnimations.smoothCurve,
    ));
    
    _actionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _actionController,
        curve: PulseAnimations.bouncyCurve,
    ));
    
    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: PulseAnimations.smoothCurve,
      ),
    );

    // Initialize with smooth entrance animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerController.forward();
      context.read<DiscoveryBloc>().add(const LoadDiscoverableUsers());
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _actionController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // Enhanced gesture handling with improved physics
  void _handlePanStart(DragStartDetails details) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isDragging = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final deltaX = details.delta.dx / screenWidth;
    final deltaY = details.delta.dy / MediaQuery.of(context).size.height;
    
    setState(() {
      _dragOffset += Offset(deltaX, deltaY);
      
      // Enhanced direction detection with better thresholds
      if (_dragOffset.dx.abs() > 0.08 || _dragOffset.dy.abs() > 0.08) {
        if (_dragOffset.dy < -0.15) {
          _currentSwipeDirection = SwipeAction.up;
        } else if (_dragOffset.dx > 0.15) {
          _currentSwipeDirection = SwipeAction.right;
        } else if (_dragOffset.dx < -0.15) {
          _currentSwipeDirection = SwipeAction.left;
        } else {
          _currentSwipeDirection = null;
        }
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!mounted) return;
    
    // Improved swipe detection with velocity consideration
    final shouldSwipe =
        _dragOffset.dx.abs() > 0.35 ||
        _dragOffset.dy < -0.25 ||
        details.velocity.pixelsPerSecond.dx.abs() > 500;
    
    if (shouldSwipe && _currentSwipeDirection != null) {
      HapticFeedback.mediumImpact();
      _executeSwipe(_currentSwipeDirection!);
    } else {
      // Smooth snap back animation
      HapticFeedback.lightImpact();
      setState(() {
        _dragOffset = Offset.zero;
        _currentSwipeDirection = null;
        _isDragging = false;
      });
    }
  }

  void _executeSwipe(SwipeAction direction) {
    if (!mounted) return;
    final discoveryBloc = context.read<DiscoveryBloc>();
    final state = discoveryBloc.state;
    
    if (state is DiscoveryLoaded && state.currentUser != null) {
      final user = state.currentUser!;
      
      // Add to rewind history
      _rewindHistory.add(direction);
      if (_rewindHistory.length > 10) {
        _rewindHistory.removeAt(0);
      }

      // Configure direction-specific animation with smoother curves
      late Animation<Offset> directionAnimation;
      late Animation<double> rotationAnimation;
      
      switch (direction) {
        case SwipeAction.left:
          directionAnimation =
              Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-1.8, 0.2),
              ).animate(
                CurvedAnimation(
                  parent: _cardController,
                  curve: PulseAnimations.smoothCurve,
                ),
              );
          rotationAnimation = Tween<double>(begin: 0, end: -0.4).animate(
            CurvedAnimation(
              parent: _cardController,
              curve: PulseAnimations.smoothCurve,
            ),
          );
          break;
        case SwipeAction.right:
          directionAnimation =
              Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(1.8, 0.2),
              ).animate(
                CurvedAnimation(
                  parent: _cardController,
                  curve: PulseAnimations.smoothCurve,
                ),
              );
          rotationAnimation = Tween<double>(begin: 0, end: 0.4).animate(
            CurvedAnimation(
              parent: _cardController,
              curve: PulseAnimations.smoothCurve,
            ),
          );
          break;
        case SwipeAction.up:
          directionAnimation =
              Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0, -2.0),
              ).animate(
                CurvedAnimation(
                  parent: _cardController,
                  curve: PulseAnimations.bouncyCurve,
                ),
              );
          rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
            CurvedAnimation(
              parent: _cardController,
              curve: PulseAnimations.smoothCurve,
            ),
          );
          break;
      }
      
      // Update animations
      _cardSlideAnimation = directionAnimation;
      _cardRotationAnimation = rotationAnimation;
      
      // Smooth exit animation
      _cardController.forward().then((_) {
        if (!mounted) return;
        _cardController.reset();
        setState(() {
          _dragOffset = Offset.zero;
          _currentSwipeDirection = null;
          _isDragging = false;
        });
      });
      
      // Execute swipe action and track for rewind
      _rewindHistory.add(direction);
      switch (direction) {
        case SwipeAction.left:
          discoveryBloc.add(SwipeLeft(user));
          break;
        case SwipeAction.right:
          discoveryBloc.add(SwipeRight(user));
          break;
        case SwipeAction.up:
          discoveryBloc.add(SwipeUp(user));
          break;
      }
    }
  }

  void _handleActionTap(SwipeAction direction) {
    HapticFeedback.mediumImpact();
    _actionController.forward().then((_) {
      if (mounted) _actionController.reverse();
    });
    _executeSwipe(direction);
  }

  void _handleRewind() {
    if (_rewindHistory.isNotEmpty) {
      HapticFeedback.heavyImpact();
      _rewindHistory.removeLast();
      // TODO: Implement rewind logic with backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rewound last action'),
          backgroundColor: PulseColors.rewind,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PulseGradients.background),
        child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Modern curved header
                _buildModernHeader(),

                // Main content area
                Positioned.fill(top: 120, child: _buildMainContent(state)),

                // Enhanced action buttons
                if (state is DiscoveryLoaded && state.hasUsers)
                  _buildModernActionButtons(),

                // Match celebration
                if (state is DiscoveryMatchFound) _buildMatchDialog(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return AnimatedBuilder(
      animation: _headerOpacityAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: PulseDecorations.glassmorphism(
              color: PulseColors.white,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PulseSpacing.lg,
                  vertical: PulseSpacing.sm,
                ),
                child: Row(
                  children: [
                    // App title with modern typography
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Good ${_getTimeOfDay()}',
                            style: PulseTypography.bodyMedium.copyWith(
                              color: PulseColors.grey600,
                            ),
                          ),
                          Text(
                            'Ready to explore?',
                            style: PulseTypography.h3.copyWith(
                              color: PulseColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Header action buttons
                    _buildHeaderButton(
                      icon: PulseIcons.filters,
                      color: PulseColors.primary,
                      onTap: () {
                        // TODO: Open filters
                      },
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    _buildHeaderButton(
                      icon: PulseIcons.ai,
                      color: PulseColors.accent,
                      onTap: () {
                        // TODO: Open AI settings
                      },
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    _buildHeaderButton(
                      icon: PulseIcons.notifications,
                      color: PulseColors.grey600,
                      onTap: () {
                        // TODO: Open notifications
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(PulseBorderRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildMainContent(DiscoveryState state) {
    if (state is DiscoveryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PulseColors.primary),
      );
    } else if (state is DiscoveryLoaded && state.hasUsers) {
      return _buildCardStack(state);
    } else if (state is DiscoveryEmpty) {
      return _buildEmptyState();
    } else if (state is DiscoveryError) {
      return _buildErrorState(state);
    }
    return const SizedBox.shrink();
  }

  Widget _buildCardStack(DiscoveryLoaded state) {
    final users = state.userStack;
    if (users.isEmpty) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PulseSpacing.lg,
          0,
          PulseSpacing.lg,
          100, // Space for modern action buttons
        ),
        child: Stack(
          children: [
            // Background cards with modern stacking effect
            if (users.length > 1)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.96,
                  child: Transform.translate(
                    offset: const Offset(0, 4),
                    child: Container(
                      decoration: PulseDecorations.swipeCard(),
                      child: swipe_widget.SwipeCard(
                        user: users[1],
                        showDetails: false,
                      ),
                    ),
                  ),
                ),
              ),
            
            if (users.length > 2)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.92,
                  child: Transform.translate(
                    offset: const Offset(0, 8),
                    child: Container(
                      decoration: PulseDecorations.swipeCard(),
                      child: swipe_widget.SwipeCard(
                        user: users[2],
                        showDetails: false,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Main interactive card
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _cardSlideAnimation,
                    _cardRotationAnimation,
                    _cardScaleAnimation,
                  ]),
                  builder: (context, child) {
                    final offset = _isDragging
                        ? Offset(
                            _dragOffset.dx * MediaQuery.of(context).size.width,
                            _dragOffset.dy * MediaQuery.of(context).size.height,
                          )
                        : _cardSlideAnimation.value *
                              MediaQuery.of(context).size.width;

                    final rotation = _isDragging
                        ? _dragOffset.dx * 0.5
                        : _cardRotationAnimation.value;

                    final scale = _isDragging
                        ? 1.0 - (_dragOffset.dx.abs() * 0.05)
                        : _cardScaleAnimation.value;

                    return Transform.translate(
                      offset: offset,
                      child: Transform.scale(
                        scale: scale,
                        child: Transform.rotate(
                          angle: rotation,
                          child: Container(
                            decoration: PulseDecorations.swipeCard(),
                            child: swipe_widget.SwipeCard(
                              user: users[0],
                              showDetails: true,
                              swipeProgress: _dragOffset.dx,
                              swipeDirection: _convertToWidgetSwipeDirection(
                                _currentSwipeDirection,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionButtons() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: PulseSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        ),
        decoration: PulseDecorations.glassmorphism(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Rewind button
            _buildActionButton(
              config: ActionButtonConfig.rewind,
              isActive: _currentSwipeDirection == null,
              onTap: _handleRewind,
            ),
            
            // Pass button
            _buildActionButton(
              config: ActionButtonConfig.pass,
              isActive: _currentSwipeDirection == SwipeAction.left,
              onTap: () => _handleActionTap(SwipeAction.left),
            ),
            
            // Super like button
            _buildActionButton(
              config: ActionButtonConfig.superLike,
              isActive: _currentSwipeDirection == SwipeAction.up,
              onTap: () => _handleActionTap(SwipeAction.up),
            ),
            
            // Like button
            _buildActionButton(
              config: ActionButtonConfig.like,
              isActive: _currentSwipeDirection == SwipeAction.right,
              onTap: () => _handleActionTap(SwipeAction.right),
            ),
            
            // Boost button
            _buildActionButton(
              config: ActionButtonConfig.boost,
              isActive: false,
              onTap: () {
                // TODO: Implement boost
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Boost feature coming soon!'),
                    backgroundColor: PulseColors.accent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required ActionButtonConfig config,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _actionScaleAnimation,
      builder: (context, child) {
        final scale = isActive ? _actionScaleAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) => HapticFeedback.lightImpact(),
            onTap: onTap,
            child: Container(
              width: config.size,
              height: config.size,
              decoration: PulseDecorations.actionButton(
                color: config.color,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: config.color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : PulseShadows.button,
              ),
              child: Icon(
                config.icon,
                color: config.color,
                size: config.size * 0.4,
              ),
            ),
          ),
        );
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
              gradient: PulseGradients.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_off,
              size: 60,
              color: PulseColors.white,
            ),
          ),
          const SizedBox(height: PulseSpacing.xl),
          Text(
            'No more profiles',
            style: PulseTypography.h3.copyWith(color: PulseColors.grey900),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Check back later for new matches!',
            style: PulseTypography.bodyMedium.copyWith(
              color: PulseColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.xl),
          ElevatedButton(
            onPressed: () {
              context.read<DiscoveryBloc>().add(
                const LoadDiscoverableUsers(resetStack: true),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: PulseColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: PulseSpacing.xl,
                vertical: PulseSpacing.md,
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DiscoveryError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PulseColors.reject.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: PulseColors.reject,
            ),
          ),
          const SizedBox(height: PulseSpacing.xl),
          Text(
            'Something went wrong',
            style: PulseTypography.h3.copyWith(color: PulseColors.grey900),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            state.message,
            style: PulseTypography.bodyMedium.copyWith(
              color: PulseColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.xl),
          ElevatedButton(
            onPressed: () {
              context.read<DiscoveryBloc>().add(
                const LoadDiscoverableUsers(resetStack: true),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: PulseColors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDialog(DiscoveryMatchFound state) {
    return Positioned.fill(
      child: Container(
        color: PulseColors.black.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(PulseSpacing.xl),
            padding: const EdgeInsets.all(PulseSpacing.xl),
            decoration: PulseDecorations.swipeCard(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: PulseGradients.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: PulseColors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: PulseSpacing.lg),
                Text(
                  'It\'s a Match!',
                  style: PulseTypography.h2.copyWith(
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: PulseSpacing.sm),
                Text(
                  'You and ${state.matchedUser.name} liked each other',
                  style: PulseTypography.bodyMedium.copyWith(
                    color: PulseColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: PulseSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Continue swiping
                          context.read<DiscoveryBloc>().add(
                            const DismissMatch(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.grey200,
                          foregroundColor: PulseColors.grey700,
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(width: PulseSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Go to chat
                          context.go('/chat/${state.matchedUser.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: PulseColors.white,
                        ),
                        child: const Text('Say Hi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  swipe_widget.SwipeDirection? _convertToWidgetSwipeDirection(
    SwipeAction? action,
  ) {
    if (action == null) return null;
    switch (action) {
      case SwipeAction.left:
        return swipe_widget.SwipeDirection.left;
      case SwipeAction.right:
        return swipe_widget.SwipeDirection.right;
      case SwipeAction.up:
        return swipe_widget.SwipeDirection.up;
    }
  }
}
