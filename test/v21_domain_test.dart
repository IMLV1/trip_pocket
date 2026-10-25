import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/places/curated_places.dart';
import 'package:trip_pocket/features/places/thailand_boundary.dart';
import 'package:trip_pocket/features/places/navigation_service.dart';
import 'package:trip_pocket/features/sharing/trip_share_formatter.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

const t = Trip(
  id: 't',
  title: 'ทริป',
  destination: 'เชียงใหม่',
  startDate: '2026-11-06',
  endDate: '2026-11-08',
  budgetSatang: 300000,
);
TripActivity stop(
  String id, {
  int time = 540,
  int cost = 10000,
  bool known = true,
  int? rank,
}) => TripActivity(
  id: id,
  title: id,
  date: t.startDate,
  timeMinutes: time,
  estimatedCostSatang: cost,
  costKnown: known,
  latitude: 18.78,
  longitude: 98.98,
  orderIndex: rank,
);
TripActivity leg(
  TripActivity from,
  TripActivity to, {
  int cost = 5000,
  bool known = true,
}) => TripActivity.fromFields(to.id, {
  ...to.fields(),
  'travelMode': 'car',
  'travelFromId': from.id,
  'travelSignature': segmentSignature(from, to),
  'travelCostKnown': known,
  'travelCostSatang': cost,
});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'legacy decoding preserves money and chronological order without migration',
    () {
      final legacy = {
        'title': 'old',
        'date': t.startDate,
        'timeMinutes': 600,
        'estimatedCostSatang': 12345,
        'latitude': 18.78,
        'longitude': 98.98,
        'note': 'private',
      };
      final a = TripActivity.fromFields('old', legacy);
      expect(a.category, 'other');
      expect(a.costKnown, isTrue);
      expect(a.rank, 600000);
      expect(plannedTotal([a]), 12345);
      expect(sortedActivities([a, stop('earlier')]).map((a) => a.id), [
        'earlier',
        'old',
      ]);
      final newer = TripActivity.fromFields(a.id, a.fields());
      expect(newer.estimatedCostSatang, 12345);
      expect(newer.rank, a.rank);
      newer.validate(t);
    },
  );
  test(
    'unknown, explicit free and incoming travel are distinct and never double counted',
    () {
      final a = stop('a'), b = leg(a, stop('b', time: 600));
      final summary = planBudget([a, b]);
      expect(summary.activities, 20000);
      expect(summary.transport, 5000);
      expect(summary.total, 25000);
      expect(summary.unknown, 0);
      final unknown = stop('unknown', cost: 0, known: false, time: 700);
      expect(planBudget([a, b, unknown]).unknown, 2);
      final free = leg(a, stop('free', cost: 0, time: 600), cost: 0);
      expect(planBudget([a, free]).unknown, 0);
      final shared = formatTripShare(t, [a, b, unknown]);
      expect(shared, contains('ยังไม่ทราบราคา'));
      expect(shared, contains('ค่าเดินทางที่ทราบ: 50.00 บาท'));
      expect(shared, isNot(contains('travelSignature')));
    },
  );
  test(
    'moving coordinates, times, day or predecessor invalidates old segment cost',
    () {
      final a = stop('a'), b = leg(a, stop('b', time: 600));
      for (final fields in [
        {'latitude': 19.0},
        {'timeMinutes': 700},
        {'date': '2026-11-07'},
      ]) {
        final changed = TripActivity.fromFields(a.id, {
          ...a.fields(),
          ...fields,
        });
        expect(validSegment(changed, b), isFalse);
        expect(planBudget([changed, b]).transport, 0);
      }
      expect(planBudget([b.withRank(0), a.withRank(1000)]).transport, 0);
      expect(planBudget([stop('new', time: 500), b]).transport, 0);
      expect(planBudget([b]).transport, 0);
    },
  );
  test('category, rank and unknown-price consistency validate', () {
    expect(
      () => TripActivity.fromFields('x', {
        ...stop('x').fields(),
        'costKnown': false,
      }).validate(t),
      throwsStateError,
    );
    expect(
      () => TripActivity.fromFields('x', {
        ...stop('x').fields(),
        'category': 'bad',
      }).validate(t),
      throwsStateError,
    );
    expect(() => stop('x', rank: -1).validate(t), throwsStateError);
  });
  test(
    'offline search filters category and text, uses country metadata and distance reasons',
    () {
      expect(
        suggestPlaces(category: 'all', query: 'ดอยสุเทพ').single.place.id,
        'doi-suthep',
      );
      expect(suggestPlaces(category: 'food', query: 'ดอยสุเทพ'), isEmpty);
      expect(suggestPlaces(category: 'all', query: 'not found'), isEmpty);
      final results = suggestPlaces(category: 'all', anchor: stop('a'));
      expect(results.every((s) => s.place.country == 'TH'), isTrue);
      expect(results.first.reason, contains('ทางตรง'));
    },
  );
  test(
    'bundled polygon accepts Thai cities and islands, rejects neighbors inside broad bbox',
    () async {
      final boundary = await ThailandBoundary.load();
      for (final p in [
        const LatLng(13.7563, 100.5018),
        const LatLng(18.7883, 98.9853),
        const LatLng(7.88, 98.35),
        const LatLng(9.51, 100.01),
      ]) {
        expect(boundary.contains(p), isTrue, reason: p.toString());
      }
      for (final p in [
        const LatLng(17.97, 102.60),
        const LatLng(16.84, 96.17),
        const LatLng(11.56, 104.93),
      ]) {
        expect(boundary.contains(p), isFalse);
      }
      expect(chiangMaiPlaces.every((p) => boundary.contains(p.point)), isTrue);
    },
  );
  test(
    'Maps URL encodes coordinates/mode and browser fallback; both failures surface',
    () async {
      final calls = <LaunchMode>[];
      final service = NavigationService((uri, mode) async {
        calls.add(mode);
        expect(uri.queryParameters['api'], '1');
        expect(uri.queryParameters['destination'], '18.78,98.98');
        return mode == LaunchMode.inAppBrowserView;
      });
      await service.open(stop('a'));
      expect(calls, [
        LaunchMode.externalApplication,
        LaunchMode.inAppBrowserView,
      ]);
      final failing = NavigationService((u, m) async => false);
      await expectLater(failing.open(stop('a')), throwsStateError);
      final transit = TripActivity.fromFields('b', {
        ...stop('b').fields(),
        'travelMode': 'transit',
      });
      expect(
        service.directions(transit).queryParameters['travelmode'],
        'transit',
      );
    },
  );
}
