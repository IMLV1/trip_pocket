import 'package:trip_pocket/features/activities/presentation/activity_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/places/curated_places.dart';
import 'package:trip_pocket/features/places/daily_map.dart';
import 'package:trip_pocket/features/places/day_plan.dart';
import 'package:trip_pocket/features/places/recommendations_sheet.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

const trip = Trip(
  id: 't',
  title: 'test',
  destination: 'เชียงใหม่',
  startDate: '2026-11-06',
  endDate: '2026-11-08',
  budgetSatang: 300000,
);
const a = TripActivity(
  id: 'a',
  title: 'วัด',
  date: '2026-11-06',
  timeMinutes: 540,
  estimatedCostSatang: 10000,
  latitude: 18.78,
  longitude: 98.98,
  category: 'attraction',
);
const b = TripActivity(
  id: 'b',
  title: 'อาหาร',
  date: '2026-11-06',
  timeMinutes: 600,
  estimatedCostSatang: 20000,
  latitude: 18.79,
  longitude: 98.99,
  category: 'food',
);
void main() {
  testWidgets(
    'replacing an existing stop via search clears old price and requires a new pin confirmation',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActivityEditor(uid: 'u', trip: trip, initial: a),
          ),
        ),
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('activity-cost')))
            .controller!
            .text,
        '100.00',
      );
      await tester.tap(find.byKey(const Key('search-place')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('place-search')), 'Jasmine');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('recommend-jasmine')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recommend-jasmine')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('activity-cost')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        find.byKey(const ValueKey('activity-category-food')),
        findsOneWidget,
      );
      expect(find.text('เลือกตำแหน่งบนแผนที่'), findsOneWidget);
    },
  );
  testWidgets(
    'search is offline, respects category, and selection does not save a trip',
    (tester) async {
      CuratedPlace? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  chosen = await showModalBottomSheet<CuratedPlace>(
                    context: context,
                    isScrollControlled: true,
                    builder: (c) =>
                        const RecommendationsSheet(remaining: 10000),
                  );
                },
                child: const Text('ค้นหา'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ค้นหา'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('place-search')), 'ดอยสุเทพ');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recommend-doi-suthep')), findsOneWidget);
      expect(find.byKey(const Key('recommend-phra-singh')), findsNothing);
      expect(chosen, isNull);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('recommend-doi-suthep')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recommend-doi-suthep')));
      await tester.pumpAndSettle();
      expect(chosen?.id, 'doi-suthep');
    },
  );
  testWidgets(
    'rank changes keep numbered map and list consistent, with delete persistence',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final packing = PackingRepository(await SharedPreferences.getInstance());
      final repo = DemoTravelRepository(packing);
      await repo.saveTrip('u', trip, create: true);
      await repo.saveActivity('u', 't', a, create: true);
      await repo.saveActivity('u', 't', b, create: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [travelRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: StreamBuilder(
                stream: repo.watchActivities('u', 't'),
                builder: (c, s) => s.hasData
                    ? SingleChildScrollView(
                        child: DayPlan(
                          uid: 'u',
                          trip: trip,
                          activities: s.data!.value,
                          onDelete: (a) => repo.deleteActivity('u', 't', a.id),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DailyMap>(find.byType(DailyMap))
            .activities
            .map((a) => a.id),
        ['a', 'b'],
      );
      await tester.ensureVisible(find.byKey(const Key('up-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('up-b')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DailyMap>(find.byType(DailyMap))
            .activities
            .map((a) => a.id),
        ['b', 'a'],
      );
      expect(
        (await repo.watchActivities('u', 't').first).value.map((a) => a.id),
        ['b', 'a'],
      );
      await repo.deleteActivity('u', 't', 'b');
      await tester.pumpAndSettle();
      expect(
        tester.widget<DailyMap>(find.byType(DailyMap)).activities.single.id,
        'a',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'travel editor preserves unknown versus confirmed zero on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TripActivity? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<TripActivity>(
                    context: c,
                    isScrollControlled: true,
                    builder: (c) => const TravelEditor(from: a, to: b),
                  );
                },
                child: const Text('เดินทาง'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('เดินทาง'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('travel-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เดิน').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('travel-cost')), '0');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('save-travel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-travel')));
      await tester.pumpAndSettle();
      expect(result?.travelCostKnown, isTrue);
      expect(result?.travelCostSatang, 0);
      expect(result?.travelMode, 'walk');
      expect(validSegment(a, result!), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
