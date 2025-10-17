import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';

/// Document verification screen for ID/Passport/Driver's License
/// Steps: 1) Select document type, 2) Capture front, 3) Capture back, 4) Review, 5) Submit
class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  int _currentStep = 0;
  String? _selectedDocumentType;
  File? _frontPhoto;
  File? _backPhoto;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  final Map<String, Map<String, dynamic>> _documentTypes = {
    'passport': {
      'label': 'Passport',
      'icon': Icons.book,
      'description': 'International passport',
      'requiresBack': false,
    },
    'driver_license': {
      'label': 'Driver\'s License',
      'icon': Icons.credit_card,
      'description': 'Valid driver\'s license',
      'requiresBack': true,
    },
    'national_id': {
      'label': 'National ID',
      'icon': Icons.badge,
      'description': 'Government-issued ID',
      'requiresBack': true,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ID Verification',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStepContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int totalSteps = _selectedDocumentType != null &&
            _documentTypes[_selectedDocumentType]!['requiresBack'] == false
        ? 3
        : 4;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(
          totalSteps,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDocumentTypeSelection();
      case 1:
        return _buildCaptureStep(isFront: true);
      case 2:
        if (_selectedDocumentType != null &&
            _documentTypes[_selectedDocumentType]!['requiresBack']) {
          return _buildCaptureStep(isFront: false);
        }
        return _buildReviewStep();
      case 3:
        return _buildReviewStep();
      case 4:
        return _buildSubmissionStep();
      default:
        return _buildDocumentTypeSelection();
    }
  }

  // Step 1: Document Type Selection
  Widget _buildDocumentTypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.assignment_ind,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose your document',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a government-issued ID to verify your identity',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ..._documentTypes.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;
            return _buildDocumentOption(
              type: key,
              label: value['label']!,
              icon: value['icon']!,
              description: value['description']!,
            );
          }),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your information is encrypted and secure. We never share your documents.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentOption({
    required String type,
    required String label,
    required IconData icon,
    required String description,
  }) {
    final isSelected = _selectedDocumentType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDocumentType = type;
          _currentStep = 1;
          _frontPhoto = null;
          _backPhoto = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Step 2/3: Capture Document Photo
  Widget _buildCaptureStep({required bool isFront}) {
    final existingPhoto = isFront ? _frontPhoto : _backPhoto;
    final side = isFront ? 'front' : 'back';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.camera_alt,
            size: 100,
            color: existingPhoto != null
                ? AppColors.success
                : AppColors.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Capture $side of document',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Make sure all details are clearly visible',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildGuidelines(),
          const Spacer(),
          if (existingPhoto != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                existingPhoto,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _captureDocument(isFront: isFront),
              icon: Icon(existingPhoto != null ? Icons.refresh : Icons.camera_alt),
              label: Text(
                existingPhoto != null ? 'Retake Photo' : 'Take Photo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _pickDocumentFromGallery(isFront: isFront),
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (existingPhoto != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _proceedToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips for a clear photo:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildGuideline(Icons.lightbulb, 'Use good lighting'),
          _buildGuideline(Icons.crop, 'All corners visible'),
          _buildGuideline(Icons.text_fields, 'Text is readable'),
          _buildGuideline(Icons.blur_off, 'Avoid glare and blur'),
        ],
      ),
    );
  }

  Widget _buildGuideline(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Review Photos
  Widget _buildReviewStep() {
    final requiresBack = _selectedDocumentType != null &&
        _documentTypes[_selectedDocumentType]!['requiresBack'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Review your documents',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Make sure all details are clearly visible',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          if (_frontPhoto != null) ...[
            _buildPhotoPreview(
              title: 'Front of Document',
              photo: _frontPhoto!,
              onRetake: () {
                setState(() {
                  _currentStep = 1;
                });
              },
            ),
            if (requiresBack && _backPhoto != null) ...[
              const SizedBox(height: 24),
              _buildPhotoPreview(
                title: 'Back of Document',
                photo: _backPhoto!,
                onRetake: () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
              ),
            ],
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 4;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Looks Good - Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview({
    required String title,
    required File photo,
    required VoidCallback onRetake,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            photo,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step 5: Submission
  Widget _buildSubmissionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isSubmitting) ...[
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            const Text(
              'Uploading your documents...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This may take a few moments',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.cloud_upload,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            const Text(
              'Ready to submit',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We\'ll review your documents within 24-48 hours',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Submit for Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _captureDocument({required bool isFront}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          if (isFront) {
            _frontPhoto = File(photo.path);
          } else {
            _backPhoto = File(photo.path);
          }
        });
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  Future<void> _pickDocumentFromGallery({required bool isFront}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          if (isFront) {
            _frontPhoto = File(photo.path);
          } else {
            _backPhoto = File(photo.path);
          }
        });
      }
    } catch (e) {
      _showError('Failed to pick photo: $e');
    }
  }

  void _proceedToNextStep() {
    final requiresBack = _selectedDocumentType != null &&
        _documentTypes[_selectedDocumentType]!['requiresBack'];

    setState(() {
      if (_currentStep == 1 && requiresBack) {
        // Move to back photo capture
        _currentStep = 2;
      } else {
        // Move to review
        _currentStep = requiresBack ? 3 : 2;
      }
    });
  }

  Future<void> _submitVerification() async {
    if (_frontPhoto == null) {
      _showError('Please capture document photo');
      return;
    }

    final requiresBack = _selectedDocumentType != null &&
        _documentTypes[_selectedDocumentType]!['requiresBack'];

    if (requiresBack && _backPhoto == null) {
      _showError('Please capture both sides of the document');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Upload photos and call verification API
      // For now, simulate API call
      await Future.delayed(const Duration(seconds: 3));

      // final repository = context.read<UsersRepository>();
      // await repository.requestVerification({
      //   'type': 'id',
      //   'documentType': _selectedDocumentType,
      //   'frontPhotoUrl': frontUploadedUrl,
      //   'backPhotoUrl': backUploadedUrl,
      // });

      if (mounted) {
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showError('Submission failed: $e');
      }
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Documents Submitted!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'We\'ll review your documents within 24-48 hours and notify you when verified.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close verification screen
            },
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
