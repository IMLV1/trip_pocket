// รวม Riverpod providers กลาง: repository, session, ทริป, กิจกรรม และเช็กลิสต์
// ค่า repository ถูกกำหนดจริงใน main.dart ด้วย override

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_repository.dart';
import '../features/trips/domain/travel_repository.dart';
import '../features/trips/domain/trip.dart';
import '../features/activities/domain/trip_activity.dart';
import '../features/packing/packing_repository.dart';

final modeProvider = Provider<String>((ref) => 'live');
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(),
);
final travelRepositoryProvider = Provider<TravelRepository>(
  (ref) => throw UnimplementedError(),
);
final packingRepositoryProvider = Provider<PackingRepository>(
  (ref) => throw UnimplementedError(),
);
final sessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(authRepositoryProvider).watchSession(),
);
typedef TripKey = ({String uid, String tripId});
final tripsProvider = StreamProvider.autoDispose
    .family<DataSnapshot<List<Trip>>, String>(
      (ref, uid) => ref.watch(travelRepositoryProvider).watchTrips(uid),
    );
final deletingTripsProvider = StreamProvider.autoDispose
    .family<DataSnapshot<List<Trip>>, String>(
      (ref, uid) =>
          ref.watch(travelRepositoryProvider).watchTrips(uid, deleting: true),
    );
final tripProvider = StreamProvider.autoDispose
    .family<DataSnapshot<Trip?>, TripKey>(
      (ref, key) =>
          ref.watch(travelRepositoryProvider).watchTrip(key.uid, key.tripId),
    );
final activitiesProvider = StreamProvider.autoDispose
    .family<DataSnapshot<List<TripActivity>>, TripKey>(
      (ref, key) => ref
          .watch(travelRepositoryProvider)
          .watchActivities(key.uid, key.tripId),
    );
final packingProvider = FutureProvider.autoDispose
    .family<List<PackingItem>, TripKey>(
      (ref, key) =>
          ref.watch(packingRepositoryProvider).load(key.uid, key.tripId),
    );
