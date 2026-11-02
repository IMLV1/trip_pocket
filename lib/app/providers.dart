// Shared Riverpod providers. Repositories are placeholders overridden in
// bootstrap; the stream providers auto-dispose so closed screens stop
// listening.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_repository.dart';
import '../features/trips/domain/travel_repository.dart';
import '../features/trips/domain/trip.dart';
import '../features/activities/domain/trip_activity.dart';
import '../features/packing/packing_repository.dart';

/// Run mode: `live`, `emulator` or `demo`.
final modeProvider = Provider<String>((ref) => 'live');

/// Must be overridden in `bootstrap`.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(),
);

/// Must be overridden in `bootstrap`.
final travelRepositoryProvider = Provider<TravelRepository>(
  (ref) => throw UnimplementedError(),
);

/// Must be overridden in `bootstrap`.
final packingRepositoryProvider = Provider<PackingStore>(
  (ref) => throw UnimplementedError(),
);

/// Current session, or null when signed out.
final sessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(authRepositoryProvider).watchSession(),
);

/// Identifies a trip within an account.
typedef TripKey = ({String uid, String tripId});

/// Active trips of an account.
final tripsProvider = StreamProvider.autoDispose
    .family<DataSnapshot<List<Trip>>, String>(
      (ref, uid) => ref.watch(travelRepositoryProvider).watchTrips(uid),
    );

/// Trips still being deleted.
final deletingTripsProvider = StreamProvider.autoDispose
    .family<DataSnapshot<List<Trip>>, String>(
      (ref, uid) =>
          ref.watch(travelRepositoryProvider).watchTrips(uid, deleting: true),
    );

/// A single trip.
final tripProvider = StreamProvider.autoDispose
    .family<DataSnapshot<Trip?>, TripKey>(
      (ref, key) =>
          ref.watch(travelRepositoryProvider).watchTrip(key.uid, key.tripId),
    );

/// Activities of a trip.
final activitiesProvider = StreamProvider.autoDispose
    .family<DataSnapshot<List<TripActivity>>, TripKey>(
      (ref, key) => ref
          .watch(travelRepositoryProvider)
          .watchActivities(key.uid, key.tripId),
    );

/// Packing checklist of a trip.
final packingProvider = FutureProvider.autoDispose
    .family<List<PackingItem>, TripKey>(
      (ref, key) =>
          ref.watch(packingRepositoryProvider).load(key.uid, key.tripId),
    );
