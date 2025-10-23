/// Verification status model - represents user's email/phone verification state
class VerificationStatus {
  final bool emailVerified;
  final DateTime? emailVerifiedAt;
  final bool phoneVerified;
  final DateTime? phoneVerifiedAt;
  final bool hasVerified;
  final bool canAccessMatching;

  const VerificationStatus({
    required this.emailVerified,
    this.emailVerifiedAt,
    required this.phoneVerified,
    this.phoneVerifiedAt,
    required this.hasVerified,
    required this.canAccessMatching,
  });

  /// Create from JSON response (supports both old and new API formats)
  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    // Handle new nested format: { email: { verified, verifiedAt }, phone: { verified, verifiedAt } }
    final emailData = json['email'] as Map<String, dynamic>? ?? {};
    final phoneData = json['phone'] as Map<String, dynamic>? ?? {};

    final emailVerified =
        emailData['verified'] as bool? ??
        json['emailVerified'] as bool? ??
        false;
    final emailVerifiedAt = emailData['verifiedAt'] != null
        ? DateTime.parse(emailData['verifiedAt'] as String)
        : (json['emailVerifiedAt'] != null
              ? DateTime.parse(json['emailVerifiedAt'] as String)
              : null);

    final phoneVerified =
        phoneData['verified'] as bool? ??
        json['phoneVerified'] as bool? ??
        false;
    final phoneVerifiedAt = phoneData['verifiedAt'] != null
        ? DateTime.parse(phoneData['verifiedAt'] as String)
        : (json['phoneVerifiedAt'] != null
              ? DateTime.parse(json['phoneVerifiedAt'] as String)
              : null);

    return VerificationStatus(
      emailVerified: emailVerified,
      emailVerifiedAt: emailVerifiedAt,
      phoneVerified: phoneVerified,
      phoneVerifiedAt: phoneVerifiedAt,
      hasVerified:
          json['verified'] as bool? ?? (emailVerified || phoneVerified),
      canAccessMatching:
          json['canAccessMatching'] as bool? ??
          (emailVerified || phoneVerified),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'emailVerified': emailVerified,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'phoneVerified': phoneVerified,
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'hasVerified': hasVerified,
      'canAccessMatching': canAccessMatching,
    };
  }

  /// Copy with method for state updates
  VerificationStatus copyWith({
    bool? emailVerified,
    DateTime? emailVerifiedAt,
    bool? phoneVerified,
    DateTime? phoneVerifiedAt,
    bool? hasVerified,
    bool? canAccessMatching,
  }) {
    return VerificationStatus(
      emailVerified: emailVerified ?? this.emailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      hasVerified: hasVerified ?? this.hasVerified,
      canAccessMatching: canAccessMatching ?? this.canAccessMatching,
    );
  }

  /// Check if user needs to verify before accessing features
  bool get needsVerification => !hasVerified;

  /// Get verification methods that are pending
  List<String> get pendingVerifications {
    final pending = <String>[];
    if (!emailVerified) pending.add('Email');
    if (!phoneVerified) pending.add('Phone');
    return pending;
  }

  /// Get verification methods that are completed
  List<String> get completedVerifications {
    final completed = <String>[];
    if (emailVerified) completed.add('Email');
    if (phoneVerified) completed.add('Phone');
    return completed;
  }

  @override
  String toString() {
    return 'VerificationStatus(emailVerified: $emailVerified, phoneVerified: $phoneVerified, hasVerified: $hasVerified, canAccessMatching: $canAccessMatching)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerificationStatus &&
        other.emailVerified == emailVerified &&
        other.emailVerifiedAt == emailVerifiedAt &&
        other.phoneVerified == phoneVerified &&
        other.phoneVerifiedAt == phoneVerifiedAt &&
        other.hasVerified == hasVerified &&
        other.canAccessMatching == canAccessMatching;
  }

  @override
  int get hashCode {
    return Object.hash(
      emailVerified,
      emailVerifiedAt,
      phoneVerified,
      phoneVerifiedAt,
      hasVerified,
      canAccessMatching,
    );
  }
}
