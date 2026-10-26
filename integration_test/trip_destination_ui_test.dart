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
import 'package:trip_pocket/features/places/destination_preview.dart';
import 'package:trip_pocket/features/places/daily_map.dart';
import 'package:trip_pocket/features/places/place_catalog.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'trip destination search, confirmed pin, cancel, edit and clear preserve itinerary budget',
    (tester) async {
      final packing = PackingRepository(await SharedPreferences.getInstance());
      final repo = DemoTravelRepository(packing);
      final container = ProviderContainer(
        overrides: [
          modeProvider.overrideWithValue('demo'),
          packingRepositoryProvider.overrideWithValue(packing),
          travelRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      final catalog = await container.read(placeCatalogProvider.future);
      final place = catalog
          .search(
            query: 'วัดอรุณ',
            category: 'attraction',
            province: 'กรุงเทพมหานคร',
          )
          .places
          .first;
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const SessionApp(uid: 'trip-pin-test'),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tapKey(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('สร้างทริป'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trip-title')),
        'กรุงเทพ วันพักผ่อน',
      );
      await tapKey('search-destination');
      await tester.enterText(find.byKey(const Key('place-search')), 'วัดอรุณ');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey('recommend-${place.id}');
      await tapKey('choose-poi');
      await tapKey('confirm-place');
      expect(
        tester
            .widget<DestinationPreview>(find.byType(DestinationPreview))
            .point,
        place.point,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('destination-preview')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('trip-destination-form');
      await tester.enterText(find.byKey(const Key('budget')), '2500');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey('save-trip');
      var t = (await repo.watchTrips('trip-pin-test').first).value.single;
      expect(t.destinationLatitude, place.latitude);
      expect(t.destinationLongitude, place.longitude);
      expect(t.destination, place.name);
      expect(t.budgetSatang, 250000);
      expect(
        (await repo.watchActivities('trip-pin-test', t.id).first).value,
        isEmpty,
      );
      await tester.tap(find.text(t.title));
      await tester.pumpAndSettle();
      expect(find.byType(DestinationPreview), findsOneWidget);
      await tapKey('tab-map');
      final map = tester.widget<DailyMap>(find.byType(DailyMap));
      expect(map.destination, place.point);
      expect(map.activities, isEmpty);
      await tester.ensureVisible(find.byType(DailyMap));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ดูจุดหมายทั้งหมด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ดูจุดหมายทั้งหมด'));
      await tester.pumpAndSettle();
      final camera = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .camera;
      expect(camera.center.latitude, closeTo(place.latitude, .0001));
      expect(camera.center.longitude, closeTo(place.longitude, .0001));
      await tester.ensureVisible(find.byType(DailyMap));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('trip-destination-map');
      Future<void> edit() async {
        await tester.tap(find.byTooltip('จัดการทริป'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แก้ไขทริป'));
        await tester.pumpAndSettle();
      }

      await edit();
      expect(
        tester
            .widget<DestinationPreview>(find.byType(DestinationPreview))
            .point,
        place.point,
      );
      await tapKey('pick-destination');
      final rect = tester.getRect(find.byType(FlutterMap).last);
      await tester.tapAt(rect.center + const Offset(25, 20));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DestinationPreview>(find.byType(DestinationPreview))
            .point,
        place.point,
      );
      await tapKey('pick-destination');
      final rect2 = tester.getRect(find.byType(FlutterMap).last);
      await tester.tapAt(rect2.center + const Offset(25, 20));
      await tester.pumpAndSettle();
      await tapKey('confirm-place');
      final changed = tester
          .widget<DestinationPreview>(find.byType(DestinationPreview))
          .point;
      expect(changed, isNot(place.point));
      await tapKey('save-trip');
      t = (await repo.watchTrip('trip-pin-test', t.id).first).value!;
      expect(t.destinationLatitude, changed.latitude);
      expect(t.destinationLongitude, changed.longitude);
      await edit();
      await tapKey('clear-destination-pin');
      await tapKey('save-trip');
      t = (await repo.watchTrip('trip-pin-test', t.id).first).value!;
      expect(t.hasDestinationPin, isFalse);
      expect(t.budgetSatang, 250000);
      expect(
        (await repo.watchActivities('trip-pin-test', t.id).first).value,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await repo.deleteTrip('trip-pin-test', t.id);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
