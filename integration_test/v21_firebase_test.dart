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
    'V2.1 SDK legacy upgrade, transactional reorder, stale data rejection and cleanup',
    (tester) async {
      const mode = String.fromEnvironment('APP_MODE', defaultValue: 'emulator');
      final app = mode == 'live'
          ? await Firebase.initializeApp()
          : await Firebase.initializeApp(
              name: 'emulator',
              options: const FirebaseOptions(
                apiKey: 'demo-key',
                appId: '1:123456789:android:demo',
                messagingSenderId: '123456789',
                projectId: 'demo-trippocket',
              ),
            );
      final auth = FirebaseAuth.instanceFor(app: app),
          db = FirebaseFirestore.instanceFor(app: app);
      if (mode != 'live') {
        await auth.useAuthEmulator('10.0.2.2', 9099);
        db.useFirestoreEmulator('10.0.2.2', 8080);
        db.settings = const Settings(persistenceEnabled: false);
      }
      await auth.signOut();
      final run = DateTime.now().microsecondsSinceEpoch.toString(),
          password = 'Test-$run!';
      final email = 'v21-$run@example.com';
      final user = (await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      )).user!;
      final uid = user.uid;
      final packing = PackingRepository(await SharedPreferences.getInstance()),
          repo = FirestoreTravelRepository(
            db,
            PackingRepository(await SharedPreferences.getInstance()),
          );
      final t = Trip(
        id: 'v21-$run',
        title: 'เชียงใหม่ V2.1 test',
        destination: 'เชียงใหม่',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 300000,
        destinationLatitude: 18.78,
        destinationLongitude: 98.98,
      );
      try {
        await repo.saveTrip(uid, t, create: true);
        final persisted = repo.trip(
          await repo
              .trips(uid)
              .doc(t.id)
              .get(const GetOptions(source: Source.server)),
        );
        expect(persisted.destinationLatitude, 18.78);
        expect(persisted.destinationLongitude, 98.98);
        // Explicitly removing a pin writes a null pair and keeps the budget.
        await repo.saveTrip(
          uid,
          Trip(
            id: t.id,
            title: t.title,
            destination: t.destination,
            startDate: t.startDate,
            endDate: t.endDate,
            budgetSatang: t.budgetSatang,
          ),
          create: false,
        );
        final cleared = repo.trip(
          await repo
              .trips(uid)
              .doc(t.id)
              .get(const GetOptions(source: Source.server)),
        );
        expect(cleared.hasDestinationPin, isFalse);
        expect(cleared.budgetSatang, t.budgetSatang);
        final parent = repo.trips(uid).doc(t.id),
            legacy = repo
                .trips(uid)
                .doc(t.id)
                .collection('activities')
                .doc('old');
        await legacy.set({
          'title': 'legacy',
          'date': t.startDate,
          'timeMinutes': 540,
          'estimatedCostSatang': 12345,
          'latitude': 18.78,
          'longitude': 98.98,
          'note': 'private',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final old = repo.activity(
          await legacy.get(const GetOptions(source: Source.server)),
        );
        expect(old.costKnown, isTrue);
        expect(plannedTotal([old]), 12345);
        await repo.saveActivity(uid, t.id, old, create: false);
        expect(
          (await legacy.get(
            const GetOptions(source: Source.server),
          ))['schemaVersion'],
          2,
        );
        final target = TripActivity(
          id: 'b',
          title: 'food',
          date: t.startDate,
          timeMinutes: 600,
          estimatedCostSatang: 10000,
          latitude: 18.79,
          longitude: 98.99,
          category: 'food',
        );
        final b = TripActivity.fromFields('b', {
          ...target.fields(),
          'travelMode': 'car',
          'travelFromId': old.id,
          'travelSignature': segmentSignature(old, target),
          'travelCostKnown': true,
          'travelCostSatang': 2000,
        });
        await repo.saveActivity(uid, t.id, b, create: true);
        Future<List<TripActivity>> read() async => sortedActivities(
          (await parent
                  .collection('activities')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .map(repo.activity),
        );
        var list = await read();
        expect(plannedTotal(list), 24345);
        await repo.reorderActivities(uid, t.id, [list[1], list[0]]);
        list = await read();
        expect(list.map((a) => a.id), ['b', 'old']);
        expect(planBudget(list).transport, 0);
        final stale = [...list];
        await repo.saveActivity(
          uid,
          t.id,
          TripActivity.fromFields(list[0].id, {
            ...list[0].fields(),
            'title': 'changed',
          }),
          create: false,
        );
        await expectLater(
          repo.reorderActivities(uid, t.id, stale.reversed.toList()),
          throwsA(anyOf(isA<StateError>(), isA<FirebaseException>())),
        );
        // Android's method channel can wrap a callback StateError as FirebaseException.
        // Assert the safety property on server data, rather than just its Dart type.
        final afterRejectedOrder = await read();
        expect(afterRejectedOrder.map((a) => a.id), ['b', 'old']);
        expect(afterRejectedOrder.first.title, 'changed');
        await packing.save(uid, t.id, [
          const PackingItem('pack', 'charger', false),
        ]);
        await packing.queueCleanup(uid, t.id);
        await parent.update({
          'status': 'deleting',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await expectLater(
          repo.saveActivity(uid, t.id, b, create: false),
          throwsA(anyOf(isA<StateError>(), isA<FirebaseException>())),
        );
        final afterRejectedSave = await read();
        expect(afterRejectedSave.first.title, 'changed');
        await repo.resumePendingDeletes(uid);
        expect(
          (await parent.get(const GetOptions(source: Source.server))).exists,
          isFalse,
        );
        expect(await packing.load(uid, t.id), isEmpty);
        // Cross-account SDK checks use server reads; no cached owner data is treated as authorization.
        await repo.saveTrip(uid, t, create: true);
        await auth.signOut();
        await expectLater(
          parent.get(const GetOptions(source: Source.server)),
          throwsA(isA<FirebaseException>()),
        );
        final second = (await auth.createUserWithEmailAndPassword(
          email: 'v21-b-$run@example.com',
          password: password,
        )).user!;
        try {
          await expectLater(
            parent.get(const GetOptions(source: Source.server)),
            throwsA(isA<FirebaseException>()),
          );
        } finally {
          await second.delete();
        }
        await auth.signInWithEmailAndPassword(email: email, password: password);
      } finally {
        if (auth.currentUser?.uid != uid) {
          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
        await repo.deleteTrip(uid, t.id);
        await auth.currentUser!.delete();
        await auth.signOut();
      }
    },
  );
}
