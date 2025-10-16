/// Photo model representing a user's uploaded photo with progressive loading support
class Photo {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? blurhash;
  final int? width;
  final int? height;
  final bool isMain;
  final int displayOrder;
  final DateTime? createdAt;

  const Photo({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.blurhash,
    this.width,
    this.height,
    this.isMain = false,
    this.displayOrder = 0,
    this.createdAt,
  });

  /// Get appropriate URL based on desired size
  /// Falls back to full URL if specific size not available
  String getUrl({bool useThumbnail = false}) {
    if (useThumbnail && thumbnailUrl != null) {
      return thumbnailUrl!;
    }
    return url;
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? json['processedUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      blurhash: json['blurhash']?.toString(),
      width: json['width'] as int? ?? json['dimensions']?['width'] as int?,
      height: json['height'] as int? ?? json['dimensions']?['height'] as int?,
      isMain: json['isMain'] == true,
      displayOrder: json['displayOrder'] as int? ?? json['order'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Create Photo from simple string URL (backward compatibility)
  factory Photo.fromUrl(String url) {
    return Photo(
      id: url.hashCode.toString(),
      url: url,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (blurhash != null) 'blurhash': blurhash,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'isMain': isMain,
      'displayOrder': displayOrder,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Photo(id: $id, url: $url, blurhash: ${blurhash != null ? "present" : "null"})';
  }
}
