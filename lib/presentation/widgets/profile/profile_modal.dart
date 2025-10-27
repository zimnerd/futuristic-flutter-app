import 'package:flutter/material.dart';
import '../../../domain/entities/user_profile.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../common/robust_network_image.dart';
import '../verification/verification_badge.dart';

/// Modal widget for displaying user profile details
class ProfileModal extends StatelessWidget {
  const ProfileModal({
    super.key,
    required this.userProfile,
    this.onMessage,
    this.onClose,
  });

  final UserProfile userProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outlineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userProfile.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: onClose ?? () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                  iconSize: 28,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo carousel
                  if (userProfile.photos.isNotEmpty) ...[
                    SizedBox(
                      height: 400,
                      child: PageView.builder(
                        itemCount: userProfile.photos.length,
                        itemBuilder: (context, index) {
                          final photo = userProfile.photos[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: RobustNetworkImage(
                              imageUrl: photo.url,
                              blurhash: photo.blurhash,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 400,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Basic info
                  Row(
                    children: [
                      Text(
                        '${userProfile.name}, ${userProfile.age}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      VerificationBadge(
                        isVerified: userProfile.isVerified,
                        size: VerificationBadgeSize.medium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  if (userProfile.location.city?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: context.onSurfaceVariantColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          userProfile.location.city!,
                          style: TextStyle(
                            color: context.onSurfaceVariantColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bio
                  if (userProfile.bio.isNotEmpty) ...[
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userProfile.bio,
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Interests
                  if (userProfile.interests.isNotEmpty) ...[
                    Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: userProfile.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: PulseColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: PulseColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            interest.name,
                            style: TextStyle(
                              color: PulseColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Additional info
                  if (userProfile.occupation?.isNotEmpty == true ||
                      userProfile.education?.isNotEmpty == true) ...[
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (userProfile.occupation?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: context.onSurfaceVariantColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userProfile.occupation!,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (userProfile.education?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: context.onSurfaceVariantColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userProfile.education!,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),

          // Action button
          if (onMessage != null) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: context.theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Conversation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required UserProfile userProfile,
    VoidCallback? onMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProfileModal(userProfile: userProfile, onMessage: onMessage),
    );
  }
}
