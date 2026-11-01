// Account operations, with Firebase and demo implementations.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/validation.dart';
import 'google_identity_client.dart';

/// App-level view of the signed-in user.
class Session {
  final String uid, email;
  final String? displayName, photoUrl;
  final bool hasPassword, googleLinked;
  const Session(
    this.uid,
    this.email, {
    this.displayName,
    this.photoUrl,
    this.hasPassword = true,
    this.googleLinked = false,
  });
}

/// Account operations used by the screens.
abstract class AuthRepository {
  /// Emits on every sign-in, sign-out or profile change.
  Stream<Session?> watchSession();

  /// The current session, if any.
  Session? get currentSession;

  /// Signs in with email and password.
  Future<void> signIn(String email, String password);

  /// Creates an account.
  Future<void> register(String email, String password);

  /// Signs out.
  Future<void> signOut();

  /// Requests a password reset email.
  Future<void> sendPasswordReset(String email);

  /// Updates the display name.
  Future<void> updateDisplayName(String name);

  /// Changes the password after verifying the current one.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Links Google for the profile photo. Returns false if cancelled.
  Future<bool> connectGoogleProfile();

  /// Signs in with Google. Returns false if cancelled.
  Future<bool> signInWithGoogle();
}

/// [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth auth;
  final GoogleIdentityClient google;
  FirebaseAuthRepository(this.auth, {GoogleIdentityClient? google})
    : google = google ?? NativeGoogleIdentityClient();

  /// Maps a Firebase user to a [Session].
  Session? session(User? u) => u == null
      ? null
      : Session(
          u.uid,
          u.email ?? '',
          displayName: u.displayName,
          photoUrl: u.photoURL,
          hasPassword: u.providerData.any((p) => p.providerId == 'password'),
          googleLinked: u.providerData.any((p) => p.providerId == 'google.com'),
        );
  @override
  Session? get currentSession => session(auth.currentUser);

  /// Returns the current user, or throws if signed out.
  User requireUser() {
    final u = auth.currentUser;
    if (u == null) throw StateError('กรุณาเข้าสู่ระบบอีกครั้ง');
    return u;
  }

  /// Throws if the account changed during an async step.
  void sameUser(String uid) => requireValid(
    auth.currentUser?.uid == uid,
    'บัญชีเปลี่ยนแล้ว กรุณาลองใหม่',
  );

  /// Uses `userChanges` so profile edits are emitted too.
  @override
  Stream<Session?> watchSession() => auth.userChanges().map(session);

  /// Signs in with the trimmed email.
  @override
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers with the trimmed email.
  @override
  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs out of Firebase first, then best-effort from Google.
  @override
  Future<void> signOut() async {
    await auth.signOut();
    // Firebase owns the session; an SDK sign-out failure must not restore it.
    try {
      await google.signOut();
    } catch (_) {}
  }

  /// Hides `user-not-found` to avoid revealing which emails have accounts.
  @override
  Future<void> sendPasswordReset(String email) async {
    requireValid(emailError(email) == null, 'กรอกอีเมลให้ถูกต้อง');
    await auth.setLanguageCode('th');
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
  }

  /// Saves the name, then reloads the user.
  @override
  Future<void> updateDisplayName(String name) async {
    requireValid(
      textError(name.trim()) == null,
      'ชื่อแสดงต้องมี 1–100 ตัวอักษร',
    );
    final user = requireUser();
    await user.updateDisplayName(name.trim());
    sameUser(user.uid);
    await user.reload();
  }

  /// Reauthenticates, then updates the password.
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    requireValid(currentPassword.isNotEmpty, 'กรอกรหัสผ่านปัจจุบัน');
    requireValid(
      passwordError(newPassword) == null,
      'รหัสผ่านใหม่อย่างน้อย 6 ตัวอักษร',
    );
    requireValid(
      currentPassword != newPassword,
      'รหัสผ่านใหม่ต้องต่างจากรหัสปัจจุบัน',
    );
    final user = requireUser();
    requireValid(
      user.providerData.any((p) => p.providerId == 'password'),
      'บัญชีนี้ใช้ Google ให้จัดการรหัสผ่านในบัญชี Google',
    );
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      ),
    );
    sameUser(user.uid);
    await user.updatePassword(newPassword);
  }

  /// Links a Google account with the same email, keeping any chosen name.
  @override
  Future<bool> connectGoogleProfile() async {
    final user = requireUser();
    final uid = user.uid;
    final chosenName = user.displayName;
    final identity = await google.authenticate();
    if (identity == null) return false;
    sameUser(uid);
    requireValid(
      identity.email.toLowerCase() == user.email?.toLowerCase(),
      'เลือกบัญชี Google ที่มีอีเมลเดียวกับบัญชี TripPocket นี้',
    );
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      await user.reauthenticateWithCredential(identity.credential);
    } else {
      await user.linkWithCredential(identity.credential);
    }
    sameUser(uid);
    // Preserve the user's chosen name; Google is only a fallback for an empty name.
    if ((chosenName ?? '').trim().isNotEmpty) {
      await user.updateDisplayName(chosenName);
    }
    if ((chosenName ?? '').trim().isEmpty &&
        (identity.name ?? '').trim().isNotEmpty) {
      await user.updateDisplayName(identity.name!.trim());
    }
    if (identity.photoUrl != null &&
        Uri.tryParse(identity.photoUrl!)?.scheme == 'https') {
      await user.updatePhotoURL(identity.photoUrl);
    }
    sameUser(uid);
    await user.reload();
    return true;
  }

  /// Exchanges a Google credential for a Firebase session.
  @override
  Future<bool> signInWithGoogle() async {
    requireValid(auth.currentUser == null, 'ออกจากระบบก่อนเปลี่ยนบัญชี');
    final identity = await google.authenticate();
    if (identity == null) return false;
    requireValid(auth.currentUser == null, 'บัญชีเปลี่ยนแล้ว กรุณาลองใหม่');
    await auth.signInWithCredential(identity.credential);
    return true;
  }
}

/// Explicit demo only. No real passwords, tokens or email deliveries.
/// Demo-only accounts. No real passwords or emails.
class DemoAuthRepository implements AuthRepository {
  Session? _session;
  final _profiles = <String, Session>{};
  final _events = StreamController<Session?>.broadcast();
  @override
  Session? get currentSession => _session;

  /// Emits the current session, then later changes.
  @override
  Stream<Session?> watchSession() async* {
    yield _session;
    yield* _events.stream;
  }

  /// Updates the session and notifies listeners.
  void emit(Session? s) {
    _session = s;
    if (s != null) _profiles[s.email] = s;
    _events.add(s);
  }

  /// Signs in to a local demo profile.
  @override
  Future<void> signIn(String email, String password) async {
    final e = email.trim().toLowerCase();
    emit(_profiles[e] ?? Session('demo-$e', e));
  }

  /// Same as [signIn] in demo mode.
  @override
  Future<void> register(String email, String password) =>
      signIn(email, password);

  /// Clears the demo session.
  @override
  Future<void> signOut() async => emit(null);

  /// Only validates the email.
  @override
  Future<void> sendPasswordReset(String email) async {
    requireValid(emailError(email) == null, 'กรอกอีเมลให้ถูกต้อง');
  }

  /// Updates the demo profile.
  @override
  Future<void> updateDisplayName(String name) async {
    requireValid(
      textError(name.trim()) == null,
      'ชื่อแสดงต้องมี 1–100 ตัวอักษร',
    );
    final u = _session;
    if (u == null) throw StateError('กรุณาเข้าสู่ระบบ');
    emit(
      Session(
        u.uid,
        u.email,
        displayName: name.trim(),
        photoUrl: u.photoUrl,
        hasPassword: u.hasPassword,
        googleLinked: u.googleLinked,
      ),
    );
  }

  /// Only validates the input.
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    requireValid(
      currentPassword.isNotEmpty &&
          passwordError(newPassword) == null &&
          currentPassword != newPassword,
      'ตรวจรหัสผ่านปัจจุบันและรหัสใหม่',
    );
  }

  /// Not available in demo mode.
  @override
  Future<bool> connectGoogleProfile() async {
    throw StateError('โหมดจำลองไม่เชื่อม Google จริง');
  }

  /// Not available in demo mode.
  @override
  Future<bool> signInWithGoogle() async {
    throw StateError('โหมดจำลองไม่เข้าสู่ระบบ Google จริง');
  }
}
