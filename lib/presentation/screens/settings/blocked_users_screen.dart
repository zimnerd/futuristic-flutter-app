import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/pulse_colors.dart' hide PulseTextStyles;
import '../../theme/pulse_theme.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../blocs/block_report/block_report_bloc.dart';

/// Screen displaying list of blocked users for safety
class SafetyBlockedUsersScreen extends StatefulWidget {
  const SafetyBlockedUsersScreen({super.key});

  @override
  State<SafetyBlockedUsersScreen> createState() => _SafetyBlockedUsersScreenState();
}

class _SafetyBlockedUsersScreenState extends State<SafetyBlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    // Load blocked users when screen opens
    context.read<BlockReportBloc>().add(LoadBlockedUsers());
  }

  Future<void> _handleUnblock(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Unblock User',
          style: PulseTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to unblock $userName? They will be able to see your profile and contact you again.',
          style: PulseTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: PulseTextStyles.labelLarge.copyWith(
                color: PulseColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Unblock',
              style: PulseTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<BlockReportBloc>().add(UnblockUser(blockedUserId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked Users',
          style: PulseTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: PulseColors.surface,
      ),
      body: BlocListener<BlockReportBloc, BlockReportState>(
        listener: (context, state) {
          if (state is UserUnblocked) {
            PulseToast.success(context, message: 'User unblocked successfully',
            );
            // Reload the list
            context.read<BlockReportBloc>().add(LoadBlockedUsers());
          } else if (state is BlockReportError) {
            PulseToast.error(context, message: state.message,
            );
          }
        },
        child: BlocBuilder<BlockReportBloc, BlockReportState>(
          builder: (context, state) {
            if (state is BlockReportLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: PulseColors.primary,
                ),
              );
            }

            if (state is BlockedUsersLoaded) {
              if (state.blockedUserIds.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<BlockReportBloc>().add(LoadBlockedUsers());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.blockedUserIds.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final userId = state.blockedUserIds[index];
                    return _buildBlockedUserCard(userId);
                  },
                ),
              );
            }

            if (state is BlockReportError) {
              return _buildErrorState(state.message);
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildBlockedUserCard(String userId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PulseColors.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // User avatar placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 32,
              color: PulseColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocked User',
                  style: PulseTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'User ID: ${userId.substring(0, 8)}...',
                  style: PulseTextStyles.bodySmall.copyWith(
                    color: PulseColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Unblock button
          OutlinedButton.icon(
            onPressed: () => _handleUnblock(userId, 'Blocked User'),
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Unblock'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PulseColors.error,
              side: BorderSide(color: PulseColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: PulseColors.surfaceVariant.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: PulseColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Blocked Users',
              style: PulseTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t blocked anyone yet.\nBlocked users will appear here.',
              textAlign: TextAlign.center,
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: PulseColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Blocked Users',
              style: PulseTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<BlockReportBloc>().add(LoadBlockedUsers());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
