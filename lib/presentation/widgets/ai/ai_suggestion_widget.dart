import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_feedback_widget.dart';

/// AI Suggestion Widget - displays AI-generated suggestions with feedback collection
/// Used for conversation suggestions, profile improvements, and compatibility insights
class AiSuggestionWidget extends StatefulWidget {
  final String title;
  final String suggestion;
  final String? reasoning;
  final double? confidence;
  final String suggestionId;
  final String featureType;
  final String userId;
  final IconData? icon;
  final VoidCallback? onUse;
  final VoidCallback? onDismiss;
  final VoidCallback? onFeedback;

  const AiSuggestionWidget({
    super.key,
    required this.title,
    required this.suggestion,
    required this.suggestionId,
    required this.featureType,
    required this.userId,
    this.reasoning,
    this.confidence,
    this.icon,
    this.onUse,
    this.onDismiss,
    this.onFeedback,
  });

  @override
  State<AiSuggestionWidget> createState() => _AiSuggestionWidgetState();
}

class _AiSuggestionWidgetState extends State<AiSuggestionWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isExpanded = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    
    // Subtle pulse animation for AI badge
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6E3BFF).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            if (_isExpanded) _buildExpandedContent(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6E3BFF).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon ?? Icons.psychology_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.confidence != null) _buildConfidenceBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF6E3BFF).withOpacity(0.2),
                      ),
                      child: const Text(
                        'AI Generated',
                        style: TextStyle(
                          color: Color(0xFF6E3BFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.expand_more_rounded,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = widget.confidence! * 100;
    final color = _getConfidenceColor(confidence);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.2),
      ),
      child: Text(
        '${confidence.round()}%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Text(
          widget.suggestion,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.reasoning != null) ...[
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.orange.shade300,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'AI Reasoning',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.reasoning!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onUseSuggestion,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Use'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E3BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _onCopySuggestion,
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _onDismissSuggestion,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Dismiss',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          if (!_hasInteracted) ...[
            AiQuickFeedbackButton(
              featureType: widget.featureType,
              featureId: widget.suggestionId,
              userId: widget.userId,
              isPositive: true,
              onPressed: () => setState(() => _hasInteracted = true),
            ),
            const SizedBox(width: 4),
            AiQuickFeedbackButton(
              featureType: widget.featureType,
              featureId: widget.suggestionId,
              userId: widget.userId,
              isPositive: false,
              onPressed: () => setState(() => _hasInteracted = true),
            ),
          ] else
            TextButton(
              onPressed: _showDetailedFeedback,
              child: const Text(
                'Feedback',
                style: TextStyle(
                  color: Color(0xFF00C2FF),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onUseSuggestion() {
    setState(() => _hasInteracted = true);
    widget.onUse?.call();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade300),
            const SizedBox(width: 8),
            const Text('Suggestion used! How did it work?'),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Rate',
          textColor: Colors.white,
          onPressed: _showDetailedFeedback,
        ),
      ),
    );
  }

  void _onCopySuggestion() {
    Clipboard.setData(ClipboardData(text: widget.suggestion));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.blue.shade300),
            const SizedBox(width: 8),
            const Text('Suggestion copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onDismissSuggestion() {
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  void _showDetailedFeedback() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AiFeedbackWidget(
        featureType: widget.featureType,
        featureId: widget.suggestionId,
        userId: widget.userId,
        title: 'Rate this suggestion',
        description: widget.title,
        onComplete: () => setState(() => _hasInteracted = true),
      ),
    );
    
    widget.onFeedback?.call();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return const Color(0xFF00C2FF);
    if (confidence >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// Compact AI suggestion widget for smaller spaces
class CompactAiSuggestion extends StatelessWidget {
  final String suggestion;
  final String suggestionId;
  final String featureType;
  final String userId;
  final VoidCallback? onTap;

  const CompactAiSuggestion({
    super.key,
    required this.suggestion,
    required this.suggestionId,
    required this.featureType,
    required this.userId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}