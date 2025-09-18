import 'package:flutter/material.dart';

import '../../../data/services/service_locator.dart';
import '../../../data/services/auto_reply_service.dart';
import '../../../core/services/service_locator.dart' as core;
import '../../theme/pulse_colors.dart';

class AiMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onVoice;
  final String? lastReceivedMessage;
  final String chatId;

  const AiMessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.chatId,
    this.onTyping,
    this.onCamera,
    this.onGallery,
    this.onVoice,
    this.lastReceivedMessage,
  });

  @override
  State<AiMessageInput> createState() => _AiMessageInputState();
}

class _AiMessageInputState extends State<AiMessageInput>
    with TickerProviderStateMixin {
  bool _isComposing = false;
  bool _showAttachments = false;
  bool _showAiSuggestions = false;
  bool _isLoadingSuggestions = false;
  
  List<String> _suggestions = [];
  String _selectedSuggestion = '';
  String _aiPrompt = '';
  
  late AnimationController _aiGlowController;
  late AnimationController _suggestionController;
  late Animation<double> _aiGlowAnimation;
  late Animation<double> _suggestionAnimation;
  
  final AutoReplyService _autoReplyService = ServiceLocator().autoReplyService;
  final TextEditingController _aiPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    
    // Initialize animations for futuristic effects
    _aiGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _suggestionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _aiGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _aiGlowController, curve: Curves.easeInOut),
    );
    _suggestionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _suggestionController, curve: Curves.easeOutBack),
    );
    
    _aiGlowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _aiGlowController.dispose();
    _suggestionController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = widget.controller.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
    widget.onTyping?.call();
  }

  void _onSendPressed() {
    if (_isComposing) {
      widget.onSend();
      setState(() {
        _showAiSuggestions = false;
        _suggestions.clear();
      });
    }
  }

  Future<void> _generateAiSuggestions() async {
    if (widget.lastReceivedMessage == null) return;
    
    // Check if AI suggestions are enabled
    final aiPreferences = core.ServiceLocator.instance.aiPreferences;
    final isEnabled = await aiPreferences.isFeatureEnabled('auto_suggestions');
    
    if (!isEnabled) {
      return;
    }
    
    setState(() {
      _isLoadingSuggestions = true;
      _showAiSuggestions = true;
    });
    
    _suggestionController.forward();
    
    try {
      final suggestions = await _autoReplyService.generateReplySuggestions(
        conversationId: widget.chatId,
        lastMessage: widget.lastReceivedMessage!,
        count: 3,
      );
      
      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
        _showAiSuggestions = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate suggestions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateCustomAiReply() async {
    if (_aiPrompt.isEmpty) return;
    
    setState(() {
      _isLoadingSuggestions = true;
    });
    
    try {
      final customReply = await _autoReplyService.generateCustomReply(
        conversationId: widget.chatId,
        lastMessage: widget.lastReceivedMessage ?? '',
        userInstructions: _aiPrompt,
      );
      
      setState(() {
        _selectedSuggestion = customReply ?? '';
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate custom reply: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    setState(() {
      _isComposing = true;
      _selectedSuggestion = suggestion;
    });
  }

  void _showAiCustomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAiCustomModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          if (_showAiSuggestions) _buildAiSuggestions(),
          if (_showAttachments) _buildAttachmentOptions(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAttachmentButton(),
              const SizedBox(width: 8),
              Expanded(child: _buildTextInput()),
              const SizedBox(width: 8),
              _buildAiButton(),
              const SizedBox(width: 8),
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiButton() {
    return AnimatedBuilder(
      animation: _aiGlowAnimation,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PulseColors.primary.withValues(
                  alpha: 0.7 + 0.3 * _aiGlowAnimation.value,
                ),
                PulseColors.secondary.withValues(
                  alpha: 0.7 + 0.3 * _aiGlowAnimation.value,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PulseColors.primary.withValues(
                  alpha: 0.3 * _aiGlowAnimation.value,
                ),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isLoadingSuggestions ? Icons.auto_awesome : Icons.psychology,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _isLoadingSuggestions ? null : () {
              if (_showAiSuggestions) {
                _showAiCustomModal();
              } else {
                _generateAiSuggestions();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAiSuggestions() {
    return AnimatedBuilder(
      animation: _suggestionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _suggestionAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PulseColors.primary.withValues(alpha: 0.1),
                  PulseColors.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PulseColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: PulseColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Suggestions',
                      style: TextStyle(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _showAiSuggestions = false;
                          _suggestions.clear();
                        });
                        _suggestionController.reverse();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoadingSuggestions)
                  _buildLoadingIndicator()
                else
                  _buildSuggestionsList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 60,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is thinking...',
              style: TextStyle(
                color: PulseColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      children: _suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _useSuggestion(suggestion),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAiCustomModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PulseColors.primary, PulseColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Reply Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Describe how AI should reply',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // AI Prompt Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PulseColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _aiPromptController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'e.g., "Reply with a funny response" or "Be supportive and caring"',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _aiPrompt = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _aiPrompt.isEmpty || _isLoadingSuggestions
                          ? null
                          : () async {
                              await _generateCustomAiReply();
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingSuggestions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Generate AI Reply',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Generated Reply Preview
                  if (_selectedSuggestion.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PulseColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: PulseColors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Generated Reply',
                                style: TextStyle(
                                  color: PulseColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedSuggestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await _generateCustomAiReply();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: PulseColors.primary),
                                    foregroundColor: PulseColors.primary,
                                  ),
                                  child: const Text('Regenerate'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _useSuggestion(_selectedSuggestion);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PulseColors.secondary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Use Reply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return IconButton(
      icon: Icon(
        _showAttachments ? Icons.close : Icons.add,
        color: Colors.grey[600],
      ),
      onPressed: () {
        setState(() {
          _showAttachments = !_showAttachments;
        });
      },
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Type a message...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: (_) => _onSendPressed(),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _isComposing ? PulseColors.primary : Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isComposing ? Icons.send : Icons.mic,
          color: Colors.white,
          size: 20,
        ),
        onPressed: _isComposing ? _onSendPressed : widget.onVoice,
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            color: Colors.blue,
            onTap: widget.onCamera,
          ),
          const SizedBox(width: 16),
          _buildAttachmentOption(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.green,
            onTap: widget.onGallery,
          ),
          const SizedBox(width: 16),
          _buildAttachmentOption(
            icon: Icons.location_on,
            label: 'Location',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing current location...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}