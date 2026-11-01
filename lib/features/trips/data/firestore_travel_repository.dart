import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/trip.dart';
import '../domain/travel_repository.dart';
import '../../activities/domain/trip_activity.dart';
import '../../packing/packing_repository.dart';
import '../../../core/validation.dart';

class FirestoreTravelRepository implements TravelRepository {
  final FirebaseFirestore db;
  final PackingRepository packing;
  FirestoreTravelRepository(this.db, this.packing);
  CollectionReference<Map<String, dynamic>> trips(String uid) =>
      db.collection('users').doc(uid).collection('trips');
  DateTime? stamp(dynamic value) => value is Timestamp ? value.toDate() : null;
  Trip trip(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Trip.fromFields(
      doc.id,
      d,
      createdAt: stamp(d['createdAt']),
      updatedAt: stamp(d['updatedAt']),
    );
  }

  TripActivity activity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return TripActivity.fromFields(
      doc.id,
      d,
      createdAt: stamp(d['createdAt']),
      updatedAt: stamp(d['updatedAt']),
    );
  }

  @override
  Stream<DataSnapshot<List<Trip>>> watchTrips(
    String uid, {
    bool deleting = false,
  }) {
    Query<Map<String, dynamic>> q = trips(
      uid,
    ).where('status', isEqualTo: deleting ? 'deleting' : 'active');
    if (!deleting) q = q.orderBy('startDate');
    return q
        .snapshots(includeMetadataChanges: true)
        .map(
          (s) => DataSnapshot(
            s.docs.map(trip).toList(),
            cached: s.metadata.isFromCache,
            pending: s.metadata.hasPendingWrites,
          ),
        );
  }

  @override
  Stream<DataSnapshot<Trip?>> watchTrip(String uid, String tripId) => trips(uid)
      .doc(tripId)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => DataSnapshot(
          s.exists ? trip(s) : null,
          cached: s.metadata.isFromCache,
          pending: s.metadata.hasPendingWrites,
        ),
      );
  @override
  Stream<DataSnapshot<List<TripActivity>>> watchActivities(
    String uid,
    String tripId,
  ) => trips(uid)
      .doc(tripId)
      .collection('activities')
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => DataSnapshot(
          sortedActivities(s.docs.map(activity)),
          cached: s.metadata.isFromCache,
          pending: s.metadata.hasPendingWrites,
        ),
      );
  @override
  Future<void> saveTrip(String uid, Trip value, {required bool create}) async {
    value.validate();
    final ref = trips(uid).doc(value.id);
    // Server-only preflight: range shrinking is single-editor validation, not a cross-device guarantee.
    if (!create) {
      final children = await ref
          .collection('activities')
          .get(const GetOptions(source: Source.server));
      requireValid(
        children.docs.every(
          (d) =>
              (d['date'] as String).compareTo(value.startDate) >= 0 &&
              (d['date'] as String).compareTo(value.endDate) <= 0,
        ),
        'มีกิจกรรมนอกช่วงวันใหม่ กรุณาแก้กิจกรรมก่อน',
      );
    }
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      requireValid(create || old.exists, 'ไม่พบทริป');
      requireValid(!old.exists || old['status'] == 'active', 'ทริปกำลังลบ');
      requireValid(
        !old.exists ||
            !(old.data()?['completed'] as bool? ?? false) ||
            value.completed,
        'ทริปนี้จบแล้ว กรุณาโหลดข้อมูลใหม่',
      );
      // Stable ID makes a retry update the same document after an uncertain result.
      tx.set(ref, {
        ...value.fields(),
        'createdAt': old.exists
            ? old['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> saveActivity(
    String uid,
    String tripId,
    TripActivity value, {
    required bool create,
  }) async {
    final parent = trips(uid).doc(tripId);
    final ref = parent.collection('activities').doc(value.id);
    await db.runTransaction((tx) async {
      final p = await tx.get(parent);
      final old = await tx.get(ref);
      requireValid(p.exists && p['status'] == 'active', 'ไม่พบทริปที่แก้ไขได้');
      requireValid(create || old.exists, 'ไม่พบกิจกรรม');
      value.validate(trip(p));
      tx.set(ref, {
        ...value.fields(),
        'createdAt': old.exists
            ? old['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> reorderActivities(
    String uid,
    String tripId,
    List<TripActivity> ordered,
  ) async {
    requireValid(
      ordered.isNotEmpty &&
          ordered.length <= 100 &&
          ordered.map((a) => a.id).toSet().length == ordered.length &&
          ordered.every((a) => a.date == ordered.first.date),
      'เรียงได้ครั้งละไม่เกิน 100 จุดในวันเดียว',
    );
    final parent = trips(uid).doc(tripId);
    await db.runTransaction((tx) async {
      final p = await tx.get(parent);
      requireValid(p.exists && p['status'] == 'active', 'ทริปไม่พร้อมแก้ไข');
      final docs = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final a in ordered) {
        docs.add(await tx.get(parent.collection('activities').doc(a.id)));
      }
      for (var i = 0; i < ordered.length; i++) {
        requireValid(
          docs[i].exists &&
              mapEquals(activity(docs[i]).fields(), ordered[i].fields()),
          'ข้อมูลเปลี่ยนแล้ว กรุณาโหลดใหม่ก่อนเรียง',
        );
      }
      for (var i = 0; i < ordered.length; i++) {
        tx.update(docs[i].reference, {
          'schemaVersion': 2,
          ...ordered[i].withRank(i * 1000).fields(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> deleteActivity(String uid, String tripId, String id) async {
    final parent = trips(uid).doc(tripId);
    await db.runTransaction((tx) async {
      final p = await tx.get(parent);
      requireValid(p.exists && p['status'] == 'active', 'ทริปไม่พร้อมแก้ไข');
      tx.delete(parent.collection('activities').doc(id));
    });
  }

  @override
  Future<void> completeTrip(String uid, String tripId) async {
    final parent = trips(uid).doc(tripId);
    await db.runTransaction((tx) async {
      final old = await tx.get(parent);
      requireValid(
        old.exists && old['status'] == 'active',
        'ทริปไม่พร้อมแก้ไข',
      );
      final value = trip(old);
      if (value.completed) return;
      value.validate();
      tx.update(parent, {
        'completed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deleteTrip(String uid, String tripId) async {
    await packing.queueCleanup(uid, tripId);
    final ref = trips(uid).doc(tripId);
    await db.runTransaction((tx) async {
      final d = await tx.get(ref);
      if (d.exists && d['status'] == 'active') {
        tx.update(ref, {
          'status': 'deleting',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    await _continueDelete(uid, tripId);
  }

  Future<void> _continueDelete(String uid, String id) async {
    final ref = trips(uid).doc(id);
    final p = await ref.get(const GetOptions(source: Source.server));
    if (!p.exists) {
      await packing.finishCleanup(uid, id);
      return;
    }
    if (p['status'] != 'deleting') {
      return; // A queued intent alone never deletes active local data.
    }
    while (true) {
      final children = await ref
          .collection('activities')
          .limit(100)
          .get(const GetOptions(source: Source.server));
      if (children.docs.isEmpty) break;
      final batch = db.batch();
      for (final child in children.docs) {
        batch.delete(child.reference);
      }
      await batch.commit();
    }
    await ref.delete();
    await packing.finishCleanup(uid, id);
  }

  @override
  Future<void> resumePendingDeletes(String uid) async {
    final pending = await trips(uid)
        .where('status', isEqualTo: 'deleting')
        .get(const GetOptions(source: Source.server));
    for (final id in {
      ...packing.cleanupQueue(uid),
      ...pending.docs.map((d) => d.id),
    }) {
      await _continueDelete(uid, id);
    }
  }
}
