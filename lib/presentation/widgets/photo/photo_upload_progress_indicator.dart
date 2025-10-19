import 'package:flutter/material.dart';
import '../../../data/models/photo_upload_progress.dart';
import '../../../data/services/photo_upload_service.dart';

/// Widget to display photo upload progress
class PhotoUploadProgressIndicator extends StatelessWidget {
  final String uploadId;
  final bool showDetails;

  const PhotoUploadProgressIndicator({
    super.key,
    required this.uploadId,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final uploadService = PhotoUploadService();

    return StreamBuilder<PhotoUploadProgress>(
      stream: uploadService.watchUploadProgress(uploadId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(progress.status),
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 8),
                  // Status and percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _getStatusIcon(progress.status),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(progress.status),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Text(
                        '${(progress.progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Error message if failed
                  if (progress.status == UploadStatus.failed &&
                      progress.error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      progress.error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.red),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Colors.grey;
      case UploadStatus.uploading:
      case UploadStatus.processing:
        return Colors.blue;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
      case UploadStatus.cancelled:
        return Colors.orange;
    }
  }

  Icon _getStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return const Icon(Icons.schedule, size: 16, color: Colors.grey);
      case UploadStatus.uploading:
      case UploadStatus.processing:
        return const Icon(Icons.cloud_upload, size: 16, color: Colors.blue);
      case UploadStatus.completed:
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case UploadStatus.failed:
        return const Icon(Icons.error, size: 16, color: Colors.red);
      case UploadStatus.cancelled:
        return const Icon(Icons.cancel, size: 16, color: Colors.orange);
    }
  }

  String _getStatusText(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return 'Pending';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.processing:
        return 'Processing';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Widget to display batch upload progress
class BatchUploadProgressIndicator extends StatelessWidget {
  final String batchId;

  const BatchUploadProgressIndicator({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final uploadService = PhotoUploadService();

    return StreamBuilder<BatchUploadProgress>(
      stream: uploadService.watchBatchProgress(batchId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final batchProgress = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uploading Photos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${batchProgress.uploadedPhotos}/${batchProgress.totalPhotos}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Overall progress bar
                LinearProgressIndicator(
                  value: batchProgress.overallProgress,
                  backgroundColor: Colors.grey[200],
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                // Statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(
                      context,
                      '${(batchProgress.overallProgress * 100).toStringAsFixed(0)}%',
                      'Complete',
                    ),
                    _buildStat(
                      context,
                      '${batchProgress.successCount}',
                      'Success',
                      color: Colors.green,
                    ),
                    if (batchProgress.hasErrors)
                      _buildStat(
                        context,
                        '${batchProgress.failedCount}',
                        'Failed',
                        color: Colors.red,
                      ),
                  ],
                ),
                // Individual photo progress
                if (batchProgress.photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...batchProgress.photos.map(
                    (photo) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: PhotoUploadProgressIndicator(
                        uploadId: photo.uploadId,
                        showDetails: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
