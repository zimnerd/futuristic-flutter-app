import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/match_model.dart';
import '../../../domain/entities/user_profile.dart';

/// Card widget for displaying match information with user details
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.userProfile,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onUnmatch,
    this.onCall,
    this.showStatus = true,
  });

  final MatchModel match;
  final UserProfile? userProfile;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onUnmatch;
  final VoidCallback? onCall;
  final bool showStatus;



  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // User profile photo
                  _buildUserPhoto(),
                  const SizedBox(width: 16),
                  
                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getUserDisplayName(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getUserDetails(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (match.compatibilityScore > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(match.compatibilityScore * 100).round()}% match',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_getUserLocation().isNotEmpty)
                              Expanded(
                                child: Text(
                                  _getUserLocation(),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicator (conditionally shown)
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          match.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        match.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(match.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Action buttons
              if (onAccept != null ||
                  onReject != null ||
                  onUnmatch != null ||
                  onCall != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onCall != null)
                      _ActionButton(
                        onPressed: onCall!,
                        icon: Icons.phone,
                        label: 'Call',
                        color: const Color(0xFF6E3BFF),
                      ),
                    if (onAccept != null)
                      _ActionButton(
                        onPressed: onAccept!,
                        icon: Icons.check,
                        label: 'Accept',
                        color: Colors.green,
                      ),
                    if (onReject != null)
                      _ActionButton(
                        onPressed: onReject!,
                        icon: Icons.close,
                        label: 'Reject',
                        color: Colors.red,
                      ),
                    if (onUnmatch != null)
                      _ActionButton(
                        onPressed: onUnmatch!,
                        icon: Icons.heart_broken,
                        label: 'Unmatch',
                        color: Colors.orange,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build user profile photo widget
  Widget _buildUserPhoto() {
    // For now, use userProfile if available, otherwise show placeholder
    if (userProfile?.photos.isNotEmpty == true) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: userProfile!.photos.first.url,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 30),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Default placeholder
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
    );
  }

  /// Get user display name from userProfile or fallback
  String _getUserDisplayName() {
    print('🏷️ Getting display name - userProfile: ${userProfile?.name}, match.otherUserId: ${match.otherUserId}');
    
    if (userProfile != null && userProfile!.name.isNotEmpty) {
      return userProfile!.name;
    }
    
    // Try to extract name from match.otherUserId or user IDs
    if (match.otherUserId != null) {
      return 'User ${match.otherUserId!.substring(0, 8)}...';
    }
    
    // Final fallback
    return 'New Match';
  }

  /// Get user details (age, bio snippet, etc.)
  String _getUserDetails() {
    if (userProfile != null) {
      List<String> details = [];

      if (userProfile!.age > 0) {
        details.add('${userProfile!.age} years old');
      }

      if (userProfile!.bio.isNotEmpty) {
        String bio = userProfile!.bio;
        if (bio.length > 50) {
          bio = '${bio.substring(0, 50)}...';
        }
        details.add(bio);
      }

      // Add occupation if available
      if (userProfile!.occupation?.isNotEmpty == true) {
        details.add(userProfile!.occupation!);
      }

      return details.isNotEmpty ? details.join(' • ') : 'Tap to view profile';
    }

    // Better fallback with match timing
    final matchTime = match.matchedAt ?? match.createdAt;
    final now = DateTime.now();
    final diff = now.difference(matchTime);
    
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inHours < 1) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = '${diff.inDays}d ago';
    }
    
    return 'Matched $timeAgo • ${_getStatusText(match.status)}';
  }

  /// Get user location
  String _getUserLocation() {
    if (userProfile?.location != null) {
      return userProfile!.location.displayName;
    }
    return '';
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'matched':
        return 'Active Match';
      case 'pending':
        return 'Waiting for Response';
      case 'rejected':
        return 'Declined';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'matched':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
    );
  }
}
