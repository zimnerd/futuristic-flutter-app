import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/ai_matching_service.dart';
import '../../theme/pulse_colors.dart';
import 'compatibility_score_widget.dart';
import '../common/robust_network_image.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Smart matching widget with AI-powered recommendations and insights
class SmartMatchWidget extends StatefulWidget {
  final UserModel currentUser;
  final Function(MatchModel match)? onMatchTap;
  final Function(MatchModel match, String action)? onMatchAction;

  const SmartMatchWidget({
    super.key,
    required this.currentUser,
    this.onMatchTap,
    this.onMatchAction,
  });

  @override
  State<SmartMatchWidget> createState() => _SmartMatchWidgetState();
}

class _SmartMatchWidgetState extends State<SmartMatchWidget>
    with TickerProviderStateMixin {
  final AiMatchingService _aiService = AiMatchingService(ApiClient.instance);

  List<MatchModel> _recommendations = [];

  bool _isLoading = false;
  String _selectedFilter = 'all';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadRecommendations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final recommendations = await _aiService.getRecommendations(
        userId: widget.currentUser.id,
        limit: 20,
        minCompatibility: _getMinCompatibilityForFilter(),
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load recommendations');
    }
  }

  double? _getMinCompatibilityForFilter() {
    switch (_selectedFilter) {
      case 'high':
        return 0.8;
      case 'medium':
        return 0.6;
      case 'all':
      default:
        return null;
    }
  }

  void _showErrorMessage(String message) {
    PulseToast.error(context, message: message);
  }

  Future<void> _handleMatchAction(MatchModel match, String action) async {
    // Submit feedback to AI system
    await _aiService.submitFeedback(
      userId: widget.currentUser.id,
      targetUserId: match.otherUserId ?? match.user2Id,
      action: action,
      context: {
        'source': 'smart_match_widget',
        'compatibility_score': match.compatibilityScore,
        'filter': _selectedFilter,
      },
    );

    widget.onMatchAction?.call(match, action);

    // Remove from current recommendations
    setState(() {
      _recommendations.removeWhere((m) => m.id == match.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilterTabs(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _recommendations.isEmpty
                ? _buildEmptyState()
                : _buildMatchesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PulseColors.primary, PulseColors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: context.onSurfaceColor,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Matches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                Text(
                  'AI-powered recommendations just for you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadRecommendations,
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterTab('All', 'all'),
          const SizedBox(width: 12),
          _buildFilterTab('High Match', 'high'),
          const SizedBox(width: 12),
          _buildFilterTab('Good Match', 'medium'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadRecommendations();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PulseColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Finding your perfect matches...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final match = _recommendations[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Match Header with Photo and Basic Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RobustNetworkImage(
                    imageUrl: match.userProfile?.photos.isNotEmpty == true
                        ? match.userProfile!.photos.first.url
                        : 'https://via.placeholder.com/80',
                    blurhash: match.userProfile?.photos.isNotEmpty == true
                        ? match.userProfile!.photos.first.blurhash
                        : null,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(width: 16),

                // Match Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            match.userProfile?.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (match.userProfile?.age != null &&
                              match.userProfile!.age > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${match.userProfile!.age}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Compatibility Score
                      CompatibilityBar(score: match.compatibilityScore),

                      const SizedBox(height: 8),

                      // Common Interests
                      if (match.userProfile?.interests.isNotEmpty == true)
                        Wrap(
                          spacing: 6,
                          children: match.userProfile!.interests.take(3).map((
                            interest,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: PulseColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                interest.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PulseColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.close,
                    label: 'Pass',
                    color: context.outlineColor,
                    onTap: () => _handleMatchAction(match, 'pass'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.favorite,
                    label: 'Like',
                    color: PulseColors.primary,
                    onTap: () => _handleMatchAction(match, 'like'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.star,
                    label: 'Super Like',
                    color: Colors.amber,
                    onTap: () => _handleMatchAction(match, 'super_like'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
