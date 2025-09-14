import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/discovery_service.dart';
import '../../blocs/discovery/discovery_bloc.dart';
import '../../blocs/discovery/discovery_event.dart';
import '../../blocs/discovery/discovery_state.dart';
import '../../widgets/discovery/swipe_card.dart';

/// Main discovery screen with swipeable user cards
/// 
/// Features:
/// - Swipeable card stack for user discovery
/// - Action buttons for like/pass/super like
/// - Filter and settings access
/// - Match celebration animations
/// - Boost feature integration
/// - Empty state handling
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _actionController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardRotationAnimation;
  late Animation<double> _actionScaleAnimation;
  
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  SwipeDirection? _currentSwipeDirection;

  @override
  void initState() {
    super.initState();
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _actionController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    ));
    
    _cardRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    ));
    
    _actionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _actionController,
      curve: Curves.elasticOut,
    ));

    // Load initial users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryBloc>().add(const LoadDiscoverableUsers());
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deltaX = details.delta.dx / screenWidth;
    final deltaY = details.delta.dy / MediaQuery.of(context).size.height;
    
    setState(() {
      _dragOffset += Offset(deltaX, deltaY);
      
      // Determine swipe direction
      if (_dragOffset.dx.abs() > 0.1 || _dragOffset.dy.abs() > 0.1) {
        if (_dragOffset.dy < -0.2) {
          _currentSwipeDirection = SwipeDirection.up;
        } else if (_dragOffset.dx > 0.2) {
          _currentSwipeDirection = SwipeDirection.right;
        } else if (_dragOffset.dx < -0.2) {
          _currentSwipeDirection = SwipeDirection.left;
        } else {
          _currentSwipeDirection = null;
        }
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final shouldSwipe = _dragOffset.dx.abs() > 0.4 || _dragOffset.dy < -0.3;
    
    if (shouldSwipe && _currentSwipeDirection != null) {
      _executeSwipe(_currentSwipeDirection!);
    } else {
      // Snap back to center
      setState(() {
        _dragOffset = Offset.zero;
        _currentSwipeDirection = null;
        _isDragging = false;
      });
    }
  }

  void _executeSwipe(SwipeDirection direction) {
    final discoveryBloc = context.read<DiscoveryBloc>();
    final state = discoveryBloc.state;
    
    if (state is DiscoveryLoaded && state.currentUser != null) {
      final user = state.currentUser!;
      
      // Trigger animation
      _cardController.forward().then((_) {
        _cardController.reset();
        setState(() {
          _dragOffset = Offset.zero;
          _currentSwipeDirection = null;
          _isDragging = false;
        });
      });
      
      // Execute swipe action
      switch (direction) {
        case SwipeDirection.left:
          discoveryBloc.add(SwipeLeft(user));
          break;
        case SwipeDirection.right:
          discoveryBloc.add(SwipeRight(user));
          break;
        case SwipeDirection.up:
          discoveryBloc.add(SwipeUp(user));
          break;
      }
    }
  }

  void _handleActionTap(SwipeDirection direction) {
    _actionController.forward().then((_) {
      _actionController.reverse();
    });
    _executeSwipe(direction);
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          AnimatedBuilder(
            animation: _actionScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentSwipeDirection == SwipeDirection.left 
                    ? _actionScaleAnimation.value 
                    : 1.0,
                child: GestureDetector(
                  onTap: () => _handleActionTap(SwipeDirection.left),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFFF4458),
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Super like button
          AnimatedBuilder(
            animation: _actionScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentSwipeDirection == SwipeDirection.up 
                    ? _actionScaleAnimation.value 
                    : 1.0,
                child: GestureDetector(
                  onTap: () => _handleActionTap(SwipeDirection.up),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Color(0xFF4FC3F7),
                      size: 25,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Like button
          AnimatedBuilder(
            animation: _actionScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentSwipeDirection == SwipeDirection.right 
                    ? _actionScaleAnimation.value 
                    : 1.0,
                child: GestureDetector(
                  onTap: () => _handleActionTap(SwipeDirection.right),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFF66D7A2),
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile/Settings button
          GestureDetector(
            onTap: () {
              context.go('/profile');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 24,
              ),
            ),
          ),
          
          // App logo/title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'PulseLink',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6E3BFF),
              ),
            ),
          ),
          
          // Filters button
          GestureDetector(
            onTap: () {
              // TODO: Show filters modal
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune,
                color: Colors.grey,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(DiscoveryLoaded state) {
    final users = state.userStack;
    if (users.isEmpty) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 140),
        child: Stack(
          children: [
            // Background cards (next users)
            if (users.length > 1)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.95,
                  child: SwipeCard(
                    user: users[1],
                    showDetails: false,
                  ),
                ),
              ),
            
            if (users.length > 2)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.9,
                  child: SwipeCard(
                    user: users[2],
                    showDetails: false,
                  ),
                ),
              ),
            
            // Main card (current user)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: AnimatedBuilder(
                  animation: _cardSlideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _isDragging 
                          ? Offset(
                              _dragOffset.dx * MediaQuery.of(context).size.width,
                              _dragOffset.dy * MediaQuery.of(context).size.height,
                            )
                          : _cardSlideAnimation.value * MediaQuery.of(context).size.width,
                      child: Transform.rotate(
                        angle: _isDragging 
                            ? _dragOffset.dx * 0.3
                            : _cardRotationAnimation.value,
                        child: SwipeCard(
                          user: users[0],
                          swipeProgress: _dragOffset.dx,
                          swipeDirection: _currentSwipeDirection,
                          isAnimating: _isDragging,
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

  Widget _buildMatchDialog(DiscoveryMatchFound state) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  color: Color(0xFF66D7A2),
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'It\'s a Match!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6E3BFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You and ${state.matchedUser.name} liked each other',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<DiscoveryBloc>().dismissMatch();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Keep Swiping'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to messages and dismiss match
                          context.go('/messages');
                          context.read<DiscoveryBloc>().dismissMatch();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E3BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Say Hello'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No more profiles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new people or adjust your filters',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<DiscoveryBloc>().add(const RefreshDiscovery());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E3BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: BlocProvider(
          create: (context) => DiscoveryBloc(
            discoveryService: DiscoveryService(),
          ),
          child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Main content
                  if (state is DiscoveryLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state is DiscoveryLoaded && state.hasUsers)
                    _buildCardStack(state)
                  else if (state is DiscoveryEmpty)
                    _buildEmptyState()
                  else if (state is DiscoveryError)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context.read<DiscoveryBloc>().add(
                                const LoadDiscoverableUsers(resetStack: true),
                              );
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  
                  // Top bar
                  _buildTopBar(),
                  
                  // Action buttons
                  if (state is DiscoveryLoaded && state.hasUsers)
                    _buildActionButtons(),
                  
                  // Match dialog
                  if (state is DiscoveryMatchFound)
                    _buildMatchDialog(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
