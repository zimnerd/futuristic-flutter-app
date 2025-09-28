import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/logger.dart';
import '../../theme/pulse_colors.dart';

/// AI Chat Assistant Modal for user-to-user messaging assistance
/// Provides rich context selection and AI-powered message generation
class AiChatAssistantModal extends StatefulWidget {
  final String conversationId;
  final UserModel? currentUser;
  final UserModel? matchProfile;
  final List<MessageModel> recentMessages;
  final MessageModel? specificMessage; // For reply assistance
  final VoidCallback onClose;
  final Function(String message) onApplyToChat;

  const AiChatAssistantModal({
    super.key,
    required this.conversationId,
    this.currentUser,
    this.matchProfile,
    this.recentMessages = const [],
    this.specificMessage,
    required this.onClose,
    required this.onApplyToChat,
  });

  @override
  State<AiChatAssistantModal> createState() => _AiChatAssistantModalState();
}

class _AiChatAssistantModalState extends State<AiChatAssistantModal>
    with TickerProviderStateMixin {
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Context selection
  bool _includeMyProfile = false;
  bool _includeMatchProfile = true;
  bool _includeConversation = true;
  bool _includeMatchGallery = false;
  bool _includePreferences = false;
  int _messageLimit = 10;
  
  // AI assistance state
  bool _isGenerating = false;
  bool _hasResponse = false;
  
  // Quick prompts for common scenarios
  final List<String> _quickPrompts = [
    "Help me reply to this message in a flirty way",
    "Suggest a fun conversation starter",
    "Help me ask them out on a date",
    "Write a compliment about their photos",
    "Help me respond with humor",
    "Suggest a question to learn more about them",
    "Help me show genuine interest",
    "Write a message to keep the conversation going",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeRequest();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  void _initializeRequest() {
    if (widget.specificMessage != null) {
      _requestController.text = "Help me reply to: \"${widget.specificMessage!.content}\"";
      _includeConversation = true;
    } else if (widget.recentMessages.isEmpty) {
      _requestController.text = "Help me start a conversation with ${widget.matchProfile?.firstName ?? 'this person'}";
      _includeMatchProfile = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _requestController.dispose();
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRequestSection(),
                          const SizedBox(height: 24),
                          _buildContextSelection(),
                          const SizedBox(height: 24),
                          _buildQuickPrompts(),
                          const SizedBox(height: 24),
                          _buildGenerateButton(),
                          if (_hasResponse) ...[
                            const SizedBox(height: 24),
                            _buildResponseSection(),
                          ],
                        ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PulseColors.primary, PulseColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Chat Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.specificMessage != null
                          ? 'Get help replying to a message'
                          : 'Get AI assistance with your conversation',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like help with?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _requestController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe what kind of message you want to send...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildContextSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Include Context',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select what information to share with AI',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        _buildContextOption(
          'My Profile',
          'Include your profile information',
          _includeMyProfile,
          (value) => setState(() => _includeMyProfile = value),
          Icons.person,
        ),
        _buildContextOption(
          'Match Profile',
          'Include ${widget.matchProfile?.firstName ?? 'their'} profile',
          _includeMatchProfile,
          (value) => setState(() => _includeMatchProfile = value),
          Icons.favorite,
        ),
        _buildContextOption(
          'Conversation History',
          'Include recent messages (${widget.recentMessages.length} available)',
          _includeConversation,
          (value) => setState(() => _includeConversation = value),
          Icons.chat,
        ),
        if (_includeConversation && widget.recentMessages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message limit: $_messageLimit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Slider(
                  value: _messageLimit.toDouble(),
                  min: 1,
                  max: widget.recentMessages.length.toDouble().clamp(1, 20),
                  divisions: (widget.recentMessages.length.clamp(1, 20) - 1),
                  activeColor: PulseColors.primary,
                  onChanged: (value) {
                    setState(() => _messageLimit = value.round());
                  },
                ),
              ],
            ),
          ),
        _buildContextOption(
          'Match Gallery',
          'Include their photos for context',
          _includeMatchGallery,
          (value) => setState(() => _includeMatchGallery = value),
          Icons.photo_library,
        ),
        _buildContextOption(
          'My Preferences',
          'Include your dating preferences',
          _includePreferences,
          (value) => setState(() => _includePreferences = value),
          Icons.tune,
        ),
      ],
    );
  }

  Widget _buildContextOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: value ? PulseColors.primary.withOpacity(0.3) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
        color: value ? PulseColors.primary.withOpacity(0.05) : null,
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value ? PulseColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: value ? PulseColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        activeColor: PulseColors.primary,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Prompts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to use common assistance scenarios',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickPrompts.map((prompt) {
            return GestureDetector(
              onTap: () {
                _requestController.text = prompt;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: PulseColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                  color: PulseColors.primary.withOpacity(0.05),
                ),
                child: Text(
                  prompt,
                  style: TextStyle(
                    color: PulseColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateAiResponse,
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI is thinking...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Generate AI Response',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResponseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Generated Response',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _responseController,
            maxLines: null,
            minLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'AI response will appear here...',
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _refineResponse,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Refine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.secondary.withOpacity(0.1),
                  foregroundColor: PulseColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Apply to chat
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _applyToChat,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Apply to Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAiResponse() async {
    if (_requestController.text.trim().isEmpty) {
      _showSnackBar('Please enter your request first');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Build context for AI
      final context = _buildAiContext();
      
      // TODO: Replace with actual AI service call
      await _mockAiGeneration(context);
      
    } catch (e) {
      AppLogger.error('Error generating AI response: $e');
      _showSnackBar('Failed to generate response. Please try again.');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Map<String, dynamic> _buildAiContext() {
    final context = <String, dynamic>{
      'request': _requestController.text.trim(),
      'conversationId': widget.conversationId,
    };

    if (_includeMyProfile && widget.currentUser != null) {
      context['myProfile'] = {
        'name': '${widget.currentUser!.firstName ?? ''} ${widget.currentUser!.lastName ?? ''}',
        'age': widget.currentUser!.age,
        'bio': widget.currentUser!.bio,
        // Add other relevant profile fields
      };
    }

    if (_includeMatchProfile && widget.matchProfile != null) {
      context['matchProfile'] = {
        'name': '${widget.matchProfile!.firstName ?? ''} ${widget.matchProfile!.lastName ?? ''}',
        'age': widget.matchProfile!.age,
        'bio': widget.matchProfile!.bio,
        // Add other relevant profile fields
      };
    }

    if (_includeConversation && widget.recentMessages.isNotEmpty) {
      final messagesToInclude = widget.recentMessages
          .take(_messageLimit)
          .map((msg) => {
                'sender': msg.senderId,
                'content': msg.content,
                'timestamp': msg.createdAt.toIso8601String(),
                'type': msg.type.name,
              })
          .toList();
      context['recentMessages'] = messagesToInclude;
    }

    if (widget.specificMessage != null) {
      context['specificMessage'] = {
        'content': widget.specificMessage!.content,
        'sender': widget.specificMessage!.senderId,
        'type': widget.specificMessage!.type.name,
      };
    }

    return context;
  }

  Future<void> _mockAiGeneration(Map<String, dynamic> context) async {
    // Mock AI generation with realistic delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock responses based on request type
    String mockResponse = _generateMockResponse();
    
    setState(() {
      _responseController.text = mockResponse;
      _hasResponse = true;
    });
    
    // Auto-scroll to response
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateMockResponse() {
    final request = _requestController.text.toLowerCase();
    
    if (request.contains('flirt')) {
      return "Hey! I noticed you mentioned [specific detail from their profile]. That's actually really cool - I've always been curious about that too! What got you into it? 😊";
    } else if (request.contains('date') || request.contains('ask out')) {
      return "I've been really enjoying our conversation! Would you be interested in continuing it over coffee sometime this week? I know a great little place that has amazing [mention something from their interests]. What do you think?";
    } else if (request.contains('humor') || request.contains('funny')) {
      return "Okay, I have to ask - are you always this [interesting/adventurous/creative] or are you just trying to make the rest of us look bad? 😄 Because it's working!";
    } else if (request.contains('compliment')) {
      return "I have to say, your smile in that [second/third] photo is absolutely captivating! You seem like someone who really knows how to enjoy life. What's the story behind that picture?";
    } else if (request.contains('start') || request.contains('conversation')) {
      return "Hi ${widget.matchProfile?.firstName ?? 'there'}! I couldn't help but notice [specific detail from their profile/photos]. That looks like it was an amazing experience! I'd love to hear more about it if you're up for sharing 😊";
    } else {
      return "That's such an interesting point! I can really see where you're coming from. Have you always felt that way, or is it something you've developed over time? I'm curious to hear your perspective!";
    }
  }

  void _copyToClipboard() {
    if (_responseController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _responseController.text));
      _showSnackBar('Copied to clipboard!');
    }
  }

  void _refineResponse() {
    // Update request with refinement prompt
    _requestController.text = "Please refine this response: \"${_responseController.text}\"";
    
    // Clear current response and regenerate
    setState(() {
      _hasResponse = false;
      _responseController.clear();
    });
    
    _generateAiResponse();
  }

  void _applyToChat() {
    if (_responseController.text.isNotEmpty) {
      widget.onApplyToChat(_responseController.text);
      widget.onClose();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}