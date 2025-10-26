import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

class UploadProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 100.0
  final String? fileName;
  final String? fileSize;
  final bool isUploading;
  final VoidCallback? onCancel;
  final String? errorMessage;

  const UploadProgressIndicator({
    super.key,
    required this.progress,
    this.fileName,
    this.fileSize,
    this.isUploading = true,
    this.onCancel,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasError
            ? context.errorColor.withValues(alpha: 0.1)
            : PulseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? context.errorColor.withValues(alpha: 0.3)
              : PulseColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with file info and cancel button
          Row(
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.upload_outlined,
                color: hasError ? context.errorColor : PulseColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fileName != null)
                      Text(
                        fileName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: hasError ? context.errorColor : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (fileSize != null)
                      Text(
                        fileSize!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasError
                              ? context.errorColor
                              : context.outlineColor.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onCancel != null && isUploading)
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: context.outlineColor.shade600,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar or error message
          if (hasError) ...[
            Text(
              errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.errorColor.shade600),
            ),
          ] else ...[
            // Progress bar
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: context.outlineColor.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            PulseColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: PulseColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUploading ? 'Uploading...' : 'Upload complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUploading
                            ? context.outlineColor.shade600
                            : Colors.green.shade600,
                      ),
                    ),
                    if (isUploading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            PulseColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact upload progress indicator for message bubbles
class CompactUploadProgress extends StatelessWidget {
  final double progress;
  final bool isUploading;
  final VoidCallback? onCancel;

  const CompactUploadProgress({
    super.key,
    required this.progress,
    this.isUploading = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: 2,
              backgroundColor: context.surfaceColor.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onCancel,
              child: Icon(Icons.close, color: context.onSurfaceColor, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
