// Travel data contract used by the screens. Implemented by Firestore for real
// data and by an in-memory class for demo mode and tests.

import 'trip.dart';
import '../../activities/domain/trip_activity.dart';

/// Trip and activity operations used by the screens.
abstract class TravelRepository {
  /// Streams active trips, or trips being deleted when [deleting] is true.
  Stream<DataSnapshot<List<Trip>>> watchTrips(
    String uid, {
    bool deleting = false,
  });

  /// Streams one trip. The value is null if it does not exist.
  Stream<DataSnapshot<Trip?>> watchTrip(String uid, String tripId);

  /// Streams the activities of a trip.
  Stream<DataSnapshot<List<TripActivity>>> watchActivities(
    String uid,
    String tripId,
  );

  /// Creates or updates a trip.
  Future<void> saveTrip(String uid, Trip trip, {required bool create});

  /// Creates or updates an activity.
  Future<void> saveActivity(
    String uid,
    String tripId,
    TripActivity activity, {
    required bool create,
  });

  /// Saves a new stop order for one day.
  Future<void> reorderActivities(
    String uid,
    String tripId,
    List<TripActivity> ordered,
  );

  /// Deletes an activity.
  Future<void> deleteActivity(String uid, String tripId, String activityId);

  /// Marks a trip as completed.
  Future<void> completeTrip(String uid, String tripId);

  /// Deletes a trip and all its activities.
  Future<void> deleteTrip(String uid, String tripId);

  /// Continues any unfinished deletes.
  Future<void> resumePendingDeletes(String uid);
}
