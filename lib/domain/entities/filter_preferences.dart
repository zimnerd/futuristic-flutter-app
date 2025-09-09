/// Filter preferences for matching algorithm
/// Defines user preferences for potential matches
class FilterPreferences {
  final int minAge;
  final int maxAge;
  final double maxDistance; // in kilometers
  final List<String> interests;
  final String? education;
  final String? occupation;
  final bool showOnlyVerified;
  final bool showOnlyWithPhotos;
  final List<String> dealBreakers;

  const FilterPreferences({
    this.minAge = 18,
    this.maxAge = 99,
    this.maxDistance = 50.0,
    this.interests = const [],
    this.education,
    this.occupation,
    this.showOnlyVerified = false,
    this.showOnlyWithPhotos = true,
    this.dealBreakers = const [],
  });

  /// Create FilterPreferences from JSON
  factory FilterPreferences.fromJson(Map<String, dynamic> json) {
    return FilterPreferences(
      minAge: json['minAge'] as int? ?? 18,
      maxAge: json['maxAge'] as int? ?? 99,
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 50.0,
      interests: List<String>.from(json['interests'] as List? ?? []),
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      showOnlyVerified: json['showOnlyVerified'] as bool? ?? false,
      showOnlyWithPhotos: json['showOnlyWithPhotos'] as bool? ?? true,
      dealBreakers: List<String>.from(json['dealBreakers'] as List? ?? []),
    );
  }

  /// Convert FilterPreferences to JSON
  Map<String, dynamic> toJson() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistance': maxDistance,
      'interests': interests,
      'education': education,
      'occupation': occupation,
      'showOnlyVerified': showOnlyVerified,
      'showOnlyWithPhotos': showOnlyWithPhotos,
      'dealBreakers': dealBreakers,
    };
  }

  /// Create a copy with updated values
  FilterPreferences copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
    String? education,
    String? occupation,
    bool? showOnlyVerified,
    bool? showOnlyWithPhotos,
    List<String>? dealBreakers,
  }) {
    return FilterPreferences(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      interests: interests ?? this.interests,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      showOnlyVerified: showOnlyVerified ?? this.showOnlyVerified,
      showOnlyWithPhotos: showOnlyWithPhotos ?? this.showOnlyWithPhotos,
      dealBreakers: dealBreakers ?? this.dealBreakers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilterPreferences &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.maxDistance == maxDistance &&
        other.interests.length == interests.length &&
        other.education == education &&
        other.occupation == occupation &&
        other.showOnlyVerified == showOnlyVerified &&
        other.showOnlyWithPhotos == showOnlyWithPhotos &&
        other.dealBreakers.length == dealBreakers.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      minAge,
      maxAge,
      maxDistance,
      interests.length,
      education,
      occupation,
      showOnlyVerified,
      showOnlyWithPhotos,
      dealBreakers.length,
    );
  }

  @override
  String toString() {
    return 'FilterPreferences(minAge: $minAge, maxAge: $maxAge, maxDistance: $maxDistance, interests: $interests, education: $education, occupation: $occupation, showOnlyVerified: $showOnlyVerified, showOnlyWithPhotos: $showOnlyWithPhotos, dealBreakers: $dealBreakers)';
  }
}
