// Google Sign-In wrapper. Keeps the plugin behind an interface so account flows
// can be tested without native UI.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Credential and profile from a chosen Google account.
class GoogleIdentity {
  final AuthCredential credential;
  final String email;
  final String? name, photoUrl;
  const GoogleIdentity({
    required this.credential,
    required this.email,
    this.name,
    this.photoUrl,
  });
}

/// Abstraction over Google Sign-In, so tests can use a fake.
abstract class GoogleIdentityClient {
  /// Prompts for an account. Returns null if cancelled.
  Future<GoogleIdentity?> authenticate();

  /// Signs out of Google.
  Future<void> signOut();
}

/// Native implementation for Android and iOS.
class NativeGoogleIdentityClient implements GoogleIdentityClient {
  Future<void>? _initialized;

  /// Initializes the SDK once, then exchanges the account for a credential.
  ///
  /// Cancelled and interrupted prompts return null rather than throwing.
  @override
  Future<GoogleIdentity?> authenticate() async {
    _initialized ??= GoogleSignIn.instance.initialize();
    await _initialized;
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google Sign-In รองรับ Android/iOS ในรุ่นนี้');
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw StateError('ไม่ได้รับการยืนยันจาก Google กรุณาลองใหม่');
      }
      return GoogleIdentity(
        credential: GoogleAuthProvider.credential(idToken: token),
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// No-op if the SDK was never initialized.
  @override
  Future<void> signOut() async {
    if (_initialized != null) {
      await _initialized;
      await GoogleSignIn.instance.signOut();
    }
  }
}
