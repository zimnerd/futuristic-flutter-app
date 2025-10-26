import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulse_dating_app/core/utils/logger.dart';
import 'package:pulse_dating_app/presentation/theme/pulse_colors.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget for uploading multiple photos with preview and validation
class PhotoUploadWidget extends StatefulWidget {
  const PhotoUploadWidget({
    super.key,
    required this.onPhotosSelected,
    this.maxPhotos = 6,
    this.currentPhotoCount = 0,
    this.allowMultiple = true,
  });

  final Function(List<File> photos) onPhotosSelected;
  final int maxPhotos;
  final int currentPhotoCount;
  final bool allowMultiple;

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedPhotos = [];
  bool _isProcessing = false;

  // Validation constants
  static const int _maxFileSizeMB = 10;
  static const int _maxFileSizeBytes = _maxFileSizeMB * 1024 * 1024;
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'heic'];

  int get _remainingSlots => widget.maxPhotos - widget.currentPhotoCount;
  int get _availableSlots => _remainingSlots - _selectedPhotos.length > 0
      ? _remainingSlots - _selectedPhotos.length
      : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Photos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select up to ${widget.maxPhotos} photos. You have $_remainingSlots slots available.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceVariantColor,
                ),
              ),
            ],
          ),
        ),

        // Photo preview grid
        if (_selectedPhotos.isNotEmpty) ...[
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return _buildPhotoPreview(_selectedPhotos[index], index);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Camera button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _availableSlots > 0 && !_isProcessing
                      ? () => _pickPhoto(ImageSource.camera)
                      : null,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Gallery button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _availableSlots > 0 && !_isProcessing
                      ? () => _pickPhoto(ImageSource.gallery)
                      : null,
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Upload button
        if (_selectedPhotos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _uploadPhotos,
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Upload ${_selectedPhotos.length} ${_selectedPhotos.length == 1 ? 'Photo' : 'Photos'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

        // Guidelines
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo Guidelines:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildGuideline('Clear face photos work best'),
              _buildGuideline('Maximum file size: $_maxFileSizeMB MB'),
              _buildGuideline(
                'Formats: ${_allowedExtensions.join(', ').toUpperCase()}',
              ),
              _buildGuideline('First photo becomes your main photo'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(File photo, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Photo preview
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              photo,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),

          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),

          // Main photo indicator (first photo)
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PulseColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'MAIN',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: context.onSurfaceVariantColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);

      if (widget.allowMultiple && source == ImageSource.gallery) {
        // Multiple photo selection from gallery
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
        );

        if (images.isEmpty) {
          setState(() => _isProcessing = false);
          return;
        }

        // Validate and add photos
        final List<File> validPhotos = [];
        for (final image in images) {
          if (_selectedPhotos.length + validPhotos.length >= _availableSlots) {
            _showError('Maximum ${widget.maxPhotos} photos allowed');
            break;
          }

          final file = File(image.path);
          final validation = await _validatePhoto(file);

          if (validation.isValid) {
            validPhotos.add(file);
          } else {
            _showError(validation.error!);
          }
        }

        if (validPhotos.isNotEmpty) {
          setState(() {
            _selectedPhotos.addAll(validPhotos);
          });
        }
      } else {
        // Single photo selection (camera or single from gallery)
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );

        if (image == null) {
          setState(() => _isProcessing = false);
          return;
        }

        final file = File(image.path);
        final validation = await _validatePhoto(file);

        if (validation.isValid) {
          setState(() {
            _selectedPhotos.add(file);
          });
        } else {
          _showError(validation.error!);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pick photo: $e');
      _showError('Failed to select photo. Please try again.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<PhotoValidation> _validatePhoto(File photo) async {
    try {
      // Check if file exists
      if (!await photo.exists()) {
        return PhotoValidation(isValid: false, error: 'Photo file not found');
      }

      // Check file size
      final fileSize = await photo.length();
      if (fileSize > _maxFileSizeBytes) {
        return PhotoValidation(
          isValid: false,
          error: 'Photo size exceeds $_maxFileSizeMB MB limit',
        );
      }

      // Check file extension
      final extension = photo.path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(extension)) {
        return PhotoValidation(
          isValid: false,
          error:
              'Invalid format. Use: ${_allowedExtensions.join(', ').toUpperCase()}',
        );
      }

      return PhotoValidation(isValid: true);
    } catch (e) {
      AppLogger.error('Photo validation error: $e');
      return PhotoValidation(isValid: false, error: 'Failed to validate photo');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _uploadPhotos() {
    if (_selectedPhotos.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    // Call the callback with selected photos
    widget.onPhotosSelected(_selectedPhotos);

    // Clear selection after upload initiated
    setState(() {
      _selectedPhotos.clear();
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    PulseToast.error(context, message: message);
  }
}

/// Photo validation result
class PhotoValidation {
  const PhotoValidation({required this.isValid, this.error});

  final bool isValid;
  final String? error;
}
