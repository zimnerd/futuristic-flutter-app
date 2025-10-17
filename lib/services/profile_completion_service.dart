import '../data/models/user_model.dart';

/// Service to calculate profile completion percentage
/// Simple, efficient calculation based on filled fields
class ProfileCompletionService {
  /// Calculate profile completion percentage (0-100)
  static int calculateCompletion(UserModel user) {
    int totalFields = 0;
    int filledFields = 0;

    // Essential fields (weight: 1 each)
    final essentialFields = [
      user.firstName,
      user.lastName,
      user.age,
      user.gender,
      user.bio,
    ];

    for (final field in essentialFields) {
      totalFields++;
      if (field != null && field.toString().isNotEmpty) {
        filledFields++;
      }
    }

    // Photos (weight: 2 - more important)
    totalFields += 2;
    if (user.photos.isNotEmpty) {
      if (user.photos.length >= 3) {
        filledFields += 2; // Full points for 3+ photos
      } else {
        filledFields += 1; // Partial points for 1-2 photos
      }
    }

    // Interests (weight: 1)
    totalFields++;
    if (user.interests.isNotEmpty) {
      filledFields++;
    }

    // Optional fields (weight: 0.5 each)
    final optionalFields = [
      user.occupation,
      user.education,
      user.location,
    ];

    for (final field in optionalFields) {
      totalFields++;
      if (field != null && field.toString().isNotEmpty) {
        filledFields++;
      }
    }

    // Calculate percentage
    if (totalFields == 0) return 0;
    return ((filledFields / totalFields) * 100).round();
  }

  /// Get missing fields for completion prompts
  static List<String> getMissingFields(UserModel user) {
    final missing = <String>[];

    if (user.firstName == null || user.firstName!.isEmpty) missing.add('First Name');
    if (user.lastName == null || user.lastName!.isEmpty) missing.add('Last Name');
    if (user.age == null) missing.add('Age');
    if (user.gender == null || user.gender!.isEmpty) missing.add('Gender');
    if (user.bio == null || user.bio!.isEmpty) missing.add('Bio');
    if (user.photos.isEmpty) missing.add('Photos');
    if (user.photos.length < 3) missing.add('More Photos');
    if (user.interests.isEmpty) missing.add('Interests');
    if (user.occupation == null || user.occupation!.isEmpty) missing.add('Occupation');
    if (user.education == null || user.education!.isEmpty) missing.add('Education');
    if (user.location == null || user.location!.isEmpty) missing.add('Location');

    return missing;
  }

  /// Get next recommended field to complete
  static String? getNextRecommendation(UserModel user) {
    // Priority order
    if (user.photos.isEmpty) return 'Add at least one photo';
    if (user.bio == null || user.bio!.isEmpty) return 'Write your bio';
    if (user.photos.length < 3) return 'Add more photos (3+ recommended)';
    if (user.interests.isEmpty) return 'Add your interests';
    if (user.occupation == null || user.occupation!.isEmpty) return 'Add your occupation';
    if (user.education == null || user.education!.isEmpty) return 'Add your education';
    if (user.location == null || user.location!.isEmpty) return 'Add your location';

    return null; // Profile is complete!
  }

  /// Get completion status message
  static String getCompletionMessage(int percentage) {
    if (percentage >= 90) return 'Your profile looks amazing!';
    if (percentage >= 75) return 'Almost there!';
    if (percentage >= 50) return 'Keep going!';
    if (percentage >= 25) return 'Good start!';
    return 'Let\'s complete your profile';
  }

  /// Get completion tier color
  static String getCompletionTier(int percentage) {
    if (percentage >= 90) return 'excellent'; // Green
    if (percentage >= 75) return 'good'; // Light green
    if (percentage >= 50) return 'fair'; // Yellow
    if (percentage >= 25) return 'poor'; // Orange
    return 'incomplete'; // Red
  }
}
