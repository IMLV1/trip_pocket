import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_pocket/features/places/curated_places.dart';
import 'package:trip_pocket/features/places/place_catalog.dart';
import 'package:trip_pocket/features/places/poi_map_layer.dart';

const place = CuratedPlace(
  'bangkok-food',
  'อาหารทดสอบกรุงเทพ',
  'food',
  13.75,
  100.5,
  'https://www.openstreetmap.org',
  province: 'กรุงเทพมหานคร',
  community: true,
);
const second = CuratedPlace(
  'bangkok-hotel',
  'ที่พักทดสอบกรุงเทพ',
  'lodging',
  13.7501,
  100.5001,
  'https://www.openstreetmap.org',
  province: 'กรุงเทพมหานคร',
  community: true,
);

void main() {
  testWidgets(
    'recommended POI is visible and selectable separately from trip stops',
    (tester) async {
      final semantics = tester.ensureSemantics();

      CuratedPlace? selected;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            placeCatalogProvider.overrideWith(
              (ref) async => PlaceCatalog([place]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(13.75, 100.5),
                  initialZoom: 15,
                ),
                children: [PoiMapLayer(onSelected: (p) => selected = p)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('แนะนำ อาหารทดสอบกรุงเทพ'), findsOneWidget);
      expect(selected, isNull);
      await tester.tap(find.bySemanticsLabel('แนะนำ อาหารทดสอบกรุงเทพ'));
      await tester.pump();
      expect(selected?.id, place.id);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
  testWidgets(
    'a clustered map zooms on tap and does not select a fake destination',
    (tester) async {
      final semantics = tester.ensureSemantics();

      final controller = MapController();
      addTearDown(controller.dispose);
      CuratedPlace? selected;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            placeCatalogProvider.overrideWith(
              (ref) async => PlaceCatalog([place, second]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                mapController: controller,
                options: const MapOptions(
                  initialCenter: LatLng(13.75, 100.5),
                  initialZoom: 5,
                ),
                children: [PoiMapLayer(onSelected: (p) => selected = p)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('2 สถานที่แนะนำ ซูมดู')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.camera.zoom, greaterThan(5));
      expect(selected, isNull);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
}
