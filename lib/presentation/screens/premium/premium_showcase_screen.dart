import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/premium.dart';
import '../../../data/services/analytics_service.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../../blocs/premium/premium_state.dart';
import '../../navigation/app_router.dart'; // 🔴 CRITICAL: Add for payment navigation
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/premium/premium_feature_card.dart';
import '../../widgets/premium/pricing_card.dart';

/// Premium Features Showcase Screen
///
/// A conversion-optimized screen that showcases premium features and drives
/// subscription upgrades through compelling visuals and clear value proposition.
///
/// Features:
/// - Hero section with gradient background
/// - Comprehensive feature comparison (Free vs Premium)
/// - Detailed premium features with icons and descriptions
/// - Pricing cards with best value highlighting
/// - Trust indicators (money-back guarantee, secure payments)
/// - Smooth animations and sticky CTA
/// - Analytics tracking for optimization
class PremiumShowcaseScreen extends StatefulWidget {
  /// Optional parameter to highlight a specific feature
  final String? highlightFeature;

  /// Optional parameter to pre-select a plan
  final String? selectedPlanId;

  /// Source of navigation (for analytics)
  final String? source;

  const PremiumShowcaseScreen({
    super.key,
    this.highlightFeature,
    this.selectedPlanId,
    this.source,
  });

  @override
  State<PremiumShowcaseScreen> createState() => _PremiumShowcaseScreenState();
}

class _PremiumShowcaseScreenState extends State<PremiumShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedPlanId;
  final ScrollController _scrollController = ScrollController();
  bool _showStickyButton = false;

  // Scroll tracking
  final Set<int> _scrollMilestonesReached = {};
  double _maxScrollPercentageReached = 0;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.selectedPlanId;

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Load premium data
    context.read<PremiumBloc>().add(LoadPremiumData());

    // Listen to scroll for sticky button
    _scrollController.addListener(_onScroll);

    // Track analytics
    _trackScreenView();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Sticky button logic
    if (_scrollController.offset > 200 && !_showStickyButton) {
      setState(() => _showStickyButton = true);
    } else if (_scrollController.offset <= 200 && _showStickyButton) {
      setState(() => _showStickyButton = false);
    }

    // Track scroll depth milestones
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      final scrollPercentage = (_scrollController.offset / maxScroll * 100)
          .clamp(0.0, 100.0);

      // Update max reached
      if (scrollPercentage > _maxScrollPercentageReached) {
        _maxScrollPercentageReached = scrollPercentage.toDouble();
      }

      // Track milestones: 25%, 50%, 75%, 100%
      final milestones = [25, 50, 75, 100];
      for (final milestone in milestones) {
        if (scrollPercentage >= milestone &&
            !_scrollMilestonesReached.contains(milestone)) {
          _scrollMilestonesReached.add(milestone);
          _trackScrollDepth(milestone.toDouble());
        }
      }
    }
  }

  void _trackScreenView() {
    AnalyticsService.instance.trackScreenView(
      screenName: 'premium_showcase',
      properties: {
        'source': widget.source ?? 'unknown',
        'highlighted_feature': widget.highlightFeature,
        'selected_plan_id': _selectedPlanId,
      },
    );
  }

  void _trackCTAClick(String planId, String ctaType) {
    AnalyticsService.instance.trackButtonClick(
      buttonName: 'premium_cta',
      screenName: 'premium_showcase',
      properties: {
        'plan_id': planId,
        'cta_type': ctaType,
        'source': widget.source ?? 'unknown',
        'selected_plan_id': _selectedPlanId,
      },
    );
  }

  void _trackPlanSelection(String planId, String? previousPlanId) {
    AnalyticsService.instance.trackEvent(
      eventType: AnalyticsEventType.featureUsed,
      properties: {
        'feature_name': 'premium_plan_selection',
        'plan_id': planId,
        'previous_plan_id': previousPlanId,
        'screen_name': 'premium_showcase',
        'source': widget.source ?? 'unknown',
      },
    );
  }

  void _trackFeatureCardTap(String featureName) {
    AnalyticsService.instance.trackEvent(
      eventType: AnalyticsEventType.featureUsed,
      properties: {
        'feature_name': 'premium_feature_card_tap',
        'card_feature': featureName,
        'screen_name': 'premium_showcase',
        'source': widget.source ?? 'unknown',
      },
    );
  }

  void _trackScrollDepth(double scrollPercentage) {
    // Track scroll milestones (25%, 50%, 75%, 100%)
    AnalyticsService.instance.trackEvent(
      eventType: AnalyticsEventType.featureUsed,
      properties: {
        'feature_name': 'premium_showcase_scroll',
        'scroll_percentage': scrollPercentage.round(),
        'screen_name': 'premium_showcase',
        'source': widget.source ?? 'unknown',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PremiumBloc, PremiumState>(
        builder: (context, state) {
          if (state is PremiumLoading) {
            return const PulseLoadingWidget();
          }

          if (state is PremiumError) {
            return PulseErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<PremiumBloc>().add(LoadPremiumData());
              },
            );
          }

          if (state is PremiumLoaded) {
            // Auto-select most popular plan if none selected
            _selectedPlanId ??= _getMostPopularPlanId(state.plans);

            return Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildHeroSection(context),
                    _buildFeaturesSection(context),
                    _buildPricingSection(context, state.plans),
                    _buildComparisonSection(context),
                    _buildTrustIndicators(context),
                    _buildTestimonials(context),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 100), // Space for sticky button
                    ),
                  ],
                ),

                // Sticky CTA button
                if (_showStickyButton) _buildStickyButton(context, state.plans),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PulseColors.primary,
                  PulseColors.primaryLight,
                  PulseColors.secondary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text(
                            'Maybe Later',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Headline
                        const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // Subheadline
                        Text(
                          'Get unlimited access to all premium features\nand find your perfect match faster',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = _getPremiumFeatures();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Features',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Everything you need to find meaningful connections',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Feature cards grid
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumFeatureCard(
                  icon: feature['icon'] as IconData,
                  title: feature['title'] as String,
                  description: feature['description'] as String,
                  isPremium: feature['isPremium'] as bool,
                  isHighlighted: widget.highlightFeature == feature['key'],
                  onTap: () {
                    // Track feature card tap
                    _trackFeatureCardTap(feature['key'] as String);

                    // Show feature details modal
                    _showFeatureDetails(
                      context,
                      feature['title'] as String,
                      feature['description'] as String,
                      feature['details'] as String,
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

  Widget _buildPricingSection(BuildContext context, List<PremiumPlan> plans) {
    if (plans.isEmpty)
   {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    // Sort plans: monthly, 3-month, 6-month
    final sortedPlans = _sortPlansByDuration(plans);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Plan',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All plans include full access to premium features',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Pricing cards
            ...sortedPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PricingCard(
                  plan: plan,
                  isSelected: _selectedPlanId == plan.id,
                  isMostPopular: _isMostPopularPlan(plan, sortedPlans),
                  isBestValue: _isBestValuePlan(plan, sortedPlans),
                  onSelect: () {
                    final previousPlanId = _selectedPlanId;
                    setState(() => _selectedPlanId = plan.id);
                    _trackPlanSelection(plan.id, previousPlanId);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free vs Premium',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildComparisonRow('Daily likes', 'Limited', 'Unlimited'),
                _buildComparisonRow('Super likes', '1/day', '5/day'),
                _buildComparisonRow('See who liked you', false, true),
                _buildComparisonRow('Rewind (undo swipes)', false, true),
                _buildComparisonRow('Profile boost', false, true),
                _buildComparisonRow('Advanced filters', false, true),
                _buildComparisonRow('Read receipts', false, true),
                _buildComparisonRow('Profile viewers', false, true),
                _buildComparisonRow('Ad-free experience', false, true),
                _buildComparisonRow(
                  'Priority support',
                  false,
                  true,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    dynamic freeValue,
    dynamic premiumValue, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                feature,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: _buildComparisonValue(freeValue, false)),
            Expanded(child: _buildComparisonValue(premiumValue, true)),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: PulseColors.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildComparisonValue(dynamic value, bool isPremium) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value
            ? (isPremium ? PulseColors.success : PulseColors.onSurfaceVariant)
            : PulseColors.onSurfaceVariant.withValues(alpha: 0.3),
        size: 20,
      );
    }

    return Text(
      value.toString(),
      style: TextStyle(
        fontSize: 13,
        color: isPremium ? PulseColors.primary : PulseColors.onSurfaceVariant,
        fontWeight: isPremium ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTrustIndicators(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: PulseColors.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: PulseColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Money-Back Guarantee',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Not satisfied? Get a full refund within 14 days',
                            style: TextStyle(
                              fontSize: 13,
                              color: PulseColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: PulseColors.outline.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lock, color: PulseColors.success, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure Payments',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bank-level encryption protects your information',
                            style: TextStyle(
                              fontSize: 13,
                              color: PulseColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: PulseColors.outline.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      color: PulseColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cancel Anytime',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No hidden fees or long-term commitments',
                            style: TextStyle(
                              fontSize: 13,
                              color: PulseColors.onSurfaceVariant,
                            ),
                          ),
                        ],
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

  Widget _buildTestimonials(BuildContext context) {
    final testimonials = [
      {
        'name': 'Sarah, 28',
        'text':
            'Premium helped me find my match in just 2 weeks! The advanced filters made all the difference.',
        'rating': 5,
      },
      {
        'name': 'Mike, 32',
        'text':
            'Being able to see who liked me saved so much time. Best investment I made in my dating life!',
        'rating': 5,
      },
      {
        'name': 'Emma, 26',
        'text':
            'The boost feature really works! Got 10x more matches in one evening.',
        'rating': 5,
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What Our Members Say',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ...testimonials.map(
              (testimonial) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        testimonial['rating'] as int,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      testimonial['text'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      testimonial['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PulseColors.primary,
                      ),
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

  Widget _buildStickyButton(BuildContext context, List<PremiumPlan> plans) {
    final selectedPlan = plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => plans.first,
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCTAButton(context, selectedPlan, 'sticky'),
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context, PremiumPlan plan, String type) {
    // TODO: Add metadata support to PremiumPlan model for free trial detection
    // final hasFreeTrial = plan.metadata?['hasTrial'] == true;

    return ElevatedButton(
      onPressed: () => _handleSubscribe(plan, type),
      style: ElevatedButton.styleFrom(
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Upgrade Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }

  void _handleSubscribe(PremiumPlan plan, String ctaType) {
    _trackCTAClick(plan.id, ctaType);

    // Show purchase confirmation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPurchaseConfirmation(plan),
    );
  }

  Widget _buildPurchaseConfirmation(PremiumPlan plan) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PulseColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Icon(
                Icons.workspace_premium,
                size: 64,
                color: PulseColors.primary,
              ),
              const SizedBox(height: 16),

              Text(
                'Confirm Subscription',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 18,
                  color: PulseColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                plan.formattedPrice,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What you\'ll get:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...plan.features
                        .take(5)
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: PulseColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: PulseColors.outline),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _confirmPurchase(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Subscribe'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Cancel anytime. Auto-renews unless cancelled.',
                style: TextStyle(
                  fontSize: 12,
                  color: PulseColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPurchase(PremiumPlan plan) {
    Navigator.of(context).pop(); // Close bottom sheet

    // 🔴 CRITICAL: Navigate to payment methods screen to complete purchase
    // Pass plan details for payment processing
    context.push(
      AppRoutes.paymentMethods,
      extra: {
        'planId': plan.id,
        'planName': plan.name,
        'amount': plan.priceInCents / 100, // Convert cents to currency units
        'currency': plan.currency,
        'interval': plan.interval,
        'purpose': 'premium_subscription',
      },
    );

    // Track analytics for payment flow entry
    AnalyticsService.instance.trackEvent(
      eventType: AnalyticsEventType.featureUsed,
      properties: {
        'feature_name': 'premium_payment_flow_started',
        'plan_id': plan.id,
        'plan_name': plan.name,
        'price_cents': plan.priceInCents.toString(),
        'currency': plan.currency,
      },
    );
  }

  void _showFeatureDetails(
    BuildContext context,
    String title,
    String description,
    String details,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PulseColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 14,
                        color: PulseColors.onSurfaceVariant,
                        height: 1.5,
                      ),
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

  List<Map<String, dynamic>> _getPremiumFeatures() {
    return [
      {
        'key': 'who_liked_you',
        'icon': Icons.favorite,
        'title': 'See Who Liked You',
        'description': 'View everyone who already liked your profile',
        'details':
            'No more guessing! See all your likes at once and match instantly with people who are already interested in you.',
        'isPremium': true,
      },
      {
        'key': 'unlimited_likes',
        'icon': Icons.favorite_border,
        'title': 'Unlimited Likes',
        'description': 'Like as many profiles as you want, no limits',
        'details':
            'Swipe without restrictions. The more you like, the more matches you can make!',
        'isPremium': true,
      },
      {
        'key': 'rewind',
        'icon': Icons.replay,
        'title': 'Rewind',
        'description': 'Undo your last swipe and get another chance',
        'details':
            'Changed your mind? Take back your last swipe and give them another look. Perfect for those accidental left swipes!',
        'isPremium': true,
      },
      {
        'key': 'super_likes',
        'icon': Icons.star,
        'title': '5 Super Likes per Day',
        'description': 'Stand out and make a great first impression',
        'details':
            'Get 5 Super Likes daily to show someone you\'re really interested. Super Likes get 3x more matches!',
        'isPremium': true,
      },
      {
        'key': 'boost',
        'icon': Icons.trending_up,
        'title': 'Monthly Boost',
        'description': 'Be the top profile in your area for 30 minutes',
        'details':
            'Get 10x more profile views with monthly boost. Perfect for maximizing your visibility and matches!',
        'isPremium': true,
      },
      {
        'key': 'advanced_filters',
        'icon': Icons.tune,
        'title': 'Advanced Filters',
        'description': 'Find exactly who you\'re looking for',
        'details':
            'Filter by education, lifestyle, interests, and more. Find matches that truly align with what you\'re looking for.',
        'isPremium': true,
      },
      {
        'key': 'read_receipts',
        'icon': Icons.done_all,
        'title': 'Read Receipts',
        'description': 'See when your messages are read',
        'details':
            'Know exactly when your matches read your messages. No more wondering if they saw it!',
        'isPremium': true,
      },
      {
        'key': 'profile_viewers',
        'icon': Icons.visibility,
        'title': 'See Who Viewed Your Profile',
        'description': 'Know who\'s checking you out',
        'details':
            'See everyone who viewed your profile in the last 30 days. Perfect for finding people interested in you!',
        'isPremium': true,
      },
      {
        'key': 'ad_free',
        'icon': Icons.block,
        'title': 'Ad-Free Experience',
        'description': 'Enjoy PulseLink without interruptions',
        'details':
            'Focus on finding your match without any distractions. Pure, uninterrupted dating experience.',
        'isPremium': true,
      },
      {
        'key': 'priority_support',
        'icon': Icons.support_agent,
        'title': 'Priority Customer Support',
        'description': 'Get help when you need it, faster',
        'details':
            'Jump to the front of the line with priority support. We\'re here to help you succeed!',
        'isPremium': true,
      },
    ];
  }

  List<PremiumPlan> _sortPlansByDuration(List<PremiumPlan> plans) {
    final sorted = List<PremiumPlan>.from(plans);
    sorted.sort((a, b) {
      final aMonths = _getMonthsFromInterval(a.interval);
      final bMonths = _getMonthsFromInterval(b.interval);
      return aMonths.compareTo(bMonths);
    });
    return sorted;
  }

  int _getMonthsFromInterval(String interval) {
    final lower = interval.toLowerCase();
    // Parse interval string like "month", "3-month", "6-month", "year"
    if (lower.contains('year')) {
      return 12;
    } else if (lower.contains('6')) {
      return 6;
    } else if (lower.contains('3') || lower.contains('quarter')) {
      return 3;
    }
    return 1; // Default to monthly
  }

  String? _getMostPopularPlanId(List<PremiumPlan> plans) {
    final popular = plans.where((p) => p.isPopular).firstOrNull;
    if (popular != null) return popular.id;

    // Default to 3-month plan if available
    final threeMonth = plans
        .where((p) => _getMonthsFromInterval(p.interval) == 3)
        .firstOrNull;

    return threeMonth?.id ?? plans.firstOrNull?.id;
  }

  bool _isMostPopularPlan(PremiumPlan plan, List<PremiumPlan> plans) {
    return plan.isPopular || _getMonthsFromInterval(plan.interval) == 3;
  }

  bool _isBestValuePlan(PremiumPlan plan, List<PremiumPlan> plans) {
    return _getMonthsFromInterval(plan.interval) == 6;
  }
}
