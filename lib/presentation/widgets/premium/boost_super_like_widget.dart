import 'package:flutter/material.dart';
import '../common/pulse_button.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Boost and Super Like features for premium users
class BoostSuperLikeWidget extends StatefulWidget {
  const BoostSuperLikeWidget({
    super.key,
    this.onBoostActivated,
    this.onSuperLikeSent,
  });

  final VoidCallback? onBoostActivated;
  final VoidCallback? onSuperLikeSent;

  @override
  State<BoostSuperLikeWidget> createState() => _BoostSuperLikeWidgetState();
}

class _BoostSuperLikeWidgetState extends State<BoostSuperLikeWidget>
    with TickerProviderStateMixin {
  late AnimationController _boostController;
  late AnimationController _superLikeController;
  late Animation<double> _boostPulseAnimation;
  late Animation<double> _superLikeShineAnimation;

  bool _isBoostActive = false;
  int _superLikesRemaining = 5;

  @override
  void initState() {
    super.initState();

    _boostController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _superLikeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _boostPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _boostController, curve: Curves.easeInOut),
    );

    _superLikeShineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _superLikeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _boostController.dispose();
    _superLikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.bolt, color: context.onSurfaceColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Power Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.onSurfaceColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.onSurfaceColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Boost and Super Like options
          Row(
            children: [
              Expanded(child: _buildBoostCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildSuperLikeCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoostCard() {
    return AnimatedBuilder(
      animation: _boostPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isBoostActive ? _boostPulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _activateBoost,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: _isBoostActive
                    ? Border.all(color: context.onSurfaceColor, width: 2)
                    : null,
              ),
              child: Column(
                children: [
                  // Boost icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    'Boost',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    _isBoostActive ? 'Active!' : '10x visibility',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Status/Button
                  if (_isBoostActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '29m left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Activate',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuperLikeCard() {
    return AnimatedBuilder(
      animation: _superLikeShineAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _sendSuperLike,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Shine effect
                if (_superLikeShineAnimation.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.blue.withValues(
                              alpha: 0.3 * _superLikeShineAnimation.value,
                            ),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),

                Column(
                  children: [
                    // Super Like icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      'Super Like',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      'Stand out',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Remaining count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_superLikesRemaining left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _activateBoost() {
    if (_isBoostActive) return;

    setState(() {
      _isBoostActive = true;
    });

    _boostController.repeat(reverse: true);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Boost Activated!'),
        content: Text(
          'Your profile will be shown to 10x more people for the next 30 minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );

    widget.onBoostActivated?.call();

    // Auto-deactivate after 30 minutes (for demo, using 30 seconds)
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isBoostActive = false;
        });
        _boostController.stop();
        _boostController.reset();
      }
    });
  }

  void _sendSuperLike() {
    if (_superLikesRemaining <= 0) {
      _showNeedMoreSuperLikes();
      return;
    }

    setState(() {
      _superLikesRemaining--;
    });

    _superLikeController.forward().then((_) {
      _superLikeController.reset();
    });

    // Show sent confirmation
    if (mounted) {
      PulseToast.info(context, message: 'Super Like sent!');
    }

    widget.onSuperLikeSent?.call();
  }

  void _showNeedMoreSuperLikes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.onSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, color: Colors.blue, size: 40),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'No Super Likes Left',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                'Get more Super Likes with Pulse Premium or wait until tomorrow for your free daily Super Like.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceVariantColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: PulseButton(
                      text: 'Get Premium',
                      onPressed: () {
                        Navigator.pop(context);
                        _showPremiumUpgrade();
                      },
                      variant: PulseButtonVariant.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PulseButton(
                      text: 'Wait',
                      onPressed: () => Navigator.pop(context),
                      variant: PulseButtonVariant.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumUpgrade() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.onSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.outlineColor.shade200),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Premium benefits
                    _buildPremiumBenefit(
                      icon: Icons.star,
                      title: 'Unlimited Super Likes',
                      description: 'Stand out with unlimited Super Likes',
                    ),

                    _buildPremiumBenefit(
                      icon: Icons.rocket_launch,
                      title: 'Monthly Boosts',
                      description: 'Get seen by 10x more people',
                    ),

                    _buildPremiumBenefit(
                      icon: Icons.favorite,
                      title: 'See Who Likes You',
                      description: 'Know who\'s interested before you swipe',
                    ),

                    const Spacer(),

                    // CTA
                    PulseButton(
                      text: 'Start 7-Day Free Trial',
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to premium subscription screen
                      },
                      fullWidth: true,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Cancel anytime. No commitment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceVariantColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurfaceVariantColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
