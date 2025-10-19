import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/test_credentials.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../theme/pulse_colors.dart';
import 'common/pulse_toast.dart';

/// Floating auto-login button for quick development access
/// Shows a fab with developer options when in debug mode
class AutoLoginFab extends StatelessWidget {
  const AutoLoginFab({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show in development mode
    if (!TestCredentials.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _showAutoLoginDialog(context),
      backgroundColor: PulseColors.secondary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.developer_mode, size: 20),
      label: const Text('Dev Login'),
      heroTag: 'auto_login_fab',
    );
  }

  void _showAutoLoginDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PulseColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PulseColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.developer_mode,
                        color: PulseColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Development Auto-Login',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: PulseColors.primary,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Select a test account to quickly sign in:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Account list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: TestCredentials.testAccounts.length,
                    itemBuilder: (context, index) {
                      final account = TestCredentials.testAccounts[index];
                      return _AutoLoginCard(account: account);
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AutoLoginCard extends StatelessWidget {
  final TestAccount account;

  const _AutoLoginCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: PulseColors.outline.withValues(alpha: 0.2)),
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return InkWell(
            onTap: isLoading ? null : () => _handleAutoLogin(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getRoleColor(account.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        account.avatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Account info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  account.role,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                account.role,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _getRoleColor(account.role),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PulseColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: PulseColors.primary,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Loading indicator or arrow
                  if (isLoading) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          PulseColors.primary,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'USER':
        return PulseColors.success;
      case 'MODERATOR':
        return PulseColors.warning;
      case 'ADMIN':
        return PulseColors.error;
      case 'SUPER_ADMIN':
        return PulseColors.primary;
      default:
        return PulseColors.onSurface;
    }
  }

  void _handleAutoLogin(BuildContext context) {
    context.read<AuthBloc>().add(
      AuthSignInRequested(email: account.email, password: account.password),
    );

    // Close the dialog
    Navigator.of(context).pop();

    // Show feedback
    PulseToast.success(context, message: 'Signing in as ${account.name}...');
  }
}
