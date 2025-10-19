import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../../domain/entities/user_profile.dart';
import 'app_router.dart';

/// Navigation helper for profile-related screens
class ProfileNavigation {
  /// Navigate to the profile edit screen
  static Future<void> toProfileEdit(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Navigate to profile details screen
  static void toProfileDetails(
    BuildContext context,
    UserProfile profile, {
    bool isOwnProfile = false,
    VoidCallback? onLike,
    VoidCallback? onMessage,
    VoidCallback? onSuperLike,
  }) {
    // Use GoRouter for consistent navigation behavior
    context.push(
      AppRoutes.profileDetails.replaceFirst(':profileId', profile.id),
      extra: profile,
    );
  }

  /// Navigate to the original profile edit screen (for comparison)
  static Future<void> toOriginalProfileEdit(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Show profile completion bottom sheet
  static Future<void> showProfileCompletionBottomSheet(
    BuildContext context,
    UserProfile? profile,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'A complete profile gets 3x more matches!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        toProfileEdit(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to add profile navigation methods to BuildContext
extension ProfileNavigationExtension on BuildContext {
  /// Navigate to enhanced profile edit screen
  Future<void> toProfileEdit() => ProfileNavigation.toProfileEdit(this);

  /// Navigate to profile details screen
  void toProfileDetails(
    UserProfile profile, {
    bool isOwnProfile = false,
    VoidCallback? onLike,
    VoidCallback? onMessage,
    VoidCallback? onSuperLike,
  }) => ProfileNavigation.toProfileDetails(
    this,
    profile,
    isOwnProfile: isOwnProfile,
    onLike: onLike,
    onMessage: onMessage,
    onSuperLike: onSuperLike,
  );

  /// Show profile completion bottom sheet
  Future<void> showProfileCompletion(UserProfile? profile) =>
      ProfileNavigation.showProfileCompletionBottomSheet(this, profile);
}
