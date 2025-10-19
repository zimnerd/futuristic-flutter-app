import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/test_credentials.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../theme/pulse_colors.dart';
import 'common/pulse_toast.dart';

/// Development FAB for auto-login functionality
/// Only shown in debug mode for developer convenience
class DeveloperAutoLoginFAB extends StatefulWidget {
  const DeveloperAutoLoginFAB({super.key});

  @override
  State<DeveloperAutoLoginFAB> createState() => _DeveloperAutoLoginFABState();
}

class _DeveloperAutoLoginFABState extends State<DeveloperAutoLoginFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show in development mode
    if (!kDebugMode || !TestCredentials.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded auto-login options
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: _isExpanded ? _buildExpandedOptions() : const SizedBox(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: PulseColors.primary,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isExpanded ? Icons.close : Icons.developer_mode,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedOptions() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: PulseColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dev Auto-Login',
                style: PulseTextStyles.titleSmall.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quick login with test accounts:',
            style: PulseTextStyles.bodySmall.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Test accounts
          ...TestCredentials.testAccounts.map(
            (account) => _buildAutoLoginOption(account),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLoginOption(TestAccount account) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () => _handleAutoLogin(context, account),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PulseColors.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
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
                            style: PulseTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            account.role,
                            style: PulseTextStyles.bodySmall.copyWith(
                              color: _getRoleColor(account.role),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading) ...[
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
                    ] else ...[
                      Icon(Icons.login, size: 16, color: PulseColors.primary),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleAutoLogin(BuildContext context, TestAccount account) {
    try {
      context.read<AuthBloc>().add(
        AuthAutoLoginRequested(
          email: account.email,
          password: account.password,
        ),
      );

      // Close the expanded panel after login attempt
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _toggleExpanded();
        }
      });
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Auto-login failed: $e');
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return PulseColors.error;
      case 'premium':
        return PulseColors.warning;
      case 'user':
      default:
        return PulseColors.success;
    }
  }
}
