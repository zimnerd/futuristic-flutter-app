import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/test_credentials.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../theme/pulse_colors.dart';

/// Development auto-login panel for easy testing
/// Only shown in debug mode for developer convenience
class AutoLoginPanel extends StatelessWidget {
  const AutoLoginPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show in development mode
    if (!TestCredentials.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: PulseColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Development Auto-Login',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PulseColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quick login with test accounts for development:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PulseColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...TestCredentials.testAccounts.map(
            (account) => _AutoLoginButton(account: account),
          ),
        ],
      ),
    );
  }
}

class _AutoLoginButton extends StatelessWidget {
  final TestAccount account;

  const _AutoLoginButton({required this.account});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : () => _handleAutoLogin(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                side: BorderSide(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(account.avatar, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          account.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: PulseColors.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(account.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.role,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getRoleColor(account.role),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          PulseColors.primary,
                        ),
                      ),
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
  }
}
