import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Screen for selecting verification method (Email or WhatsApp)
/// Shown after first login if user hasn't verified via either method
/// User is already AUTHENTICATED with valid JWT token
/// Backend will retrieve email/phone from JWT automatically
class VerificationMethodScreen extends StatefulWidget {
  const VerificationMethodScreen({super.key});

  @override
  State<VerificationMethodScreen> createState() => _VerificationMethodScreenState();
}

class _VerificationMethodScreenState extends State<VerificationMethodScreen> {
  final Logger _logger = Logger();
  String? _selectedMethod;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPSent) {
            _logger.i('✅ OTP sent successfully via ${state.deliveryMethods}');
            // Navigate to OTP verification screen
            context.push(
              '/otp-verify',
              extra: {
                'sessionId': state.sessionId,
                'phoneNumber': '',
                'deliveryMethods': state.deliveryMethods,
              },
            );
          } else if (state is AuthError) {
            _logger.e('❌ Verification error: ${state.message}');
            PulseToast.error(
              context,
              message: state.message,
            );
            setState(() => _isLoading = false);
          } else if (state is AuthLoading) {
            setState(() => _isLoading = true);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SizedBox(height: MediaQuery.of(context).padding.top + 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Verify Your Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Choose how you\'d like to verify your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // Email verification option
                _buildVerificationOption(
                  context,
                  method: 'email',
                  title: 'Email Verification',
                  description: 'Verify using your email address',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // WhatsApp verification option
                _buildVerificationOption(
                  context,
                  method: 'whatsapp',
                  title: 'WhatsApp Verification',
                  description: 'Verify using WhatsApp OTP',
                  icon: Icons.chat_outlined,
                ),
                const SizedBox(height: 40),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PulseColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PulseColors.primary,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 12.0, top: 2),
                        child: Icon(
                          Icons.info_outline,
                          color: PulseColors.primary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'You\'ll receive a verification code on your chosen method. Keep your device handy.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationOption(
    BuildContext context, {
    required String method,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? PulseColors.primaryContainer : PulseColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PulseColors.primary : PulseColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? PulseColors.primary : PulseColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : PulseColors.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: PulseColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: context.onSurfaceColor,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleVerification() {
    if (_selectedMethod == null) {
      PulseToast.error(
        context,
        message: 'Please select a verification method',
      );
      return;
    }

    _logger.i('🔐 Starting account verification');
    _logger.i('   ✅ User is AUTHENTICATED (valid JWT)');
    _logger.i('   ✅ Method selected: $_selectedMethod');
    _logger.i('   ✅ Backend will retrieve email/phone from JWT');
    _logger.i('   ✅ Session token links to verification');

    final authBloc = context.read<AuthBloc>();

    // ✅ Request verification OTP with SELECTED METHOD ONLY
    // ✅ Backend extracts user_id from JWT Authorization header
    // ✅ Backend retrieves user's email and phone from database using user_id
    // ✅ OTP session created with sessionId linking to this verification
    authBloc.add(
      AuthOTPSendRequested(
        type: 'phone_verification', // Account verification (not login)
        preferredMethod: _selectedMethod, // 'email' or 'whatsapp'
        // ✅ NO email/phoneNumber passed - backend gets from authenticated user
      ),
    );
  }

  // Build continue button
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedMethod == null ? null : _handleVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          disabledBackgroundColor: PulseColors.primary.withAlpha(128),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Continue',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
