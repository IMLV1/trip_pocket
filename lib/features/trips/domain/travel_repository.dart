import 'trip.dart';
import '../../activities/domain/trip_activity.dart';

abstract class TravelRepository {
  Stream<DataSnapshot<List<Trip>>> watchTrips(
    String uid, {
    bool deleting = false,
  });
  Stream<DataSnapshot<Trip?>> watchTrip(String uid, String tripId);
  Stream<DataSnapshot<List<TripActivity>>> watchActivities(
    String uid,
    String tripId,
  );
  Future<void> saveTrip(String uid, Trip trip, {required bool create});
  Future<void> saveActivity(
    String uid,
    String tripId,
    TripActivity activity, {
    required bool create,
  });
  Future<void> reorderActivities(
    String uid,
    String tripId,
    List<TripActivity> ordered,
  );
  Future<void> deleteActivity(String uid, String tripId, String activityId);
  Future<void> deleteTrip(String uid, String tripId);
  Future<void> resumePendingDeletes(String uid);
}
