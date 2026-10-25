import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/features/trips/data/firestore_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Firebase SDK auth, CRUD, account isolation and resumable cleanup',
    (tester) async {
      const mode = String.fromEnvironment('APP_MODE', defaultValue: 'emulator');
      if (mode == 'live') {
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(
          name: 'emulator',
          options: const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:123456789:android:demo',
            messagingSenderId: '123456789',
            projectId: 'demo-trippocket',
          ),
        );
      }
      final firebaseApp = mode == 'live'
          ? Firebase.app()
          : Firebase.app('emulator');
      final auth = FirebaseAuth.instanceFor(app: firebaseApp),
          db = FirebaseFirestore.instanceFor(app: firebaseApp);
      if (mode != 'live') {
        await auth.useAuthEmulator('10.0.2.2', 9099);
        db.useFirestoreEmulator('10.0.2.2', 8080);
        db.settings = const Settings(persistenceEnabled: false);
      }
      await auth.signOut();
      final run = DateTime.now().microsecondsSinceEpoch.toString();
      final email = 'trip-test-$run@example.com', password = 'Test-$run!';
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final packing = PackingRepository(await SharedPreferences.getInstance());
      final repo = FirestoreTravelRepository(db, packing);
      final t = Trip(
        id: 'test-$run',
        title: 'เชียงใหม่ทดสอบ',
        destination: 'เชียงใหม่',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 300000,
      );
      await repo.saveTrip(uid, t, create: true);
      await repo.saveTrip(uid, t, create: true); // retry same id
      await repo.saveTrip(uid, t, create: false);
      final a = TripActivity(
        id: 'a',
        title: 'คาเฟ่',
        date: '2026-11-07',
        timeMinutes: 540,
        estimatedCostSatang: 20001,
        latitude: 18.78,
        longitude: 98.98,
      );
      await repo.saveActivity(uid, t.id, a, create: true);
      expect(
        (await repo
                .watchActivities(uid, t.id)
                .firstWhere((s) => !s.cached && !s.pending))
            .value
            .single
            .estimatedCostSatang,
        20001,
      );
      await expectLater(
        repo.saveTrip(
          uid,
          Trip(
            id: t.id,
            title: t.title,
            destination: t.destination,
            startDate: '2026-11-06',
            endDate: '2026-11-06',
            budgetSatang: 0,
          ),
          create: false,
        ),
        throwsStateError,
      );
      await packing.save(uid, t.id, [const PackingItem('x', 'สายชาร์จ', true)]);
      await db.disableNetwork();
      try {
        await packing.save(uid, t.id, [
          const PackingItem('x', 'สายชาร์จ', true),
        ]);
        await expectLater(
          repo.saveTrip(uid, t, create: false),
          throwsA(isA<FirebaseException>()),
        );
      } finally {
        await db.enableNetwork();
      }
      await repo.deleteActivity(uid, t.id, a.id);
      await repo.saveActivity(uid, t.id, a, create: true);
      await repo.saveActivity(uid, t.id, a, create: false);
      await packing.queueCleanup(uid, t.id);
      await repo.resumePendingDeletes(uid);
      expect(await packing.load(uid, t.id), hasLength(1));
      await auth.signOut();
      await expectLater(
        db
            .doc('users/$uid/trips/${t.id}')
            .get(const GetOptions(source: Source.server)),
        throwsA(isA<FirebaseException>()),
      );
      await auth.createUserWithEmailAndPassword(
        email: 'trip-b-$run@example.com',
        password: password,
      );
      await expectLater(
        db
            .doc('users/$uid/trips/${t.id}')
            .get(const GetOptions(source: Source.server)),
        throwsA(isA<FirebaseException>()),
      );
      await auth.currentUser!.delete();
      await auth.signInWithEmailAndPassword(email: email, password: password);
      expect((await packing.load(uid, t.id)).single.checked, isTrue);
      await db.doc('users/$uid/trips/${t.id}').update({
        'status': 'deleting',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await repo.resumePendingDeletes(uid);
      expect(
        (await db
                .doc('users/$uid/trips/${t.id}')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isFalse,
      );
      expect(await packing.load(uid, t.id), isEmpty);
      expect(packing.cleanupQueue(uid), isEmpty);
      await auth.currentUser!.delete();
    },
  );
}
