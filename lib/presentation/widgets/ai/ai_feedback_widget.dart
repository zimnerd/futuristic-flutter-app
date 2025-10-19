import 'package:flutter/material.dart';
import 'package:pulse_dating_app/data/services/ai_feedback_service.dart';
import '../common/pulse_toast.dart';

/// AI Feedback Widget - collects user feedback and ratings for AI features
/// Supports quick ratings, detailed feedback, and improvement suggestions
class AiFeedbackWidget extends StatefulWidget {
  final String featureType;
  final String featureId;
  final String userId;
  final String? title;
  final String? description;
  final VoidCallback? onComplete;

  const AiFeedbackWidget({
    super.key,
    required this.featureType,
    required this.featureId,
    required this.userId,
    this.title,
    this.description,
    this.onComplete,
  });

  @override
  State<AiFeedbackWidget> createState() => _AiFeedbackWidgetState();
}

class _AiFeedbackWidgetState extends State<AiFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _overallRating = 0;
  int _helpfulnessRating = 0;
  int _accuracyRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _showDetailedFeedback = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: _buildFeedbackContent(),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (!_showDetailedFeedback) ...[
            _buildQuickRating(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ] else ...[
            _buildDetailedFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
            ),
          ),
          child: const Icon(
            Icons.feedback_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'How was this AI feature?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.description != null)
                Text(
                  widget.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildQuickRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Rating',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 1; i <= 5; i++) ...[
              GestureDetector(
                onTap: () => setState(() => _overallRating = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.star_rounded,
                    size: 32,
                    color: i <= _overallRating
                        ? const Color(0xFFFFD700)
                        : Colors.white30,
                  ),
                ),
              ),
              if (i < 5) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _overallRating > 0 ? _submitQuickFeedback : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E3BFF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Submit'),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => setState(() => _showDetailedFeedback = true),
          child: const Text(
            'More Details',
            style: TextStyle(color: Color(0xFF00C2FF)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingSection(
          'Overall Rating',
          _overallRating,
          (rating) => setState(() => _overallRating = rating),
        ),
        const SizedBox(height: 16),
        _buildRatingSection(
          'Helpfulness',
          _helpfulnessRating,
          (rating) => setState(() => _helpfulnessRating = rating),
        ),
        const SizedBox(height: 16),
        _buildRatingSection(
          'Accuracy',
          _accuracyRating,
          (rating) => setState(() => _accuracyRating = rating),
        ),
        const SizedBox(height: 20),
        _buildCommentSection(),
        const SizedBox(height: 20),
        _buildDetailedActions(),
      ],
    );
  }

  Widget _buildRatingSection(
    String title,
    int currentRating,
    Function(int) onRatingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 1; i <= 5; i++) ...[
              GestureDetector(
                onTap: () => onRatingChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 24,
                    color: i <= currentRating
                        ? const Color(0xFFFFD700)
                        : Colors.white30,
                  ),
                ),
              ),
              if (i < 5) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Tell us how we can improve...',
              hintStyle: TextStyle(color: Colors.white60),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedActions() {
    final bool canSubmit =
        _overallRating > 0 ||
        _helpfulnessRating > 0 ||
        _accuracyRating > 0 ||
        _commentController.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: canSubmit ? _submitDetailedFeedback : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E3BFF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Submit Feedback'),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => setState(() => _showDetailedFeedback = false),
          child: const Text('Back', style: TextStyle(color: Colors.white60)),
        ),
      ],
    );
  }

  Future<void> _submitQuickFeedback() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await AiFeedbackService.instance.quickRateSuggestion(
        userId: widget.userId,
        suggestionId: widget.featureId,
        featureType: widget.featureType,
        isPositive: _overallRating >= 3,
      );

      if (success && mounted) {
        _showSuccessMessage('Thank you for your feedback!');
        Navigator.of(context).pop();
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to submit feedback. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitDetailedFeedback() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await AiFeedbackService.instance.submitGeneralAiFeedback(
        userId: widget.userId,
        aiResponseId: widget.featureId,
        featureType: widget.featureType,
        rating: _overallRating > 0
            ? _overallRating
            : (_helpfulnessRating > 0 ? _helpfulnessRating : 3),
        satisfaction: _helpfulnessRating > 0
            ? _helpfulnessRating
            : (_overallRating > 0 ? _overallRating : 3),
        comment: _commentController.text.isEmpty
            ? null
            : _commentController.text,
        context: {
          'helpfulness': _helpfulnessRating,
          'accuracy': _accuracyRating,
          'feature_id': widget.featureId,
        },
      );

      if (success && mounted) {
        _showSuccessMessage('Thank you for your detailed feedback!');
        Navigator.of(context).pop();
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to submit feedback. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    PulseToast.success(context, message: message);
  }

  void _showErrorMessage(String message) {
    PulseToast.error(context, message: message);
  }
}

/// Quick feedback button for inline use
class AiQuickFeedbackButton extends StatelessWidget {
  final String featureType;
  final String featureId;
  final String userId;
  final bool isPositive;
  final VoidCallback? onPressed;

  const AiQuickFeedbackButton({
    super.key,
    required this.featureType,
    required this.featureId,
    required this.userId,
    required this.isPositive,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _submitQuickFeedback(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
              size: 16,
              color: isPositive ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              isPositive ? 'Helpful' : 'Not helpful',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuickFeedback(BuildContext context) async {
    try {
      await AiFeedbackService.instance.quickRateSuggestion(
        userId: userId,
        suggestionId: featureId,
        featureType: featureType,
        isPositive: isPositive,
      );

      onPressed?.call();

      if (context.mounted) {
        PulseToast.success(context, message: 'Feedback submitted!');
      }
    } catch (e) {
      if (context.mounted) {
        PulseToast.error(context, message: 'Failed to submit feedback');
      }
    }
  }
}
