import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/speed_dating_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import 'active_round_screen.dart';
import 'speed_dating_matches_screen.dart';

/// Round Transition Screen for Speed Dating
/// Shows partner recap, rating system, and transitions to next round or matches
class RoundTransitionScreen extends StatefulWidget {
  final String eventId;
  final String sessionId;
  final Map<String, dynamic>? partnerProfile;
  final Map<String, dynamic>? nextSession;

  const RoundTransitionScreen({
    Key? key,
    required this.eventId,
    required this.sessionId,
    this.partnerProfile,
    this.nextSession,
  }) : super(key: key);

  @override
  State<RoundTransitionScreen> createState() => _RoundTransitionScreenState();
}

class _RoundTransitionScreenState extends State<RoundTransitionScreen>
    with SingleTickerProviderStateMixin {
  final SpeedDatingService _speedDatingService = SpeedDatingService();
  final TextEditingController _notesController = TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _showMutualMatch = false;
  String? _error;

  late AnimationController _starAnimationController;
  late Animation<double> _starScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _starAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _starScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _starAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating before continuing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Submit rating
      final result = await _speedDatingService.rateSession(
        widget.sessionId,
        userId,
        _selectedRating,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      // Check for mutual match (both rated 4+)
      final isMutualMatch = result?['mutualInterest'] == true;

      if (isMutualMatch) {
        // Show mutual match animation
        setState(() {
          _showMutualMatch = true;
        });

        // Wait for user to see the match notification
        await Future.delayed(const Duration(seconds: 3));
      }

      if (!mounted) return;

      // Navigate to next round or matches screen
      _handleNavigation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to submit rating: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleNavigation() {
    if (widget.nextSession != null) {
      // Navigate to next round
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveRoundScreen(
            eventId: widget.eventId,
            sessionId: widget.nextSession!['id'] as String,
          ),
        ),
      );
    } else {
      // Last round - navigate to matches screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SpeedDatingMatchesScreen(
            eventId: widget.eventId,
          ),
        ),
      );
    }
  }

  void _selectRating(int rating) {
    setState(() {
      _selectedRating = rating;
    });

    // Animate star selection
    _starAnimationController.forward().then((_) {
      _starAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _showMutualMatch ? _buildMutualMatchOverlay() : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 32),
          if (widget.partnerProfile != null) ...[
            _buildPartnerRecap(),
            const SizedBox(height: 32),
          ],
          _buildRatingSection(),
          const SizedBox(height: 24),
          _buildNotesSection(),
          if (widget.nextSession != null) ...[
            const SizedBox(height: 32),
            _buildNextPartnerPreview(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          _buildSubmitButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          widget.nextSession != null ? Icons.rate_review : Icons.emoji_events,
          color: AppColors.primary,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          widget.nextSession != null ? 'Rate Your Match' : 'Final Rating',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.nextSession != null
              ? 'How was your conversation?'
              : 'How was your last conversation?',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerRecap() {
    final name = widget.partnerProfile!['name'] as String? ?? 'Partner';
    final age = widget.partnerProfile!['age'] as int?;
    final photoUrl = widget.partnerProfile!['photoUrl'] as String?;
    final location = widget.partnerProfile!['location'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Partner info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  age != null ? '$name, $age' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        const Text(
          'Your Rating',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected = starNumber <= _selectedRating;

            return GestureDetector(
              onTap: () => _selectRating(starNumber),
              child: AnimatedBuilder(
                animation: _starScaleAnimation,
                builder: (context, child) {
                  final scale = starNumber == _selectedRating
                      ? _starScaleAnimation.value
                      : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        size: 48,
                        color: isSelected
                            ? _getRatingColor(starNumber)
                            : Colors.white38,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          _getRatingText(),
          style: TextStyle(
            color: _selectedRating > 0
                ? _getRatingColor(_selectedRating)
                : Colors.white60,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.white38;
    }
  }

  String _getRatingText() {
    switch (_selectedRating) {
      case 5:
        return 'Amazing! 🔥';
      case 4:
        return 'Great connection! 😊';
      case 3:
        return 'Good conversation 👍';
      case 2:
        return 'Okay, but no spark 😐';
      case 1:
        return 'Not a match 😕';
      default:
        return 'Tap a star to rate';
    }
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Add any thoughts about this match...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterStyle: TextStyle(color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextPartnerPreview() {
    final userId = _getCurrentUserId();
    if (userId == null || widget.nextSession == null) {
      return const SizedBox.shrink();
    }

    final participant1 =
        widget.nextSession!['participant1'] as Map<String, dynamic>?;
    final participant2 =
        widget.nextSession!['participant2'] as Map<String, dynamic>?;

    Map<String, dynamic>? nextPartner;
    if (participant1?['userId'] == userId && participant2?['user'] != null) {
      final userMap = participant2!['user'];
      if (userMap is Map<String, dynamic>) {
        nextPartner = userMap;
      }
    } else if (participant2?['userId'] == userId &&
        participant1?['user'] != null) {
      final userMap = participant1!['user'];
      if (userMap is Map<String, dynamic>) {
        nextPartner = userMap;
      }
    }

    if (nextPartner == null) return const SizedBox.shrink();

    final name = nextPartner['name'] as String? ?? 'Next Partner';
    final photoUrl = nextPartner['photoUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Up Next',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Get ready for your next conversation!',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitRating,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.nextSession != null
                      ? 'Continue to Next Round'
                      : 'View Matches',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  widget.nextSession != null
                      ? Icons.arrow_forward
                      : Icons.emoji_events,
                  color: Colors.white,
                ),
              ],
            ),
    );
  }

  Widget _buildMutualMatchOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            AppColors.primary.withValues(alpha: 0.3),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated celebration icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              "It's a Match!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You both rated each other highly!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "You'll see them in your matches",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _starAnimationController.dispose();
    super.dispose();
  }
}
