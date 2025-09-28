import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/ai_chat_assistant_service.dart';
import '../../../data/services/service_locator.dart';
import '../../../core/utils/logger.dart';
import '../../theme/pulse_colors.dart';

/// Rich AI Chat Assistant Modal for user-to-user messaging assistance
/// Provides comprehensive context selection and modern UX
class RichAiChatAssistantModal extends StatefulWidget {
  final String conversationId;
  final String? currentUserId;
  final String? matchUserId;
  final String? specificMessage; // For message-specific assistance
  final VoidCallback onClose;
  final Function(String message) onApplyToChat;

  const RichAiChatAssistantModal({
    super.key,
    required this.conversationId,
    this.currentUserId,
    this.matchUserId,
    this.specificMessage,
    required this.onClose,
    required this.onApplyToChat,
  });

  @override
  State<RichAiChatAssistantModal> createState() => _RichAiChatAssistantModalState();
}

class _RichAiChatAssistantModalState extends State<RichAiChatAssistantModal>
    with TickerProviderStateMixin {
  final TextEditingController _requestController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Context selection options
  bool _includeMyProfile = false;
  bool _includeMatchProfile = true;
  bool _includeConversation = true;
  bool _includeMatchGallery = false;
  bool _includePreferences = false;
  double _conversationMessageLimit = 20;
  
  // AI assistance state
  AiAssistanceType _assistanceType = AiAssistanceType.response;
  MessageTone _selectedTone = MessageTone.friendly;
  AiChatAssistanceResponse? _currentResponse;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Response refinement state
  bool _isRefining = false;
  final TextEditingController _refinementController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeForSpecificMessage();
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
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _initializeForSpecificMessage() {
    if (widget.specificMessage != null) {
      _requestController.text = 'Help me respond to: "${widget.specificMessage}"';
      _assistanceType = AiAssistanceType.response;
      _includeConversation = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _requestController.dispose();
    _refinementController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: SlideTransition(
            position: _slideAnimation,
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAssistanceTypeSelector(),
                              const SizedBox(height: 24),
                              _buildUserRequestInput(),
                              const SizedBox(height: 24),
                              _buildContextSelection(),
                              const SizedBox(height: 24),
                              _buildToneSelector(),
                              const SizedBox(height: 24),
                              _buildGenerateButton(),
                              if (_errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildErrorMessage(),
                              ],
                              if (_currentResponse != null) ...[
                                const SizedBox(height: 24),
                                _buildResponseSection(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.psychology_outlined,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'AI Chat Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _closeModal,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistanceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need help with?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AiAssistanceType.values.map((type) {
            final isSelected = _assistanceType == type;
            return InkWell(
              onTap: () => setState(() => _assistanceType = type),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [PulseColors.primary, PulseColors.secondary],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  _getAssistanceTypeLabel(type),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserRequestInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe what you need',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Be specific about what kind of help you want with this conversation',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[50],
          ),
          child: TextField(
            controller: _requestController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g., "Help me write a flirty response" or "Suggest conversation starters"',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
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
          'Context to include',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select what information the AI should use to help you',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildContextOption(
          'My Profile',
          'Include your profile information and interests',
          _includeMyProfile,
          (value) => setState(() => _includeMyProfile = value),
          Icons.person_outline,
        ),
        _buildContextOption(
          'Match Profile',
          'Include your match\'s profile and interests',
          _includeMatchProfile,
          (value) => setState(() => _includeMatchProfile = value),
          Icons.favorite_border,
        ),
        _buildContextOption(
          'Conversation History',
          'Include recent messages for context',
          _includeConversation,
          (value) => setState(() => _includeConversation = value),
          Icons.chat_bubble_outline,
        ),
        if (_includeConversation) _buildMessageLimitSlider(),
        _buildContextOption(
          'Match Gallery',
          'Include your match\'s photos for reference',
          _includeMatchGallery,
          (value) => setState(() => _includeMatchGallery = value),
          Icons.photo_library_outlined,
        ),
        _buildContextOption(
          'Preferences',
          'Include dating preferences and compatibility',
          _includePreferences,
          (value) => setState(() => _includePreferences = value),
          Icons.tune,
        ),
      ],
    );
  }

  Widget _buildContextOption(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? PulseColors.primary.withOpacity(0.3) : Colors.grey[300]!,
        ),
        color: value ? PulseColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? PulseColors.primary : Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value ? PulseColors.primary : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
            activeColor: PulseColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageLimitSlider() {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Message limit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_conversationMessageLimit.toInt()} messages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PulseColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: PulseColors.primary,
              thumbColor: PulseColors.primary,
              overlayColor: PulseColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _conversationMessageLimit,
              min: 5,
              max: 50,
              divisions: 9,
              label: '${_conversationMessageLimit.toInt()}',
              onChanged: (value) {
                setState(() => _conversationMessageLimit = value);
              },
            ),
          ),
          Text(
            'Fewer messages = lower cost, more messages = better context',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Response tone',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MessageTone.values.map((tone) {
            final isSelected = _selectedTone == tone;
            return InkWell(
              onTap: () => setState(() => _selectedTone = tone),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? PulseColors.secondary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? PulseColors.secondary : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  tone.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: PulseColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: PulseColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateAssistance,
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Generate AI Assistance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResponseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Suggestion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildResponseCard(),
        if (_currentResponse!.alternatives.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAlternativesSection(),
        ],
        const SizedBox(height: 16),
        _buildActionButtons(),
        if (_isRefining) ...[
          const SizedBox(height: 16),
          _buildRefinementSection(),
        ],
      ],
    );
  }

  Widget _buildResponseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withOpacity(0.05),
            PulseColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentResponse!.suggestion,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (_currentResponse!.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentResponse!.reasoning,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alternative suggestions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...(_currentResponse!.alternatives.take(3).map((alternative) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              alternative,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PulseColors.primary,
              side: BorderSide(color: PulseColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _startRefinement,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Refine'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _applyToChat,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefinementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refine this response',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _refinementController,
            decoration: const InputDecoration(
              hintText: 'e.g., "Make it more casual" or "Add some humor"',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelRefinement,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _refineResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Refine'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getAssistanceTypeLabel(AiAssistanceType type) {
    switch (type) {
      case AiAssistanceType.response:
        return 'Response Help';
      case AiAssistanceType.icebreaker:
        return 'Conversation Starters';
      case AiAssistanceType.refinement:
        return 'Message Refinement';
      case AiAssistanceType.custom:
        return 'Custom Request';
    }
  }

  // Action methods
  Future<void> _generateAssistance() async {
    if (_requestController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please describe what you need help with';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final aiService = ServiceLocator().aiChatAssistantService;
      final contextOptions = AiContextOptions(
        includeMyProfile: _includeMyProfile,
        includeMatchProfile: _includeMatchProfile,
        includeConversation: _includeConversation,
        includeMatchGallery: _includeMatchGallery,
        includePreferences: _includePreferences,
        conversationMessageLimit: _conversationMessageLimit.toInt(),
      );

      final response = await aiService.getChatAssistance(
        assistanceType: _assistanceType,
        conversationId: widget.conversationId,
        userRequest: _requestController.text.trim(),
        contextOptions: contextOptions,
        specificMessage: widget.specificMessage,
        tone: _selectedTone,
        suggestionCount: 3,
      );

      setState(() {
        _currentResponse = response;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate assistance: ${e.toString()}';
      });
      AppLogger.error('AI assistance generation failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_currentResponse != null) {
      Clipboard.setData(ClipboardData(text: _currentResponse!.suggestion));
      _showSnackBar('Copied to clipboard', Icons.copy);
    }
  }

  void _startRefinement() {
    setState(() {
      _isRefining = true;
      _refinementController.clear();
    });
  }

  void _cancelRefinement() {
    setState(() {
      _isRefining = false;
      _refinementController.clear();
    });
  }

  Future<void> _refineResponse() async {
    if (_refinementController.text.trim().isEmpty || _currentResponse == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final aiService = ServiceLocator().aiChatAssistantService;
      
      final refinedMessage = await aiService.refineMessage(
        originalMessage: _currentResponse!.suggestion,
        refinementRequest: _refinementController.text.trim(),
        conversationId: widget.conversationId,
        contextOptions: AiContextOptions(
          includeMyProfile: _includeMyProfile,
          includeMatchProfile: _includeMatchProfile,
          includeConversation: _includeConversation,
          conversationMessageLimit: _conversationMessageLimit.toInt(),
        ),
        targetTone: _selectedTone,
      );

      setState(() {
        _currentResponse = AiChatAssistanceResponse(
          suggestion: refinedMessage,
          reasoning: 'Refined based on your feedback: ${_refinementController.text}',
          alternatives: [],
          contextUsed: _currentResponse!.contextUsed,
          metadata: _currentResponse!.metadata,
        );
        _isRefining = false;
        _refinementController.clear();
      });

      _showSnackBar('Response refined successfully', Icons.check);
    } catch (e) {
      _showSnackBar('Failed to refine response', Icons.error);
      AppLogger.error('Response refinement failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyToChat() {
    if (_currentResponse != null) {
      widget.onApplyToChat(_currentResponse!.suggestion);
      _showSnackBar('Applied to chat', Icons.send);
      _closeModal();
    }
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: PulseColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}