import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

abstract class GoogleIdentityClient {
  Future<GoogleIdentity?> authenticate();
  Future<void> signOut();
}

class NativeGoogleIdentityClient implements GoogleIdentityClient {
  Future<void>? _initialized;
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

  @override
  Future<void> signOut() async {
    if (_initialized != null) {
      await _initialized;
      await GoogleSignIn.instance.signOut();
    }
  }
}
