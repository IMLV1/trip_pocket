import 'dart:convert';
import 'dart:io' show pid;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/data/firestore_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';

/// Run setup and verify in SEPARATE flutter test invocations on the same device.
/// Uses a temporary live Firebase user, never stores its password, and refuses
/// to replace an unrelated signed-in user on the test device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('P7 process restart: persisted auth, packing and pending deletion', (
    tester,
  ) async {
    const phase = String.fromEnvironment('PERSISTENCE_PHASE');
    expect(
      ['setup', 'verify', 'cleanup'].contains(phase),
      isTrue,
      reason: 'Specify setup or verify explicitly',
    );
    await Firebase.initializeApp();
    final auth = FirebaseAuth.instance, db = FirebaseFirestore.instance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final packing = PackingRepository(prefs),
        repo = FirestoreTravelRepository(db, PackingRepository(prefs));
    const manifestKey = 'p7.restart.fixture.v1';
    final raw = prefs.getString(manifestKey);
    final previous = raw == null
        ? null
        : jsonDecode(raw) as Map<String, dynamic>;
    final session = await auth.authStateChanges().first;
    if (phase == 'cleanup') {
      const run = String.fromEnvironment('FIXTURE_RUN');
      expect(
        RegExp(r'^\d{16}$').hasMatch(run),
        isTrue,
        reason: 'Use only the run id of this test fixture',
      );
      final email = 'p7-restart-$run@example.com';
      expect(
        session == null || session.email == email,
        isTrue,
        reason: 'Do not replace an unrelated account',
      );
      await auth.signInWithEmailAndPassword(
        email: email,
        password: 'Test-$run!',
      );
      final uid = auth.currentUser!.uid;
      final documents = await db
          .collection('users')
          .doc(uid)
          .collection('trips')
          .get(const GetOptions(source: Source.server));
      expect(
        documents.docs.every((d) => d['title'] == 'P7 restart test'),
        isTrue,
      );
      for (final d in documents.docs) {
        await repo.deleteTrip(uid, d.id);
      }
      await auth.currentUser!.delete();
      if (previous?['uid'] == uid) await prefs.remove(manifestKey);
      return;
    }
    if (phase == 'setup') {
      expect(
        session == null || (previous != null && session.uid == previous['uid']),
        isTrue,
        reason: 'Sign out of your own account before running this test',
      );
      if (previous != null) {
        expect(
          session?.uid,
          previous['uid'],
          reason:
              'Existing fixture requires its original test session for cleanup',
        );
        for (final id in [
          previous['tripId'],
          '${previous['tripId']}-deleting',
        ]) {
          await repo.deleteTrip(session!.uid, id);
        }
        await repo.resumePendingDeletes(session!.uid);
        await auth.currentUser!.delete();
        await prefs.remove(manifestKey);
      }
      final run = DateTime.now().microsecondsSinceEpoch;
      final user = (await auth.createUserWithEmailAndPassword(
        email: 'p7-restart-$run@example.com',
        password: 'Test-$run!',
      )).user!;
      final tripId = 'restart-$run';
      // Save recovery marker before creating any cloud/local fixture data.
      await prefs.setString(
        manifestKey,
        jsonEncode({'uid': user.uid, 'tripId': tripId, 'pid': pid}),
      );
      for (final id in [tripId, '$tripId-deleting']) {
        await repo.saveTrip(
          user.uid,
          Trip(
            id: id,
            title: 'P7 restart test',
            destination: 'เชียงใหม่',
            startDate: '2026-11-06',
            endDate: '2026-11-08',
            budgetSatang: 300000,
          ),
          create: true,
        );
        await repo.saveActivity(
          user.uid,
          id,
          TripActivity(
            id: 'a',
            title: 'คาเฟ่',
            date: '2026-11-07',
            timeMinutes: 540,
            estimatedCostSatang: 20000,
            latitude: 18.78,
            longitude: 98.98,
          ),
          create: true,
        );
        await packing.save(user.uid, id, [
          const PackingItem('charger', 'สายชาร์จ P7', true),
        ]);
        await packing.queueCleanup(user.uid, id);
      }
      await db.doc('users/${user.uid}/trips/$tripId-deleting').update({
        'status': 'deleting',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Keep session deliberately; the next OS process must restore it itself.
    } else {
      expect(
        previous,
        isNotNull,
        reason: 'Run setup first without clearing or uninstalling the app',
      );
      expect(
        pid,
        isNot(previous!['pid']),
        reason: 'Verification must run in a new OS process',
      );
      final uid = previous['uid'] as String,
          tripId = previous['tripId'] as String;
      expect(
        session?.uid,
        uid,
        reason: 'Firebase session should survive process restart',
      );
      await db.disableNetwork();
      try {
        expect((await packing.load(uid, tripId)).single.checked, isTrue);
        expect(await packing.load('other-account', tripId), isEmpty);
      } finally {
        await db.enableNetwork();
      }
      expect(
        (await db
            .doc('users/$uid/trips/$tripId')
            .get(const GetOptions(source: Source.server)))['title'],
        'P7 restart test',
      );
      await repo.resumePendingDeletes(uid);
      expect(
        (await db
                .doc('users/$uid/trips/$tripId-deleting')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isFalse,
      );
      expect(await packing.load(uid, '$tripId-deleting'), isEmpty);
      expect(
        await packing.load(uid, tripId),
        hasLength(1),
        reason: 'Active trip cleanup intent must not erase packing',
      );
      await repo.deleteTrip(uid, tripId);
      expect(packing.cleanupQueue(uid), isEmpty);
      await auth.currentUser!.delete();
      await prefs.remove(manifestKey);
      expect(auth.currentUser, isNull);
    }
  });
}
