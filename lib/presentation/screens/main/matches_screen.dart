import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/pulse_colors.dart';
import '../../blocs/matching/matching_bloc.dart';
import '../../../domain/entities/user_profile.dart';

/// Enhanced matches screen with swipeable cards and modern UI
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late AnimationController _matchAnimationController;
  late PageController _pageController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pageController = PageController();

    // Load matched profiles (for now using LoadPotentialMatches)
    context.read<MatchingBloc>().add(const LoadPotentialMatches());
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _matchAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MatchingBloc, MatchingState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: PulseColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header with connection insights
                _buildConnectionHeader(state),

                // Swipeable matched profiles
                Expanded(
                  child: _buildMatchesContent(state)),

                // Action buttons for connection management
                if (state.profiles.isNotEmpty) _buildConnectionActions(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectionHeader(MatchingState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseColors.primary.withValues(alpha: 0.05),
            PulseColors.secondary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: PulseColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Connections',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${state.profiles.length} mutual likes',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Connection insights
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PulseColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: PulseColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '92%',
                      style: TextStyle(
                        color: PulseColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.profiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildConnectionStrengthIndicator(state),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionStrengthIndicator(MatchingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: PulseColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Strength',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.85, // Dynamic based on compatibility
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    PulseColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Strong',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: PulseColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesContent(MatchingState state) {
    if (state.status == MatchingStatus.loading && state.profiles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
        ),
      );
    }

    if (state.profiles.isEmpty) {
      return _buildEmptyMatchesState();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Current match indicator
          _buildMatchIndicator(state),
          const SizedBox(height: 12),

          // Swipeable match cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                HapticFeedback.selectionClick();
              },
              itemCount: state.profiles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildMatchCard(state.profiles[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchIndicator(MatchingState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < state.profiles.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == i
                  ? PulseColors.primary
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchCard(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Profile image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: profile.photos.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          profile.photos.first.url,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: profile.photos.isEmpty ? Colors.grey[300] : null,
              ),
              child: profile.photos.isEmpty
                  ? const Center(
                      child: Icon(Icons.person, size: 100, color: Colors.grey),
                    )
                  : null,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            // Connection status badge
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [PulseColors.primary, PulseColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Profile info
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: ${profile.age} • ${profile.distanceString}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Swipe gesture detector
            GestureDetector(
              onTap: () => _showConnectionProfile(profile),
              onPanUpdate: (details) {
                // Handle swipe gestures
                if (details.delta.dx > 10) {
                  // Swipe right - start chat
                  _handleStartChat();
                } else if (details.delta.dx < -10) {
                  // Swipe left - remove connection
                  _handleRemoveConnection();
                } else if (details.delta.dy < -10) {
                  // Swipe up - video call
                  _handleVideoCall();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PulseColors.primary.withOpacity(0.1),
                    PulseColors.secondary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: PulseColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Connections Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to find your perfect match',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to discovery tab
                DefaultTabController.of(context).animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Discovering',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Remove connection
          _buildConnectionActionButton(
            icon: Icons.person_remove,
            label: 'Remove',
            color: PulseColors.error,
            onPressed: () => _handleRemoveConnection(),
          ),
          
          // Block user
          _buildConnectionActionButton(
            icon: Icons.block,
            label: 'Block',
            color: Colors.orange,
            onPressed: () => _handleBlockUser(),
          ),
          
          // Start chat
          _buildConnectionActionButton(
            icon: Icons.chat_bubble,
            label: 'Chat',
            color: PulseColors.primary,
            onPressed: () => _handleStartChat(),
            isPrimary: true,
          ),
          
          // Video call
          _buildConnectionActionButton(
            icon: Icons.videocam,
            label: 'Call',
            color: PulseColors.success,
            onPressed: () => _handleVideoCall(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            icon: Icon(icon, color: isPrimary ? Colors.white : color, size: 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _handleRemoveConnection() {
    final currentMatch = _getCurrentMatch();
    if (currentMatch != null) {
      _showRemoveConnectionDialog(currentMatch);
    }
  }

  void _handleBlockUser() {
    final currentMatch = _getCurrentMatch();
    if (currentMatch != null) {
      _showBlockUserDialog(currentMatch);
    }
  }

  void _handleStartChat() {
    final currentMatch = _getCurrentMatch();
    if (currentMatch != null) {
      HapticFeedback.mediumImpact();
      // Navigate to chat screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening chat...'),
          backgroundColor: PulseColors.primary,
        ),
      );
    }
  }

  void _handleVideoCall() {
    final currentMatch = _getCurrentMatch();
    if (currentMatch != null) {
      HapticFeedback.mediumImpact();
      // Initiate video call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting video call...'),
          backgroundColor: PulseColors.success,
        ),
      );
    }
  }

  UserProfile? _getCurrentMatch() {
    final state = context.read<MatchingBloc>().state;
    if (state.profiles.isNotEmpty && _currentIndex < state.profiles.length) {
      return state.profiles[_currentIndex];
    }
    return null;
  }

  void _showRemoveConnectionDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Connection'),
        content: Text(
          'Are you sure you want to remove ${profile.name} from your connections?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed ${profile.name} from connections'),
                  backgroundColor: PulseColors.error,
                ),
              );
            },
            child: Text('Remove', style: TextStyle(color: PulseColors.error)),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${profile.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Blocked ${profile.name}'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showConnectionProfile(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Connection badge
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PulseColors.primary, PulseColors.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Mutual Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Profile content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profile.photos.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  profile.photos.first.url,
                                )
                              : null,
                          child: profile.photos.isEmpty
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Age: ${profile.age} • ${profile.distanceString}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bio section
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _handleStartChat();
                            },
                            icon: const Icon(Icons.chat_bubble),
                            label: const Text('Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PulseColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _handleVideoCall();
                            },
                            icon: const Icon(Icons.videocam),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PulseColors.success,
                              side: BorderSide(color: PulseColors.success),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
