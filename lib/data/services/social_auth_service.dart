import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:logger/logger.dart';

/// Service for handling social authentication (Google, Apple, Facebook)
class SocialAuthService {
  final _logger = Logger();
  late final GoogleSignIn _googleSignIn;

  SocialAuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: <String>['email'],
    );
  }

  /// Sign in with Google and get ID token
  /// Returns null if user cancels or error occurs
  Future<String?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();

      // Trigger sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User canceled sign-in
        return null;
      }

      // Get authentication
      final GoogleSignInAuthentication auth = await account.authentication;

      // Return ID token for backend verification
      return auth.idToken;
    } catch (error) {
      _logger.e('Google sign in error: $error');
      return null;
    }
  }

  /// Sign in with Apple and get authorization credentials
  /// Returns null if user cancels or error occurs
  Future<AppleAuthResult?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // For web support - adjust domain as needed
          clientId: 'your.bundle.identifier.here',
          redirectUri: Uri.parse('https://your-domain.com/callbacks/apple'),
        ),
      );

      return AppleAuthResult(
        identityToken: credential.identityToken,
        authorizationCode: credential.authorizationCode,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } catch (error) {
      _logger.e('Apple sign in error: $error');
      return null;
    }
  }

  /// Sign in with Facebook and get access token
  /// Returns null if user cancels or error occurs
  Future<String?> signInWithFacebook() async {
    try {
      // Trigger Facebook login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get access token
        final AccessToken? accessToken = result.accessToken;
        return accessToken?.token;
      } else if (result.status == LoginStatus.cancelled) {
        // User cancelled
        return null;
      } else {
        // Error occurred
        _logger.e('Facebook login error: ${result.message}');
        return null;
      }
    } catch (error) {
      _logger.e('Facebook sign in error: $error');
      return null;
    }
  }

  /// Sign out from all social providers
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
        // Apple doesn't have a sign-out method
      ]);
    } catch (error) {
      _logger.e('Error signing out from social providers: $error');
    }
  }

  /// Disconnect Google account
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      _logger.e('Error disconnecting Google: $error');
    }
  }

  /// Get current Google sign-in status (simplified check)
  Future<bool> isSignedInWithGoogle() async {
    // Note: The new google_sign_in 7.x doesn't provide a direct isSignedIn check
    // This is a simplified version that returns false
    // To properly check, you'd need to attempt signInSilently
    return false;
  }

  /// Get current Facebook sign-in status
  Future<bool> isSignedInWithFacebook() async {
    final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
    return accessToken != null;
  }
}

/// Result data from Apple Sign In
class AppleAuthResult {
  final String? identityToken;
  final String? authorizationCode;
  final String? email;
  final String? givenName;
  final String? familyName;

  AppleAuthResult({
    required this.identityToken,
    required this.authorizationCode,
    this.email,
    this.givenName,
    this.familyName,
  });
}
