import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class Session {
  final String uid, email;
  const Session(this.uid, this.email);
}

abstract class AuthRepository {
  Stream<Session?> watchSession();
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth auth;
  FirebaseAuthRepository(this.auth);
  @override
  Stream<Session?> watchSession() => auth.authStateChanges().map(
    (u) => u == null ? null : Session(u.uid, u.email ?? ''),
  );
  @override
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => auth.signOut();
}

/// Explicit demo only. No real passwords are persisted or authenticated.
class DemoAuthRepository implements AuthRepository {
  Session? _session;
  final _events = StreamController<Session?>.broadcast();
  @override
  Stream<Session?> watchSession() async* {
    yield _session;
    yield* _events.stream;
  }

  @override
  Future<void> signIn(String email, String password) async {
    _session = Session('demo-${email.trim().toLowerCase()}', email.trim());
    _events.add(_session);
  }

  @override
  Future<void> register(String email, String password) =>
      signIn(email, password);
  @override
  Future<void> signOut() async {
    _session = null;
    _events.add(null);
  }
}
