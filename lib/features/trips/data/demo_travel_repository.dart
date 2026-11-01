// In-memory travel repository for demo mode.

import 'dart:async';
import '../domain/trip.dart';
import '../domain/travel_repository.dart';
import '../../activities/domain/trip_activity.dart';
import '../../packing/packing_repository.dart';
import '../../../core/validation.dart';

/// [TravelRepository] backed by in-memory maps. Data is lost on exit.
class DemoTravelRepository implements TravelRepository {
  final PackingRepository packing;
  DemoTravelRepository(this.packing);
  final _trips = <String, Map<String, Trip>>{};
  final _activities = <String, Map<String, TripActivity>>{};
  final _changes = StreamController<void>.broadcast();

  /// Trips of an account.
  Map<String, Trip> user(String u) => _trips.putIfAbsent(u, () => {});

  /// Activities of a trip.
  Map<String, TripActivity> children(String u, String t) =>
      _activities.putIfAbsent('$u/$t', () => {});

  /// Emits [read] now and after every change.
  Stream<T> watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  /// Trips with the requested status, sorted by start date.
  @override
  Stream<DataSnapshot<List<Trip>>> watchTrips(
    String uid, {
    bool deleting = false,
  }) => watch(
    () => DataSnapshot(
      user(uid).values
          .where((t) => t.status == (deleting ? 'deleting' : 'active'))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate)),
    ),
  );

  /// A single trip.
  @override
  Stream<DataSnapshot<Trip?>> watchTrip(String uid, String tripId) =>
      watch(() => DataSnapshot(user(uid)[tripId]));

  /// Sorted activities of a trip.
  @override
  Stream<DataSnapshot<List<TripActivity>>> watchActivities(
    String uid,
    String tripId,
  ) =>
      watch(() => DataSnapshot(sortedActivities(children(uid, tripId).values)));

  /// Mirrors the Firestore rules for completed trips and date ranges.
  @override
  Future<void> saveTrip(String uid, Trip trip, {required bool create}) async {
    trip.validate();
    requireValid(
      !(user(uid)[trip.id]?.completed ?? false) || trip.completed,
      'ทริปนี้จบแล้ว กรุณาโหลดข้อมูลใหม่',
    );
    requireValid(
      children(uid, trip.id).values.every(
        (a) =>
            a.date.compareTo(trip.startDate) >= 0 &&
            a.date.compareTo(trip.endDate) <= 0,
      ),
      'มีกิจกรรมนอกช่วงวันใหม่',
    );
    user(uid)[trip.id] = trip;
    _changes.add(null);
  }

  /// Validates and stores an activity.
  @override
  Future<void> saveActivity(
    String uid,
    String tripId,
    TripActivity a, {
    required bool create,
  }) async {
    final t = user(uid)[tripId];
    requireValid(t != null && t.status == 'active', 'ไม่พบทริป');
    a.validate(t!);
    children(uid, tripId)[a.id] = a;
    _changes.add(null);
  }

  /// Rewrites ranks if the items are unchanged.
  @override
  Future<void> reorderActivities(
    String uid,
    String tripId,
    List<TripActivity> ordered,
  ) async {
    requireValid(user(uid)[tripId]?.status == 'active', 'ทริปไม่พร้อมแก้ไข');
    requireValid(
      ordered.isNotEmpty &&
          ordered.length <= 100 &&
          ordered.every((a) => a.date == ordered.first.date),
      'ลำดับไม่ถูกต้อง',
    );
    final items = children(uid, tripId);
    for (final a in ordered) {
      requireValid(
        identical(items[a.id], a),
        'ข้อมูลเปลี่ยนแล้ว กรุณาโหลดใหม่',
      );
    }
    for (var i = 0; i < ordered.length; i++) {
      items[ordered[i].id] = ordered[i].withRank(i * 1000);
    }
    _changes.add(null);
  }

  /// Removes an activity.
  @override
  Future<void> deleteActivity(String uid, String tripId, String id) async {
    children(uid, tripId).remove(id);
    _changes.add(null);
  }

  /// Marks a trip as completed.
  @override
  Future<void> completeTrip(String uid, String tripId) async {
    final old = user(uid)[tripId];
    requireValid(old != null && old.status == 'active', 'ทริปไม่พร้อมแก้ไข');
    if (old!.completed) return;
    old.validate();
    user(uid)[tripId] = Trip.fromFields(
      tripId,
      {...old.fields(), 'completed': true},
      createdAt: old.createdAt,
      updatedAt: old.updatedAt,
    );
    _changes.add(null);
  }

  /// Removes the trip, its activities and its checklist.
  @override
  Future<void> deleteTrip(String uid, String tripId) async {
    await packing.queueCleanup(uid, tripId);
    children(uid, tripId).clear();
    user(uid).remove(tripId);
    await packing.finishCleanup(uid, tripId);
    _changes.add(null);
  }

  /// Finishes local cleanup for trips already removed.
  @override
  Future<void> resumePendingDeletes(String uid) async {
    for (final id in packing.cleanupQueue(uid)) {
      if (!user(uid).containsKey(id)) await packing.finishCleanup(uid, id);
    }
  }
}
