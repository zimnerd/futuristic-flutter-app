import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing profile creation draft state
class ProfileDraftService {
  static const String _boxName = 'profile_draft';
  static const String _draftKey = 'current_draft';

  late final Box<Map<dynamic, dynamic>> _box;

  /// Initialize the service
  Future<void> init() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  /// Save current profile creation progress
  Future<void> saveDraft(ProfileDraft draft) async {
    await _box.put(_draftKey, draft.toMap());
  }

  /// Load saved draft if exists
  ProfileDraft? loadDraft() {
    final draftMap = _box.get(_draftKey);
    if (draftMap == null) return null;

    try {
      return ProfileDraft.fromMap(Map<String, dynamic>.from(draftMap));
    } catch (e) {
      // If there's an error parsing, clear the invalid draft
      clearDraft();
      return null;
    }
  }

  /// Clear the current draft
  Future<void> clearDraft() async {
    await _box.delete(_draftKey);
  }

  /// Check if a draft exists
  bool hasDraft() {
    return _box.containsKey(_draftKey);
  }

  /// Close the service
  Future<void> close() async {
    await _box.close();
  }
}

/// Data class representing a profile creation draft
class ProfileDraft {
  final String? name;
  final int? age;
  final String? bio;
  final List<String> photos;
  final List<String> interests;
  final String? gender;
  final String? lookingFor;
  final int currentStep;
  final DateTime savedAt;

  const ProfileDraft({
    this.name,
    this.age,
    this.bio,
    this.photos = const [],
    this.interests = const [],
    this.gender,
    this.lookingFor,
    required this.currentStep,
    required this.savedAt,
  });

  /// Create a copy with updated fields
  ProfileDraft copyWith({
    String? name,
    int? age,
    String? bio,
    List<String>? photos,
    List<String>? interests,
    String? gender,
    String? lookingFor,
    int? currentStep,
    DateTime? savedAt,
  }) {
    return ProfileDraft(
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      currentStep: currentStep ?? this.currentStep,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'bio': bio,
      'photos': photos,
      'interests': interests,
      'gender': gender,
      'lookingFor': lookingFor,
      'currentStep': currentStep,
      'savedAt': savedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from map
  factory ProfileDraft.fromMap(Map<String, dynamic> map) {
    return ProfileDraft(
      name: map['name'],
      age: map['age'],
      bio: map['bio'],
      photos: List<String>.from(map['photos'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      gender: map['gender'],
      lookingFor: map['lookingFor'],
      currentStep: map['currentStep'] ?? 0,
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] ?? 0),
    );
  }

  /// Calculate completion percentage
  double get completionPercentage {
    int completedFields = 0;
    const int totalFields =
        7; // name, age, bio, photos, interests, gender, lookingFor

    if (name?.isNotEmpty == true) completedFields++;
    if (age != null && age! > 0) completedFields++;
    if (bio?.isNotEmpty == true) completedFields++;
    if (photos.isNotEmpty) completedFields++;
    if (interests.isNotEmpty) completedFields++;
    if (gender?.isNotEmpty == true) completedFields++;
    if (lookingFor?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }

  /// Check if draft is empty (no meaningful data)
  bool get isEmpty {
    return name?.isEmpty != false &&
        age == null &&
        bio?.isEmpty != false &&
        photos.isEmpty &&
        interests.isEmpty &&
        gender?.isEmpty != false &&
        lookingFor?.isEmpty != false;
  }

  /// Get formatted time since last save
  String get timeSinceLastSave {
    final now = DateTime.now();
    final difference = now.difference(savedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
