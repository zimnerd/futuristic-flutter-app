import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/match/match_bloc.dart';
import '../../blocs/match/match_state.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../screens/matches/matches_screen.dart';

/// Widget showing match success and conversation options
class MatchSuccessWidget extends StatelessWidget {
  const MatchSuccessWidget({
    super.key,
    required this.match,
    this.onStartChat,
    this.onKeepSwiping,
  });

  final MatchModel match;
  final VoidCallback? onStartChat;
  final VoidCallback? onKeepSwiping;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Celebration animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Match announcement
          const Text(
            "It's a Match! 🎉",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'You and they both liked each other!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Compatibility score
          if (match.compatibilityScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                '${(match.compatibilityScore * 100).round()}% Compatible',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Profile cards placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ProfileCard(isCurrentUser: true),
              const SizedBox(width: 24),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 24),
              _ProfileCard(isCurrentUser: false),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Start chatting button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStartChat ?? () => _startChat(context),
                    icon: const Icon(Icons.chat_bubble),
                    label: const Text('Start Chatting'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Keep swiping button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onKeepSwiping ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.explore),
                    label: const Text('Keep Swiping'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context) {
    // Navigate to matches screen or directly to chat
    Navigator.of(context).pop(); // Close the match success modal
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MatchesScreen(),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.isCurrentUser});

  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Icon(
              Icons.person,
              size: 25,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCurrentUser ? 'You' : 'Match',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen that handles the match creation flow
class MatchHandlerScreen extends StatelessWidget {
  const MatchHandlerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchBloc, MatchState>(
      listener: (context, state) {
        if (state is MatchCreated && state.isNewMatch) {
          // Show match success modal
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: false,
            enableDrag: false,
            builder: (context) => MatchSuccessWidget(
              match: state.match,
              onStartChat: () {
                Navigator.of(context).pop(); // Close modal
                _startConversationWithMatch(context, state.match);
              },
            ),
          );
        }
      },
      child: const SizedBox.shrink(), // This widget is just a listener
    );
  }

  void _startConversationWithMatch(BuildContext context, MatchModel match) {
    // Start conversation with a default greeting
    context.read<MessagingBloc>().add(
      StartConversation(
        matchId: match.id,
        initialMessage: "Hey! Great match! 😊",
      ),
    );
    
    // Navigate to matches screen to see the new conversation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MatchesScreen(),
      ),
    );
  }
}
