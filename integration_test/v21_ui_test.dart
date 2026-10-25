import 'package:trip_pocket/features/places/place_catalog.dart';
import 'package:trip_pocket/features/places/curated_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/app.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/auth/auth_repository.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/places/daily_map.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'V2.1 Android multi-stop search, map selection, order, costs and deletion',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final packing = PackingRepository(prefs),
          repo = DemoTravelRepository(PackingRepository(prefs));
      const uid = 'v21-ui';
      const trip = Trip(
        id: 'v21-ui',
        title: 'เชียงใหม่ V2.1',
        destination: 'เชียงใหม่',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 300000,
      );
      const a = TripActivity(
        id: 'a',
        title: 'วัดพระสิงห์',
        date: '2026-11-06',
        timeMinutes: 540,
        estimatedCostSatang: 10000,
        latitude: 18.7885,
        longitude: 98.9814,
        category: 'attraction',
      );
      const b = TripActivity(
        id: 'b',
        title: 'อาหารกลางวัน',
        date: '2026-11-06',
        timeMinutes: 600,
        estimatedCostSatang: 20000,
        latitude: 18.79,
        longitude: 98.99,
        category: 'food',
      );
      await repo.saveTrip(uid, trip, create: true);
      await repo.saveActivity(uid, trip.id, a, create: true);
      await repo.saveActivity(uid, trip.id, b, create: true);
      runApp(
        ProviderScope(
          overrides: [
            placeCatalogProvider.overrideWith(
              (ref) async => PlaceCatalog(chiangMaiPlaces),
            ),
            modeProvider.overrideWithValue('demo'),
            travelRepositoryProvider.overrideWithValue(repo),
            packingRepositoryProvider.overrideWithValue(packing),
            authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
          ],
          child: const SessionApp(uid: uid),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(trip.title));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      Future<void> tapKey(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      expect(
        tester
            .widget<DailyMap>(find.byType(DailyMap))
            .activities
            .map((a) => a.id),
        ['a', 'b'],
      );
      await tester.ensureVisible(find.byType(DailyMap));
      await tester.pumpAndSettle();
      for (var i = 0; i < 20; i++) {
        final loaded = tester
            .widgetList<RawImage>(
              find.descendant(
                of: find.byType(FlutterMap),
                matching: find.byType(RawImage),
              ),
            )
            .where((w) => w.image != null)
            .length;
        if (loaded > 0) break;
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        tester
            .widgetList<RawImage>(
              find.descendant(
                of: find.byType(FlutterMap),
                matching: find.byType(RawImage),
              ),
            )
            .any((w) => w.image != null),
        isTrue,
        reason: 'Real map tiles must render',
      );
      await tester.pump(const Duration(seconds: 1));
      await binding.takeScreenshot('v21-daily-map');
      await tapKey('travel-b');
      await tester.tap(find.byKey(const Key('travel-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('รถยนต์').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('travel-cost')), '50');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey('save-travel');
      var stops = (await repo.watchActivities(uid, trip.id).first).value;
      expect(planBudget(stops).transport, 5000);
      expect(plannedTotal(stops), 35000);
      await tapKey('up-b');
      stops = (await repo.watchActivities(uid, trip.id).first).value;
      expect(stops.map((a) => a.id), ['b', 'a']);
      expect(planBudget(stops).transport, 0);
      expect(
        tester
            .widget<DailyMap>(find.byType(DailyMap))
            .activities
            .map((a) => a.id),
        ['b', 'a'],
      );
      await tapKey('recommend-places');
      await tester.enterText(find.byKey(const Key('place-search')), 'ดอยสุเทพ');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('v21-place-search');
      await tapKey('recommend-doi-suthep');
      await tapKey('choose-poi');
      expect(find.text('วัดพระธาตุดอยสุเทพ'), findsOneWidget);
      await tapKey('pick-place');
      await tapKey('confirm-place');
      await tapKey('save-activity');
      stops = (await repo.watchActivities(uid, trip.id).first).value;
      expect(stops, hasLength(3));
      expect(stops.last.category, 'attraction');
      expect(stops.last.costKnown, isFalse);
      expect(planBudget(stops).unknown, 3);
      // Tap a free area on the real map and explicitly confirm another destination.
      await tester.ensureVisible(find.byType(DailyMap));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(FlutterMap));
      await tester.tapAt(rect.center + const Offset(60, 35));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เพิ่มจุดหมายที่นี่'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('activity-title')),
        'จุดแวะเพิ่ม',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey('save-activity');
      stops = (await repo.watchActivities(uid, trip.id).first).value;
      expect(stops, hasLength(4));
      expect(stops.last.title, 'จุดแวะเพิ่ม');
      final added = stops.last;
      await repo.deleteActivity(uid, trip.id, added.id);
      await tester.pumpAndSettle();
      expect(
        tester.widget<DailyMap>(find.byType(DailyMap)).activities,
        hasLength(3),
      );
      await tester.ensureVisible(find.text('แชร์แผนเที่ยว'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แชร์แผนเที่ยว'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('ยังไม่ทราบราคา'),
      );
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(
        (await repo.watchActivities('other', trip.id).first).value,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await repo.deleteTrip(uid, trip.id);
    },
  );
}
