import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/app.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/auth/auth_repository.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/places/daily_map.dart';
import 'package:trip_pocket/features/places/place_catalog.dart';
import 'package:trip_pocket/features/places/poi_map_layer.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'actual nationwide catalogue: Bangkok map selection and Phuket search save multiple destinations',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final packing = PackingRepository(prefs),
          repo = DemoTravelRepository(PackingRepository(prefs));
      const trip = Trip(
        id: 'nationwide-ui',
        title: 'ทดสอบค้นทั่วไทย',
        destination: 'ประเทศไทย',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 300000,
      );
      await repo.saveTrip('nation-test', trip, create: true);
      final container = ProviderContainer(
        overrides: [
          modeProvider.overrideWithValue('demo'),
          travelRepositoryProvider.overrideWithValue(repo),
          packingRepositoryProvider.overrideWithValue(packing),
          authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      // Use the production loader and actual asset, not a fake catalogue.
      final catalogue = await container.read(placeCatalogProvider.future);
      expect(catalogue.provinces, hasLength(77));
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const SessionApp(key: ValueKey('ux-login'), uid: null),
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('ux-login');
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const SessionApp(uid: 'nation-test'),
        ),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('ux-trip-list');
      await tester.tap(find.text(trip.title));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('ux-plan');
      await tester.tap(find.byKey(const Key('tab-map')));
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();

      final wat = catalogue
          .search(
            query: 'วัดอรุณ',
            province: 'กรุงเทพมหานคร',
            category: 'attraction',
          )
          .places
          .first;
      await tester.ensureVisible(find.byType(DailyMap));
      await tester.pumpAndSettle();
      tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .move(wat.point, 16);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(PoiMapLayer), findsOneWidget);
      // The layer debounces viewport updates independently of Flutter animations.
      for (
        var n = 0;
        n < 15 && find.bySemanticsLabel('แนะนำ ${wat.name}').evaluate().isEmpty;
        n++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.bySemanticsLabel('แนะนำ ${wat.name}'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await binding.takeScreenshot('ux-nationwide-map');
      await tester.tap(find.bySemanticsLabel('แนะนำ ${wat.name}'));
      await tester.pumpAndSettle();
      expect(find.text(wat.name), findsOneWidget);
      await tester.tap(find.byKey(const Key('choose-poi')));
      await tester.pumpAndSettle();
      Future<void> tapKey(String key) async {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tapKey('pick-place');
      await tapKey('confirm-place');
      await tapKey('save-activity');
      var stops =
          (await repo.watchActivities('nation-test', trip.id).first).value;
      expect(stops.single.title, wat.name);
      expect(stops.single.costKnown, isFalse);
      await tapKey('recommend-places');
      await tester.enterText(find.byKey(const Key('place-search')), 'ป่าตอง');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.textContaining('พบ '), findsWidgets);
      await tester.pump(const Duration(milliseconds: 300));
      await binding.takeScreenshot('ux-nationwide-search');
      final hotel = catalogue.search(query: 'ป่าตอง').places.first;
      final listState = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('place-results')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      // Scroll by list position so the test does not pan the embedded map.
      listState.position.jumpTo(0);
      await tester.pumpAndSettle();
      final target = find.byKey(ValueKey('recommend-${hotel.id}'));
      for (var n = 0; n < 20 && target.evaluate().isEmpty; n++) {
        listState.position.jumpTo(
          (listState.position.pixels + 120).clamp(
            0,
            listState.position.maxScrollExtent,
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-poi')));
      await tester.pumpAndSettle();
      await tapKey('pick-place');
      await tapKey('confirm-place');
      await tapKey('save-activity');
      stops = (await repo.watchActivities('nation-test', trip.id).first).value;
      expect(stops, hasLength(2));
      expect(stops.map((a) => a.title), contains(hotel.name));
      expect(hotel.province, 'จังหวัดภูเก็ต');
      expect(stops.every((a) => !a.costKnown), isTrue);
      await tapKey('tab-plan');
      // A saved destination remains editable through the visible pencil action.
      await tapKey('edit-${stops.first.id}');
      await tester.enterText(
        find.byKey(const Key('activity-title')),
        '${wat.name} (ช่วงเช้า)',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey('save-activity');
      stops = (await repo.watchActivities('nation-test', trip.id).first).value;
      expect(stops, hasLength(2));
      expect(stops.first.title, '${wat.name} (ช่วงเช้า)');
      await tapKey('tab-packing');
      await tester.enterText(
        find.byKey(const Key('packing-text')),
        'กระเป๋าเดินทาง',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey('packing-add');
      expect(find.text('กระเป๋าเดินทาง'), findsOneWidget);
      await binding.takeScreenshot('ux-packing');
      await tapKey('tab-plan');
      await tapKey('tab-packing');
      expect(find.text('กระเป๋าเดินทาง'), findsOneWidget);
      await tapKey('tab-plan');

      expect(tester.takeException(), isNull);
      await repo.deleteTrip('nation-test', trip.id);
      semantics.dispose();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
