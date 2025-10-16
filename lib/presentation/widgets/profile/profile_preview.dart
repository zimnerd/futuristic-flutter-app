import 'package:flutter/material.dart';
import 'dart:io';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';
import '../common/robust_network_image.dart';

/// Widget that shows how the profile will appear to other users
class ProfilePreview extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onClose;

  const ProfilePreview({
    super.key,
    required this.profile,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          PageView.builder(
            itemCount: profile.photos.length,
            itemBuilder: (context, index) {
              return _buildPhotoPage(context, profile.photos[index]);
            },
          ),

          // Profile info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name and age
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${profile.name}, ${profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (profile.verified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: PulseColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Distance and online status
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '2 km away', // This would be calculated
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (profile.isOnline) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: PulseColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Online now',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  if (profile.bio.isNotEmpty) ...[
                    Text(
                      profile.bio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Job and education
                  if (profile.job?.isNotEmpty == true ||
                      profile.school?.isNotEmpty == true) ...[
                    _buildInfoChips(),
                    const SizedBox(height: 16),
                  ],

                  // Interests
                  if (profile.interests.isNotEmpty) ...[
                    Text(
                      'Interests',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInterestChips(),
                  ],
                ],
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Profile Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Photo indicators
          if (profile.photos.length > 1)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Row(
                children: profile.photos.asMap().entries.map((entry) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                        right: entry.key < profile.photos.length - 1 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPage(BuildContext context, ProfilePhoto photo) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: photo.url.startsWith('/') || photo.url.startsWith('file://')
          ? Image.file(
              File(photo.url),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder();
              },
            )
          : RobustNetworkImage(
              imageUrl: photo.url,
              blurhash: photo.blurhash,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load photo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (profile.job?.isNotEmpty == true)
          _buildInfoChip(Icons.work, profile.job!),
        if (profile.company?.isNotEmpty == true)
          _buildInfoChip(Icons.business, profile.company!),
        if (profile.school?.isNotEmpty == true)
          _buildInfoChip(Icons.school, profile.school!),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profile.interests.take(6).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PulseColors.primary.withValues(alpha: 0.8),
                PulseColors.secondary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            interest,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
