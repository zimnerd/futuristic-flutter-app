import 'package:flutter/material.dart';

import '../../../data/models/safety.dart';

/// Widget for displaying blocked users list
class BlockedUsersWidget extends StatelessWidget {
  final List<BlockedUser> blockedUsers;
  final Function(String userId)? onUnblockUser;

  const BlockedUsersWidget({
    super.key,
    required this.blockedUsers,
    this.onUnblockUser,
  });

  @override
  Widget build(BuildContext context) {
    if (blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No blocked users',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users you block will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: blockedUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final blockedUser = blockedUsers[index];
        return _buildBlockedUserCard(context, blockedUser);
      },
    );
  }

  Widget _buildBlockedUserCard(BuildContext context, BlockedUser blockedUser) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          blockedUser.blockedUserName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (blockedUser.reason != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getReasonColor(blockedUser.reason!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getReasonColor(blockedUser.reason!).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getReasonLabel(blockedUser.reason!),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getReasonColor(blockedUser.reason!),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Blocked ${_formatDate(blockedUser.blockedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showUnblockDialog(context, blockedUser),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.green,
                  tooltip: 'Unblock User',
                ),
                IconButton(
                  onPressed: () => _showDetailsDialog(context, blockedUser),
                  icon: const Icon(Icons.info_outline),
                  color: Colors.blue,
                  tooltip: 'View Details',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason.toLowerCase()) {
      case 'harassment':
        return Colors.red;
      case 'inappropriate':
        return Colors.orange;
      case 'spam':
        return Colors.purple;
      case 'fake':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getReasonLabel(String reason) {
    return reason.toUpperCase();
  }

  void _showUnblockDialog(BuildContext context, BlockedUser blockedUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock this user? They will be able to contact you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onUnblockUser?.call(blockedUser.blockedUserId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, BlockedUser blockedUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Block Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User Name', blockedUser.blockedUserName),
            _buildDetailRow('User ID', blockedUser.blockedUserId),
            if (blockedUser.reason != null)
              _buildDetailRow('Reason', blockedUser.reason!),
            _buildDetailRow('Blocked Date', _formatDate(blockedUser.blockedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
