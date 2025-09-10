import 'package:flutter/material.dart';
import '../widgets/messaging/chat_interface.dart';
import '../widgets/messaging/conversation_list.dart';
import '../widgets/premium/premium_tier_card.dart';
import '../widgets/premium/premium_features_showcase.dart';
import '../widgets/premium/boost_super_like_widget.dart';
import '../widgets/notifications/notification_preferences_widget.dart';
import '../widgets/common/status_indicator_widget.dart';
import '../widgets/social/leaderboard_widget.dart';
import '../widgets/social/achievements_widget.dart';
import '../theme/pulse_colors.dart';
import '../../domain/entities/conversation.dart';
import '../../data/models/premium.dart';

/// Demo screen showcasing all implemented mobile features
class FeatureShowcaseScreen extends StatefulWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  State<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends State<FeatureShowcaseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Pulse Features',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Messaging'),
            Tab(text: 'Premium'),
            Tab(text: 'Real-time'),
            Tab(text: 'Social'),
          ],
          labelColor: PulseColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: PulseColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagingTab(),
          _buildPremiumTab(),
          _buildRealTimeTab(),
          _buildSocialTab(),
        ],
      ),
    );
  }

  Widget _buildMessagingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Enhanced Chat & Messaging UI',
            description: 'Modern, real-time messaging experience',
            icon: Icons.chat_bubble,
          ),
          
          const SizedBox(height: 16),
          
          // Chat Interface Demo
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ChatInterface(
              conversation: Conversation(
                id: 'demo_conversation',
                otherUserId: 'user2',
                otherUserName: 'Sarah Chen',
                otherUserAvatar: 'https://images.unsplash.com/photo-1494790108755-2616b9e3b8d8',
                lastMessage: 'Hey! How are you?',
                lastMessageTime: DateTime.now(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Conversation List Demo
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const ConversationList(),
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureHighlight(
            'Key Features',
            [
              'Real-time typing indicators',
              'Message delivery status',
              'Optimistic UI updates',
              'Smart message bubbles',
              'Voice message support',
              'Rich media sharing',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Premium Features & Enhanced Discovery',
            description: 'Unlock advanced dating features',
            icon: Icons.star,
          ),
          
          const SizedBox(height: 16),
          
          // Premium Tier Card
          PremiumTierCard(
            tier: PremiumTier.premium,
          ),
          
          const SizedBox(height: 16),
          
          // Premium Features Showcase
          const PremiumFeaturesShowcase(),
          
          const SizedBox(height: 16),
          
          // Boost & Super Like Widget
          const BoostSuperLikeWidget(),
          
          const SizedBox(height: 16),
          
          // Advanced Filters Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enhanced discovery with intelligent filters for age, distance, interests, and compatibility matching.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.tune, color: PulseColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Smart Filter System',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureHighlight(
            'Premium Benefits',
            [
              'Unlimited likes & Super Likes',
              'Profile boost visibility',
              'Advanced matching filters',
              'See who likes you',
              'Premium badges & status',
              'Ad-free experience',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Real-time Polish & Notifications',
            description: 'Stay connected with live updates',
            icon: Icons.notifications_active,
          ),
          
          const SizedBox(height: 16),
          
          // Status Indicators Demo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Indicators',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatusDemo('Online', UserStatus.online),
                    _buildStatusDemo('Typing', UserStatus.typing),
                    _buildStatusDemo('Away', UserStatus.away),
                    _buildStatusDemo('Busy', UserStatus.busy),
                    _buildStatusDemo('In Call', UserStatus.in_call),
                    _buildStatusDemo('Recently Active', UserStatus.recently_active),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'User Profile with Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const UserStatusIndicator(
                  status: UserStatus.online,
                  profileImageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b9e3b8d8',
                  size: 80,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notification Preferences
          const NotificationPreferencesWidget(),
          
          const SizedBox(height: 16),
          
          _buildFeatureHighlight(
            'Real-time Features',
            [
              'Live user status indicators',
              'Typing indicators',
              'Notification preferences',
              'Quiet hours mode',
              'Push & email notifications',
              'Smart notification timing',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Social & Gamification',
            description: 'Compete, achieve, and have fun',
            icon: Icons.emoji_events,
          ),
          
          const SizedBox(height: 16),
          
          // Leaderboard Widget
          const LeaderboardWidget(
            leaderboardType: LeaderboardType.matches,
          ),
          
          const SizedBox(height: 16),
          
          // Achievements Widget
          const AchievementsWidget(),
          
          const SizedBox(height: 16),
          
          _buildFeatureHighlight(
            'Gamification Elements',
            [
              'Weekly leaderboards',
              'Achievement system',
              'Points & rewards',
              'Streak tracking',
              'Badges & rarities',
              'Social competition',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary,
            PulseColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDemo(String label, UserStatus status) {
    return Column(
      children: [
        StatusIndicatorWidget(
          status: status,
          size: StatusIndicatorSize.large,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHighlight(String title, List<String> features) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: PulseColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
