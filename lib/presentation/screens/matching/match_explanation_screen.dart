import 'package:flutter/material.dart';
import '../../../domain/entities/user_profile.dart';
import '../../theme/pulse_colors.dart' hide PulseTextStyles;
import '../../theme/pulse_theme.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Match Explanation Screen
///
/// Shows detailed breakdown of why two users were matched:
/// - Compatibility score with visual breakdown
/// - Shared interests with icons
/// - Matching preferences (location, age, etc.)
/// - Activity patterns and lifestyle compatibility
/// - Personality compatibility factors
class MatchExplanationScreen extends StatelessWidget {
  final UserProfile profile;
  final double compatibilityScore;
  final Map<String, dynamic>? matchReasons;

  const MatchExplanationScreen({
    super.key,
    required this.profile,
    required this.compatibilityScore,
    this.matchReasons,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = matchReasons ?? {};

    return Scaffold(
      appBar: AppBar(title: Text('Match Breakdown'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with profile and overall score
            _buildHeader(context),

            const SizedBox(height: 24),

            // Compatibility breakdown
            _buildCompatibilityBreakdown(context, reasons),

            const SizedBox(height: 24),

            // Shared interests
            if (reasons['sharedInterests'] != null)
              _buildSharedInterests(context, reasons['sharedInterests']),

            const SizedBox(height: 24),

            // Location compatibility
            if (reasons['locationScore'] != null)
              _buildLocationCompatibility(context, reasons),

            const SizedBox(height: 24),

            // Lifestyle compatibility
            if (reasons['lifestyleScore'] != null)
              _buildLifestyleCompatibility(context, reasons),

            const SizedBox(height: 24),

            // Activity patterns
            if (reasons['activityScore'] != null)
              _buildActivityPatterns(context, reasons),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseColors.primary.withValues(alpha: 0.1),
            PulseColors.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile photo
          CircleAvatar(
            radius: 50,
            backgroundImage: profile.photos.isNotEmpty
                ? NetworkImage(profile.photos.first.url)
                : null,
            child: profile.photos.isEmpty
                ? Icon(Icons.person, size: 50)
                : null,
          ),

          const SizedBox(height: 16),

          // Name and age
          Text(
            '${profile.name}, ${profile.age}',
            style: PulseTextStyles.headlineMedium,
          ),

          const SizedBox(height: 24),

          // Overall compatibility score
          _buildOverallScore(context),
        ],
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context) {
    final percentage = (compatibilityScore * 100).round();
    final color = _getScoreColor(context, compatibilityScore);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: compatibilityScore,
                strokeWidth: 12,
                backgroundColor: context.outlineColor.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              children: [
                Text(
                  '$percentage%',
                  style: PulseTextStyles.headlineLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Match',
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: context.outlineColor.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          _getScoreLabel(compatibilityScore),
          style: PulseTextStyles.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityBreakdown(
    BuildContext context,
    Map<String, dynamic> reasons,
  ) {
    final categories = [
      if (reasons['interestScore'] != null)
        _CompatibilityCategory(
          'Shared Interests',
          reasons['interestScore'] as double,
          Icons.favorite,
          Colors.red,
        ),
      if (reasons['locationScore'] != null)
        _CompatibilityCategory(
          'Location',
          reasons['locationScore'] as double,
          Icons.location_on,
          Colors.blue,
        ),
      if (reasons['lifestyleScore'] != null)
        _CompatibilityCategory(
          'Lifestyle',
          reasons['lifestyleScore'] as double,
          Icons.wb_sunny,
          Colors.orange,
        ),
      if (reasons['activityScore'] != null)
        _CompatibilityCategory(
          'Activity Level',
          reasons['activityScore'] as double,
          Icons.directions_run,
          Colors.green,
        ),
      if (reasons['personalityScore'] != null)
        _CompatibilityCategory(
          'Personality',
          reasons['personalityScore'] as double,
          Icons.psychology,
          Colors.purple,
        ),
    ];

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compatibility Breakdown', style: PulseTextStyles.headlineSmall),

          const SizedBox(height: 16),

          ...categories.map((category) => _buildCategoryBar(context, category)),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    _CompatibilityCategory category,
  ) {
    final percentage = (category.score * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 20, color: category.color),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: PulseTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: PulseTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: category.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: category.score,
              minHeight: 8,
              backgroundColor: context.outlineColor.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(category.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedInterests(
    BuildContext context,
    List<dynamic> sharedInterests,
  ) {
    if (sharedInterests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: context.errorColor.shade400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text('Shared Interests', style: PulseTextStyles.headlineSmall),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sharedInterests.map((interest) {
              return Chip(
                label: Text(interest.toString()),
                backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
                labelStyle: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCompatibility(
    BuildContext context,
    Map<String, dynamic> reasons,
  ) {
    final distance = reasons['distance'] as double?;
    final locationScore = reasons['locationScore'] as double? ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text('Location', style: PulseTextStyles.titleLarge),
                ],
              ),

              const SizedBox(height: 16),

              if (distance != null)
                _buildInfoRow(
                  context,
                  'Distance',
                  '${distance.toStringAsFixed(1)} km away',
                ),

              _buildInfoRow(
                context,
                'Compatibility',
                _getLocationCompatibilityText(locationScore),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleCompatibility(
    BuildContext context,
    Map<String, dynamic> reasons,
  ) {
    final lifestyleScore = reasons['lifestyleScore'] as double? ?? 0.0;
    final lifestyleFactors = reasons['lifestyleFactors'] as List<dynamic>?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.orange.shade400, size: 24),
                  const SizedBox(width: 8),
                  Text('Lifestyle', style: PulseTextStyles.titleLarge),
                ],
              ),

              const SizedBox(height: 16),

              _buildInfoRow(
                context,
                'Compatibility',
                _getLifestyleCompatibilityText(lifestyleScore),
              ),

              if (lifestyleFactors != null && lifestyleFactors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ...lifestyleFactors.map((factor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            factor.toString(),
                            style: PulseTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityPatterns(
    BuildContext context,
    Map<String, dynamic> reasons,
  ) {
    final activityScore = reasons['activityScore'] as double? ?? 0.0;
    final activityFactors = reasons['activityFactors'] as List<dynamic>?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_run,
                    color: Colors.green.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text('Activity Patterns', style: PulseTextStyles.titleLarge),
                ],
              ),

              const SizedBox(height: 16),

              _buildInfoRow(
                context,
                'Match Level',
                _getActivityCompatibilityText(activityScore),
              ),

              if (activityFactors != null && activityFactors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ...activityFactors.map((factor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            factor.toString(),
                            style: PulseTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: PulseTextStyles.bodyMedium.copyWith(
              color: context.outlineColor.shade600,
            ),
          ),
          Text(
            value,
            style: PulseTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(BuildContext context, double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return context.outlineColor;
  }

  String _getScoreLabel(double score) {
    if (score >= 0.8) return 'Excellent Match';
    if (score >= 0.6) return 'Good Match';
    if (score >= 0.4) return 'Moderate Match';
    return 'Low Match';
  }

  String _getLocationCompatibilityText(double score) {
    if (score >= 0.8) return 'Very close by';
    if (score >= 0.6) return 'Nearby';
    if (score >= 0.4) return 'Within reasonable distance';
    return 'A bit far';
  }

  String _getLifestyleCompatibilityText(double score) {
    if (score >= 0.8) return 'Very compatible';
    if (score >= 0.6) return 'Compatible';
    if (score >= 0.4) return 'Somewhat compatible';
    return 'Different lifestyles';
  }

  String _getActivityCompatibilityText(double score) {
    if (score >= 0.8) return 'Very similar';
    if (score >= 0.6) return 'Similar';
    if (score >= 0.4) return 'Somewhat similar';
    return 'Different patterns';
  }
}

/// Internal class for compatibility category data
class _CompatibilityCategory {
  final String name;
  final double score;
  final IconData icon;
  final Color color;

  _CompatibilityCategory(this.name, this.score, this.icon, this.color);
}
