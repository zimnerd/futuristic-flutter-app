import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/verification_repository.dart';
import '../../../data/models/verification_status.dart';
import '../../widgets/common/pulse_toast.dart';

/// Verification status screen showing pending/approved/rejected states
/// Displays verification requests and their current status
class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  late final VerificationRepository _repository;
  bool _isLoading = true;
  late bool _isVerified;
  late List<VerificationRequest> _requests;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = VerificationRepository();
    _isVerified = false;
    _requests = [];
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await _repository.getVerificationStatus();
      
      if (mounted) {
        setState(() {
          _isVerified = status.hasVerified;
          _requests = _convertToVerificationRequests(status);
          _isLoading = false;
        });
        AppLogger.info('Verification status loaded: ${status.hasVerified}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load verification status: $e';
        });
        AppLogger.error('Failed to load verification status: $e');
        _showError(_errorMessage!);
      }
    }
  }

  List<VerificationRequest> _convertToVerificationRequests(
    VerificationStatus status,
  ) {
    final requests = <VerificationRequest>[];

    if (status.emailVerified) {
      requests.add(
        VerificationRequest(
          id: 'email_${status.emailVerifiedAt?.millisecondsSinceEpoch}',
          type: 'email',
          status: 'approved',
          createdAt: DateTime.now(),
          submittedAt: status.emailVerifiedAt ?? DateTime.now(),
          reviewedAt: status.emailVerifiedAt,
        ),
      );
    }

    if (status.phoneVerified) {
      requests.add(
        VerificationRequest(
          id: 'phone_${status.phoneVerifiedAt?.millisecondsSinceEpoch}',
          type: 'phone',
          status: 'approved',
          createdAt: DateTime.now(),
          submittedAt: status.phoneVerifiedAt ?? DateTime.now(),
          reviewedAt: status.phoneVerifiedAt,
        ),
      );
    }

    return requests;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text(
          'Verification Status',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadVerificationStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isVerified)
                      _buildVerifiedCard()
                    else
                      _buildStatusCard(),
                    const SizedBox(height: 32),
                    if (_requests.isNotEmpty) ...[
                      const Text(
                        'Verification History',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._requests.map((request) => _buildRequestCard(request)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVerifiedCard() {
    // Get verification methods used
    final verificationMethods = <String>[];
    if (_requests.any((r) => r.type == 'email')) {
      verificationMethods.add('Email');
    }
    if (_requests.any((r) => r.type == 'phone')) {
      verificationMethods.add('WhatsApp');
    }

    final methodsText = verificationMethods.isNotEmpty
        ? 'via ${verificationMethods.join(' & ')}'
        : '';

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.8),
              AppColors.success,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re Verified!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your account verified $methodsText',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final hasPendingRequest = _requests.any(
      (r) => r.status == 'pending' || r.status == 'under_review',
    );

    if (hasPendingRequest) {
      return _buildPendingCard();
    } else if (_requests.any((r) => r.status == 'rejected')) {
      return _buildRejectedCard();
    } else {
      return _buildNotStartedCard();
    }
  }

  Widget _buildPendingCard() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Pending',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'re reviewing your submission',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Usually takes 24-48 hours',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRejectedCard() {
    final rejectedRequest = _requests.firstWhere((r) => r.status == 'rejected');

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Declined',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rejectedRequest.rejectionReason ??
                'Unable to verify with provided information',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _retryVerification,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _contactSupport,
            child: const Text(
              'Contact Support',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNotStartedCard() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not Verified Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
              'Verify your email or WhatsApp to build trust with other users',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Choose one verification method:',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Email: Verify via confirmation link',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• WhatsApp: Verify via SMS code',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _startVerification,
                icon: const Icon(Icons.verified_user),
              label: const Text(
                  'Get Verified',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRequestCard(VerificationRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getStatusIcon(request.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRequestTypeLabel(request.type),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusLabel(request.status),
                      style: TextStyle(
                        color: _getStatusColor(request.status),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Submitted ${_formatDateTime(request.submittedAt)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (request.reviewedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reviewed ${_formatDateTime(request.reviewedAt!)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'approved':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = AppColors.error;
        break;
      case 'under_review':
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        break;
      case 'pending':
      default:
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  String _getRequestTypeLabel(String type) {
    switch (type) {
      case 'email':
        return 'Email Verification';
      case 'phone':
        return 'WhatsApp Verification';
      case 'photo':
        return 'Photo Verification';
      case 'id':
        return 'ID Verification';
      case 'social':
        return 'Social Media Verification';
      default:
        return 'Verification Request';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Declined';
      case 'under_review':
        return 'Under Review';
      case 'pending':
      default:
        return 'Pending Review';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'under_review':
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  void _startVerification() {
    context.push('/photo-verification');
  }

  void _retryVerification() {
    context.push('/photo-verification');
  }

  void _contactSupport() async {
    // Open support email
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@pulselink.com',
      query:
          'subject=Verification Support Request&body=Please describe your verification issue:',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          _showError('Could not open email client');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to contact support: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      PulseToast.error(context, message: message);
    }
  }
}

/// Verification request model
class VerificationRequest {
  final String id;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  VerificationRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });
}
