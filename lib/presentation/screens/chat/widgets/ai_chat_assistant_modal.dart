import 'package:flutter/material.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/services/ai_chat_assistant_service.dart';

class AiChatAssistantModal extends StatefulWidget {
  final UserModel? currentUser;
  final UserModel? matchProfile;
  final List<MessageModel> recentMessages;
  final String? currentMessage;
  final Function(String)? onMessageGenerated;
  final Function(String)? onMessageRefined;

  const AiChatAssistantModal({
    super.key,
    this.currentUser,
    this.matchProfile,
    this.recentMessages = const [],
    this.currentMessage,
    this.onMessageGenerated,
    this.onMessageRefined,
  });

  @override
  State<AiChatAssistantModal> createState() => _AiChatAssistantModalState();
}

class _AiChatAssistantModalState extends State<AiChatAssistantModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AiChatAssistantService _aiService;
  
  bool _isLoading = false;
  List<String> _suggestions = [];
  String? _error;

  // Context selection
  bool _includeMyProfile = true;
  bool _includeMatchProfile = true;
  bool _includeConversation = true;
  bool _includeMatchGallery = false;
  bool _includePreferences = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _aiService = AiChatAssistantService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateSuggestions(AiAssistanceType type) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestions.clear();
    });

    try {
      final response = await _aiService.generateAssistance(
        type,
        widget.recentMessages,
        includeMyProfile: _includeMyProfile,
        includeMatchProfile: _includeMatchProfile,
        includeConversation: _includeConversation,
        includeMatchGallery: _includeMatchGallery,
        includePreferences: _includePreferences,
        specificMessage: widget.currentMessage,
        currentUser: widget.currentUser,
        matchProfile: widget.matchProfile,
      );

      setState(() {
        _suggestions = response.alternatives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateIcebreakers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestions.clear();
    });

    try {
      final icebreakers = await _aiService.generateIcebreakers(
        conversationId: '',
        userId: widget.currentUser?.id ?? '',
        currentUser: widget.currentUser,
        matchProfile: widget.matchProfile,
      );

      final response = AiAssistanceResponse(
        id: 'icebreakers',
        message: '',
        tone: 'friendly',
        reasoning: 'Generated icebreakers',
        alternatives: icebreakers,
        metadata: {},
      );

      setState(() {
        _suggestions = response.alternatives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildContextSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Context Selection',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose what information to include for better AI assistance:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildContextToggle(
            'My Profile',
            'Include your profile details (bio, interests, etc.)',
            _includeMyProfile,
            (value) => setState(() => _includeMyProfile = value),
          ),
          _buildContextToggle(
            'Match Profile',
            'Include their profile information',
            _includeMatchProfile,
            (value) => setState(() => _includeMatchProfile = value),
          ),
          _buildContextToggle(
            'Conversation History',
            'Include recent messages for context',
            _includeConversation,
            (value) => setState(() => _includeConversation = value),
          ),
          _buildContextToggle(
            'Match Photos',
            'Include information about their photos',
            _includeMatchGallery,
            (value) => setState(() => _includeMatchGallery = value),
          ),
          _buildContextToggle(
            'Communication Preferences',
            'Include your communication style preferences',
            _includePreferences,
            (value) => setState(() => _includePreferences = value),
          ),
        ],
      ),
    );
  }

  Widget _buildContextToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6E3BFF),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No suggestions available.\nTry adjusting the context or generating new ones.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(suggestion),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Copy to clipboard
                    Navigator.of(context).pop();
                    if (widget.onMessageGenerated != null) {
                      widget.onMessageGenerated!(suggestion);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onMessageGenerated != null) {
                      widget.onMessageGenerated!(suggestion);
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).pop();
              if (widget.onMessageGenerated != null) {
                widget.onMessageGenerated!(suggestion);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF6E3BFF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Chat Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6E3BFF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6E3BFF),
            tabs: const [
              Tab(text: 'Reply Help'),
              Tab(text: 'Icebreakers'),
              Tab(text: 'Refine Message'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Reply Help Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContextSelector(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _generateSuggestions(AiAssistanceType.responseAssistance),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Reply Suggestions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E3BFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionsList(),
                    ],
                  ),
                ),

                // Icebreakers Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Get personalized conversation starters based on their profile!',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generateIcebreakers,
                          icon: const Icon(Icons.ac_unit),
                          label: const Text('Generate Icebreakers'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionsList(),
                    ],
                  ),
                ),

                // Refine Message Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.currentMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Message:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(widget.currentMessage!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _generateSuggestions(AiAssistanceType.messageRefinement),
                            icon: const Icon(Icons.edit),
                            label: const Text('Refine Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4AA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSuggestionsList(),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Type a message first to refine it with AI assistance.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
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