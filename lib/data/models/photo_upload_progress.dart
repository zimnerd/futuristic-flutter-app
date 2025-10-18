/// Photo upload progress tracking model
class PhotoUploadProgress {
  final String uploadId;
  final String? photoPath;
  final double progress; // 0.0 to 1.0
  final UploadStatus status;
  final String? url; // Final URL after upload
  final String? error;
  final DateTime timestamp;

  PhotoUploadProgress({
    required this.uploadId,
    this.photoPath,
    required this.progress,
    required this.status,
    this.url,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  PhotoUploadProgress copyWith({
    String? uploadId,
    String? photoPath,
    double? progress,
    UploadStatus? status,
    String? url,
    String? error,
    DateTime? timestamp,
  }) {
    return PhotoUploadProgress(
      uploadId: uploadId ?? this.uploadId,
      photoPath: photoPath ?? this.photoPath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      url: url ?? this.url,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'photoPath': photoPath,
      'progress': progress,
      'status': status.name,
      'url': url,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PhotoUploadProgress.fromJson(Map<String, dynamic> json) {
    return PhotoUploadProgress(
      uploadId: json['uploadId'] as String,
      photoPath: json['photoPath'] as String?,
      progress: (json['progress'] as num).toDouble(),
      status: UploadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UploadStatus.pending,
      ),
      url: json['url'] as String?,
      error: json['error'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PhotoUploadProgress(uploadId: $uploadId, progress: ${(progress * 100).toStringAsFixed(1)}%, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhotoUploadProgress &&
        other.uploadId == uploadId &&
        other.photoPath == photoPath &&
        other.progress == progress &&
        other.status == status &&
        other.url == url &&
        other.error == error;
  }

  @override
  int get hashCode {
    return uploadId.hashCode ^
        photoPath.hashCode ^
        progress.hashCode ^
        status.hashCode ^
        url.hashCode ^
        error.hashCode;
  }
}

/// Upload status enumeration
enum UploadStatus {
  pending,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

/// Batch upload progress tracking
class BatchUploadProgress {
  final String batchId;
  final int totalPhotos;
  final int uploadedPhotos;
  final List<PhotoUploadProgress> photos;
  final double overallProgress; // 0.0 to 1.0

  const BatchUploadProgress({
    required this.batchId,
    required this.totalPhotos,
    required this.uploadedPhotos,
    required this.photos,
    required this.overallProgress,
  });

  BatchUploadProgress copyWith({
    String? batchId,
    int? totalPhotos,
    int? uploadedPhotos,
    List<PhotoUploadProgress>? photos,
    double? overallProgress,
  }) {
    return BatchUploadProgress(
      batchId: batchId ?? this.batchId,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      uploadedPhotos: uploadedPhotos ?? this.uploadedPhotos,
      photos: photos ?? this.photos,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }

  bool get isComplete => uploadedPhotos == totalPhotos;
  bool get hasErrors => photos.any((p) => p.status == UploadStatus.failed);
  int get failedCount =>
      photos.where((p) => p.status == UploadStatus.failed).length;
  int get successCount =>
      photos.where((p) => p.status == UploadStatus.completed).length;

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'totalPhotos': totalPhotos,
      'uploadedPhotos': uploadedPhotos,
      'photos': photos.map((p) => p.toJson()).toList(),
      'overallProgress': overallProgress,
    };
  }

  factory BatchUploadProgress.fromJson(Map<String, dynamic> json) {
    return BatchUploadProgress(
      batchId: json['batchId'] as String,
      totalPhotos: json['totalPhotos'] as int,
      uploadedPhotos: json['uploadedPhotos'] as int,
      photos: (json['photos'] as List)
          .map((p) => PhotoUploadProgress.fromJson(p as Map<String, dynamic>))
          .toList(),
      overallProgress: (json['overallProgress'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BatchUploadProgress(uploaded: $uploadedPhotos/$totalPhotos, progress: ${(overallProgress * 100).toStringAsFixed(1)}%)';
  }
}
