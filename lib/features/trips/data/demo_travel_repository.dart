import 'dart:async';
import '../domain/trip.dart';
import '../domain/travel_repository.dart';
import '../../activities/domain/trip_activity.dart';
import '../../packing/packing_repository.dart';
import '../../../core/validation.dart';

class DemoTravelRepository implements TravelRepository {
  final PackingRepository packing;
  DemoTravelRepository(this.packing);
  final _trips = <String, Map<String, Trip>>{};
  final _activities = <String, Map<String, TripActivity>>{};
  final _changes = StreamController<void>.broadcast();
  Map<String, Trip> user(String u) => _trips.putIfAbsent(u, () => {});
  Map<String, TripActivity> children(String u, String t) =>
      _activities.putIfAbsent('$u/$t', () => {});
  Stream<T> watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

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
  @override
  Stream<DataSnapshot<Trip?>> watchTrip(String uid, String tripId) =>
      watch(() => DataSnapshot(user(uid)[tripId]));
  @override
  Stream<DataSnapshot<List<TripActivity>>> watchActivities(
    String uid,
    String tripId,
  ) =>
      watch(() => DataSnapshot(sortedActivities(children(uid, tripId).values)));
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

  @override
  Future<void> deleteActivity(String uid, String tripId, String id) async {
    children(uid, tripId).remove(id);
    _changes.add(null);
  }

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

  @override
  Future<void> deleteTrip(String uid, String tripId) async {
    await packing.queueCleanup(uid, tripId);
    children(uid, tripId).clear();
    user(uid).remove(tripId);
    await packing.finishCleanup(uid, tripId);
    _changes.add(null);
  }

  @override
  Future<void> resumePendingDeletes(String uid) async {
    for (final id in packing.cleanupQueue(uid)) {
      if (!user(uid).containsKey(id)) await packing.finishCleanup(uid, id);
    }
  }
}
