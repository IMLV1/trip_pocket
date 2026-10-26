import 'package:flutter_test/flutter_test.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/sharing/trip_share_formatter.dart';

void main() {
  final legacy = <String, dynamic>{
    'title': 'เชียงใหม่',
    'destination': 'เชียงใหม่',
    'startDate': '2026-11-06',
    'endDate': '2026-11-08',
    'budgetSatang': 300000,
    'status': 'active',
  };
  test('legacy trip has no invented destination and preserves budget', () {
    final t = Trip.fromFields('t', legacy);
    t.validate();
    expect(t.hasDestinationPin, isFalse);
    expect(t.budgetSatang, 300000);
    expect(t.fields()['destinationLatitude'], isNull);
  });
  test(
    'trip destination round trips and never enters shared coordinates or activity budget',
    () {
      final t = Trip.fromFields('t', {
        ...legacy,
        'destinationLatitude': 18.78,
        'destinationLongitude': 98.98,
      });
      t.validate();
      expect(Trip.fromFields('t', t.fields()).destinationLatitude, 18.78);
      expect(t.hasDestinationPin, isTrue);
      expect(planBudget([]).total, 0);
      final shared = formatTripShare(t, []);
      expect(shared, isNot(contains('18.78')));
      expect(shared, isNot(contains('98.98')));
      expect(shared, contains('เชียงใหม่'));
    },
  );
  test('destination coordinates require a finite complete pair', () {
    for (final pair in [
      [18.78, null],
      [null, 98.98],
      [91.0, 98.98],
      [18.78, -181.0],
      [double.nan, 98.98],
      [18.78, double.infinity],
    ]) {
      final t = Trip.fromFields('t', {
        ...legacy,
        'destinationLatitude': pair[0],
        'destinationLongitude': pair[1],
      });
      expect(t.validate, throwsA(isA<StateError>()));
    }
  });
}
