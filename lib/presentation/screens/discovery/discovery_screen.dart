import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/utils/haptic_feedback_utils.dart';
import '../../../data/services/boost_service.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../../services/discovery_prefetch_manager.dart';
import '../../blocs/boost/boost_bloc.dart';
import '../../blocs/boost/boost_event.dart';
import '../../blocs/boost/boost_state.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
import '../../blocs/discovery/discovery_state.dart';
import '../../widgets/boost/boost_banner_widget.dart';
import '../../widgets/boost/boost_confirmation_dialog.dart';
import '../../widgets/discovery/swipe_card.dart' as swipe_widget;
import '../../widgets/ai/floating_ai_button.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../ai_companion/ai_companion_screen.dart';

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

    // Initialize with smooth entrance animation and load user preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerController.forward();
      _loadDiscoveryWithPreferences();
      
      // Prefetch discovery images on screen entry for instant loading
      // This will use cached profiles from app launch and prefetch images
      _prefetchDiscoveryImages();
    });
  }

  /// Prefetch discovery profile images when screen is entered
  ///
  /// This ensures that discovery profile images are cached and ready,
  /// providing zero-wait-time experience when swiping through profiles.
  void _prefetchDiscoveryImages() {
    if (!mounted) return;

    // Prefetch with context for image caching
    // This will use cached profiles from app launch/background sync
    DiscoveryPrefetchManager.instance
        .prefetchProfilesWithImages(context)
        .catchError((error) {
          // Silently fail - this is a performance optimization, not critical
          debugPrint('Discovery image prefetch error: $error');
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

      // Haptic feedback for swipe action
      switch (direction) {
        case SwipeAction.left:
          PulseHaptics.swipeLeft();
          break;
        case SwipeAction.right:
          PulseHaptics.swipeRight();
          break;
        case SwipeAction.up:
          PulseHaptics.swipeUp();
          break;
      }

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
      
      // Trigger rewind event through DiscoveryBloc
      context.read<DiscoveryBloc>().add(const UndoLastSwipe());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BoostBloc(BoostService())..add(CheckBoostStatus()),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: PulseGradients.background),
          child: BlocListener<DiscoveryBloc, DiscoveryState>(
            listener: (context, state) {
              // Handle rewind success/error feedback
              if (state is DiscoveryLoaded && state.rewindJustCompleted) {
              // Rewind was successful
              PulseToast.success(
                context,
                message: 'Rewound last action',
                duration: const Duration(seconds: 2),
              );

              // Reset the flag to prevent showing the toast again
              context.read<DiscoveryBloc>().add(const ClearRewindFlag());
            }
            
            // Handle boost success feedback
            if (state is DiscoveryBoostActivated) {
              PulseToast.success(
                context,
                message: 'Boost activated for ${state.boostDuration.inMinutes} minutes!',
                duration: const Duration(seconds: 3),
              );
            }
            
            // Handle errors
            if (state is DiscoveryError) {
              PulseToast.error(
                context,
                message: state.message,
                duration: const Duration(seconds: 3),
              );
            }
          },
          child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Modern curved header
                  _buildModernHeader(),

                    // Boost banner (appears below header when boost is active)
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      child: const BoostBannerWidget(),
                    ),

                  // Main content area
                  Positioned.fill(top: 120, child: _buildMainContent(state)),

                  // Enhanced action buttons
                  if (state is DiscoveryLoaded && state.hasUsers)
                    _buildModernActionButtons(),

                    // Floating boost button (bottom-right corner)
                    if (state is DiscoveryLoaded && state.hasUsers)
                      _buildFloatingBoostButton(),

                  // Floating AI Companion button (QUICK WIN - Easy AI access)
                  if (state is DiscoveryLoaded && state.hasUsers)
                    const Positioned(
                      left: 16,
                      bottom: 140,
                      child: FloatingAIButton(),
                    ),

                  // Match celebration
                  if (state is DiscoveryMatchFound) _buildMatchDialog(state),
                ],
                ); // Stack
              }, // BlocBuilder builder
            ), // BlocBuilder
          ), // BlocListener child
        ), // Container (Scaffold body)
      ), // Scaffold
    ); // BlocProvider child
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
                      onTap: _showFiltersModal,
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    _buildHeaderButton(
                      icon: PulseIcons.ai,
                      color: PulseColors.accent,
                      onTap: _showAICompanionModal,
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    _buildHeaderButton(
                      icon: PulseIcons.notifications,
                      color: PulseColors.grey600,
                      onTap: _showNotificationsModal,
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          PulseSpacing.lg,
          PulseSpacing.xl,
          PulseSpacing.lg,
          100,
        ),
        child: const ProfileCardSkeleton(),
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
    
    return Padding(
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
            SizedBox.expand(
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
            SizedBox.expand(
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
          SizedBox.expand(
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
                            // Pass swipe handlers for profile detail page buttons
                            onSwipeLeft: () => _executeSwipe(SwipeAction.left),
                            onSwipeRight: () =>
                                _executeSwipe(SwipeAction.right),
                            onSwipeUp: () => _executeSwipe(SwipeAction.up),
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
    );
  }

  Widget _buildModernActionButtons() {
    return Positioned(
      bottom:
          0, // Optimal balance: clear navigation bar + comfortable thumb reach
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: PulseSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        ),
        decoration: BoxDecoration(
          color: PulseColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(PulseBorderRadius.xl),
          border: Border.all(
            color: PulseColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
                HapticFeedback.heavyImpact();
                // Trigger boost event through DiscoveryBloc
                context.read<DiscoveryBloc>().add(const UseBoost());
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
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DiscoveryBloc>().add(
          const LoadDiscoverableUsers(resetStack: true),
        );
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: EmptyStates.noMoreProfiles(
            onAdjustFilters: () => context.push('/filters'),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(DiscoveryError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: PulseColors.reject.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: PulseColors.reject,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Text(
              'Something went wrong',
              style: PulseTypography.h4.copyWith(color: PulseColors.grey900),
            ),
            const SizedBox(height: PulseSpacing.sm),
            Text(
              state.message,
              style: PulseTypography.bodyMedium.copyWith(
                color: PulseColors.grey600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: PulseSpacing.lg),
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
      ),
    );
  }

  /// Build floating boost button for profile visibility boost
  Widget _buildFloatingBoostButton() {
    return BlocBuilder<BoostBloc, BoostState>(
      builder: (context, boostState) {
        // Hide button if boost is already active
        if (boostState is BoostActive) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 120, // Above action buttons
          right: 20,
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();

              // Show confirmation dialog
              final confirmed = await BoostConfirmationDialog.show(context);

              if (confirmed == true && context.mounted) {
                // Activate boost
                context.read<BoostBloc>().add(ActivateBoost());
              }
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [PulseColors.primary, PulseColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PulseColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
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

  // Modal/Overlay Methods
  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: PulseColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(PulseSpacing.xl),
              topRight: Radius.circular(PulseSpacing.xl),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: PulseSpacing.md),
                decoration: BoxDecoration(
                  color: PulseColors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(PulseSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: PulseTypography.h3.copyWith(
                        color: PulseColors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: PulseColors.grey600),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PulseSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection('Age Range', '18 - 35'),
                      _buildFilterSection('Distance', 'Within 50 km'),
                      _buildFilterSection(
                        'Interests',
                        'Music, Travel, Fitness',
                      ),
                      _buildFilterSection('Education', 'Any'),
                      _buildFilterSection(
                        'Looking for',
                        'Long-term relationship',
                      ),
                      const SizedBox(height: PulseSpacing.xl),
                      // Apply filters button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Apply filters logic here
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: PulseColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: PulseSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                PulseSpacing.md,
                              ),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: PulseTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Bottom padding to ensure button is accessible
                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom +
                            PulseSpacing.lg,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAICompanionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: PulseColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(PulseSpacing.xl),
              topRight: Radius.circular(PulseSpacing.xl),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: PulseSpacing.md),
                decoration: BoxDecoration(
                  color: PulseColors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(PulseSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Companion',
                      style: PulseTypography.h3.copyWith(
                        color: PulseColors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: PulseColors.grey600),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PulseSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Dating Coach section
                      Container(
                        padding: const EdgeInsets.all(PulseSpacing.lg),
                        decoration: BoxDecoration(
                          color: PulseColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(PulseSpacing.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your AI Dating Coach',
                              style: PulseTypography.h4.copyWith(
                                color: PulseColors.accent,
                              ),
                            ),
                            const SizedBox(height: PulseSpacing.sm),
                            Text(
                              'Get personalized advice, conversation starters, and dating insights powered by AI.',
                              style: PulseTypography.bodyMedium.copyWith(
                                color: PulseColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: PulseSpacing.lg),
                      // AI Features
                      _buildAIFeature(
                        '💬',
                        'Conversation Starters',
                        'Get personalized icebreakers',
                      ),
                      _buildAIFeature(
                        '📊',
                        'Profile Analysis',
                        'Optimize your dating profile',
                      ),
                      _buildAIFeature(
                        '💡',
                        'Dating Tips',
                        'Personalized advice for better matches',
                      ),
                      _buildAIFeature(
                        '🎯',
                        'Match Insights',
                        'Understand compatibility scores',
                      ),
                      const SizedBox(height: PulseSpacing.xl),
                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AiCompanionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: PulseColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: PulseSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                PulseSpacing.md,
                              ),
                            ),
                          ),
                          child: Text(
                            'Start Chat with AI Companion',
                            style: PulseTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Bottom padding to ensure button is accessible
                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom +
                            PulseSpacing.lg,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: PulseColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(PulseSpacing.xl),
              topRight: Radius.circular(PulseSpacing.xl),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: PulseSpacing.md),
                decoration: BoxDecoration(
                  color: PulseColors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(PulseSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: PulseTypography.h3.copyWith(
                        color: PulseColors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: PulseColors.grey600),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PulseSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationItem(
                        'New Match! 💕',
                        'You and Sarah have matched',
                        '2 minutes ago',
                        true,
                      ),
                      _buildNotificationItem(
                        'Message from Alex',
                        'Hey! How\'s your day going?',
                        '1 hour ago',
                        true,
                      ),
                      _buildNotificationItem(
                        'Profile View',
                        'Mike viewed your profile',
                        '3 hours ago',
                        false,
                      ),
                      _buildNotificationItem(
                        'Event Reminder',
                        'Coffee meetup starts in 30 minutes',
                        '5 hours ago',
                        false,
                      ),
                      _buildNotificationItem(
                        'Like Received',
                        'Someone liked your profile',
                        '1 day ago',
                        false,
                      ),
                      _buildNotificationItem(
                        'Profile Boost',
                        'Your profile was boosted successfully',
                        '2 days ago',
                        false,
                      ),
                      // Bottom padding to ensure content is accessible
                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom +
                            PulseSpacing.lg,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PulseSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: PulseTypography.bodyMedium.copyWith(
              color: PulseColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: PulseTypography.bodyMedium.copyWith(
              color: PulseColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeature(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PulseSpacing.md),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PulseTypography.bodyMedium.copyWith(
                    color: PulseColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: PulseTypography.labelMedium.copyWith(
                    color: PulseColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    bool isUnread,
  ) {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      margin: const EdgeInsets.only(bottom: PulseSpacing.sm),
      decoration: BoxDecoration(
        color: isUnread
            ? PulseColors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(PulseSpacing.sm),
        border: Border.all(
          color: isUnread
              ? PulseColors.primary.withValues(alpha: 0.2)
              : PulseColors.grey200,
        ),
      ),
      child: Row(
        children: [
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: PulseColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          if (isUnread) const SizedBox(width: PulseSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PulseTypography.bodyMedium.copyWith(
                    color: PulseColors.black,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: PulseTypography.labelMedium.copyWith(
                    color: PulseColors.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: PulseTypography.labelSmall.copyWith(
                    color: PulseColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Load discovery with user's saved filter preferences
  void _loadDiscoveryWithPreferences() {
    // Add event to load discoverable users with preferences
    // The DiscoveryBloc will handle loading preferences internally
    context.read<DiscoveryBloc>().add(
      const LoadDiscoverableUsersWithPreferences(),
    );
  }
}
