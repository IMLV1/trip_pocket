import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/features/auth/auth_repository.dart';
import 'package:trip_pocket/features/auth/google_identity_client.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/data/firestore_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

class FixtureGoogle implements GoogleIdentityClient {
  GoogleIdentity? next;
  @override
  Future<GoogleIdentity?> authenticate() async => next;
  @override
  Future<void> signOut() async {}
}

String testToken(String email, String sub) {
  String part(Object x) =>
      base64Url.encode(utf8.encode(jsonEncode(x))).replaceAll('=', '');
  return '${part({'alg': 'none', 'typ': 'JWT'})}.${part({'sub': sub, 'email': email, 'email_verified': true, 'name': 'Google fixture', 'picture': 'https://lh3.googleusercontent.com/test-fixture', 'iss': 'https://accounts.google.com', 'aud': 'demo-trippocket', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'SDK profile, reauthentication, reset OOB, Google link identity and trip completion',
    (tester) async {
      const live = bool.fromEnvironment(
        'LIVE_ACCOUNT_TEST',
        defaultValue: false,
      );
      final app = live
          ? await Firebase.initializeApp()
          : await Firebase.initializeApp(
              name: 'account-emulator',
              options: const FirebaseOptions(
                apiKey: 'demo-key',
                appId: '1:123456789:android:demo',
                messagingSenderId: '123456789',
                projectId: 'demo-trippocket',
              ),
            );
      final auth = FirebaseAuth.instanceFor(app: app),
          db = FirebaseFirestore.instanceFor(app: app);
      if (!live) {
        await auth.useAuthEmulator('10.0.2.2', 9099);
        db.useFirestoreEmulator('10.0.2.2', 8080);
        db.settings = const Settings(persistenceEnabled: false);
      }
      await auth.signOut();
      final run = DateTime.now().microsecondsSinceEpoch.toString(),
          email = 'account-$run@example.com';
      var password = 'Fixture-$run!';
      final user = (await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      )).user!;
      final uid = user.uid;
      final google = FixtureGoogle(),
          repository = FirebaseAuthRepository(auth, google: FixtureGoogle());
      final linkedRepo = FirebaseAuthRepository(auth, google: google);
      final packing = PackingRepository(await SharedPreferences.getInstance()),
          tripRepo = FirestoreTravelRepository(
            db,
            PackingRepository(await SharedPreferences.getInstance()),
          );
      final tripId = 'account-$run';
      try {
        await repository.updateDisplayName('ชื่อที่ผู้ใช้ตั้ง');
        await auth.currentUser!.reload();
        expect(auth.currentUser!.displayName, 'ชื่อที่ผู้ใช้ตั้ง');
        expect(auth.currentUser!.uid, uid);
        if (!live) {
          expect(await linkedRepo.connectGoogleProfile(), isFalse);
          expect(auth.currentUser!.uid, uid);
          google.next = GoogleIdentity(
            email: 'other@example.com',
            credential: GoogleAuthProvider.credential(
              idToken: testToken('other@example.com', 'other-$run'),
            ),
          );
          await expectLater(
            linkedRepo.connectGoogleProfile(),
            throwsStateError,
          );
          expect(
            auth.currentUser!.providerData.any(
              (p) => p.providerId == 'google.com',
            ),
            isFalse,
          );
          google.next = GoogleIdentity(
            email: email,
            credential: GoogleAuthProvider.credential(
              idToken: testToken(email, 'google-$run'),
            ),
            name: 'Google fixture',
            photoUrl: 'https://lh3.googleusercontent.com/test-fixture',
          );
          expect(await linkedRepo.connectGoogleProfile(), isTrue);
          expect(auth.currentUser!.uid, uid);
          expect(auth.currentUser!.displayName, 'ชื่อที่ผู้ใช้ตั้ง');
          expect(
            auth.currentUser!.photoURL,
            'https://lh3.googleusercontent.com/test-fixture',
          );
          expect(linkedRepo.currentSession!.hasPassword, isTrue);
        }
        await expectLater(
          repository.changePassword(
            currentPassword: 'wrong-fixture',
            newPassword: 'Changed-$run!',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
        await repository.changePassword(
          currentPassword: password,
          newPassword: 'Changed-$run!',
        );
        password = 'Changed-$run!';
        await repository.signOut();
        await expectLater(
          repository.signIn(email, 'Fixture-$run!'),
          throwsA(isA<FirebaseAuthException>()),
        );
        await repository.signIn(email, password);
        expect(auth.currentUser!.uid, uid);
        if (!live) {
          await repository.sendPasswordReset(email);
          final client = HttpClient();
          try {
            final req = await client.getUrl(
              Uri.parse(
                'http://10.0.2.2:9099/emulator/v1/projects/demo-trippocket/oobCodes',
              ),
            );
            final res = await req.close();
            expect(res.statusCode, 200);
            final body =
                jsonDecode(await utf8.decoder.bind(res).join())
                    as Map<String, dynamic>;
            final codes = (body['oobCodes'] as List)
                .where(
                  (c) =>
                      c['email'] == email &&
                      c['requestType'] == 'PASSWORD_RESET',
                )
                .toList();
            expect(codes, isNotEmpty);
            final code = codes.last['oobCode'] as String;
            await auth.confirmPasswordReset(
              code: code,
              newPassword: 'Reset-$run!',
            );
            password = 'Reset-$run!';
            await auth.signOut();
            await repository.signIn(email, password);
            expect(auth.currentUser!.uid, uid);
          } finally {
            client.close(force: true);
          }
        }
        final t = Trip(
          id: tripId,
          title: 'ทริปทดสอบ',
          destination: 'ไทย',
          startDate: '2026-11-06',
          endDate: '2026-11-08',
          budgetSatang: 12345,
        );
        await tripRepo.saveTrip(uid, t, create: true);
        await packing.save(uid, tripId, [
          const PackingItem('p', 'charger', true),
        ]);
        final serverDoc = tripRepo.trips(uid).doc(tripId);
        final denied = throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        );
        await expectLater(
          serverDoc.update({
            'endDate': t.startDate,
            'updatedAt': FieldValue.serverTimestamp(),
          }),
          denied,
        );
        await tripRepo.completeTrip(uid, tripId);
        await tripRepo.completeTrip(uid, tripId);
        final stored = tripRepo.trip(
          await tripRepo
              .trips(uid)
              .doc(tripId)
              .get(const GetOptions(source: Source.server)),
        );
        expect(stored.completed, isTrue);
        await expectLater(
          serverDoc.update({
            'completed': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }),
          denied,
        );

        expect(stored.budgetSatang, 12345);
        expect((await packing.load(uid, tripId)).single.checked, isTrue);
        await tripRepo.saveTrip(
          uid,
          Trip(
            id: tripId,
            title: 'แก้หลังจบ',
            destination: t.destination,
            startDate: t.startDate,
            endDate: t.endDate,
            budgetSatang: t.budgetSatang,
            completed: true,
          ),
          create: false,
        );
        expect(
          (await tripRepo
              .trips(uid)
              .doc(tripId)
              .get(const GetOptions(source: Source.server)))['completed'],
          isTrue,
        );
        await expectLater(
          tripRepo.saveTrip(
            uid,
            Trip(
              id: 'bad',
              title: 'วันเดียวกัน',
              destination: 'ไทย',
              startDate: t.startDate,
              endDate: t.startDate,
              budgetSatang: 0,
            ),
            create: true,
          ),
          throwsStateError,
        );
        await auth.signOut();
        final other = (await auth.createUserWithEmailAndPassword(
          email: 'other-account-$run@example.com',
          password: 'Other-$run!',
        )).user!;
        try {
          await expectLater(
            tripRepo
                .trips(uid)
                .doc(tripId)
                .get(const GetOptions(source: Source.server)),
            throwsA(isA<FirebaseException>()),
          );
        } finally {
          await other.delete();
        }
        await repository.signIn(email, password);
      } finally {
        if (auth.currentUser?.uid != uid) {
          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
        await tripRepo.deleteTrip(uid, tripId);
        await auth.currentUser!.delete();
        await auth.signOut();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
