import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_pocket/features/places/place_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlaceCatalog catalog;
  setUpAll(() async {
    catalog = decodePlaceCatalog(
      await rootBundle.loadString('assets/thailand_pois.json'),
    );
  });
  test(
    'actual bundled OSM data spans all 77 provinces, with stable source links',
    () {
      expect(catalog.places.length, greaterThan(50000));
      expect(catalog.provinces.length, 77);
      expect(
        catalog.places.map((p) => p.id).toSet().length,
        catalog.places.length,
      );
      expect(
        catalog.places.every(
          (p) =>
              p.community &&
              p.country == 'TH' &&
              p.source.startsWith('https://www.openstreetmap.org/'),
        ),
        isTrue,
      );
      for (final province in catalog.provinces) {
        expect(
          catalog.search(province: province, limit: 1).total,
          greaterThan(0),
          reason: province,
        );
      }
    },
  );
  test(
    'search and category filters work outside Chiang Mai in every region',
    () {
      for (final p in [
        'กรุงเทพมหานคร',
        'จังหวัดภูเก็ต',
        'จังหวัดขอนแก่น',
        'จังหวัดเชียงราย',
        'จังหวัดชลบุรี',
        'จังหวัดกาญจนบุรี',
        'จังหวัดนราธิวาส',
      ]) {
        for (final category in ['attraction', 'food', 'lodging']) {
          final results = catalog.search(
            province: p,
            category: category,
            limit: 4,
          );
          expect(results.total, greaterThan(0), reason: '$p/$category');
          expect(
            results.places.every(
              (place) => place.province == p && place.category == category,
            ),
            isTrue,
          );
        }
      }
      expect(
        catalog
            .search(
              query: 'วัดอรุณ',
              province: 'กรุงเทพมหานคร',
              category: 'attraction',
            )
            .total,
        greaterThan(0),
      );
      expect(
        catalog
            .search(
              query: 'พิมาย',
              province: 'จังหวัดนครราชสีมา',
              category: 'attraction',
            )
            .total,
        greaterThan(0),
      );
      expect(
        catalog.search(query: 'ภูเก็ต', category: 'lodging').total,
        greaterThan(100),
      );
      expect(
        catalog.search(query: 'คาเฟ่', province: 'กรุงเทพมหานคร').total,
        greaterThan(0),
      );
    },
  );
  test(
    'district and subdistrict filters narrow food search in every province',
    () {
      final filled = catalog.places
          .where((p) => p.subdistrict.isNotEmpty)
          .length;
      expect(filled / catalog.places.length, greaterThan(.95));
      for (final province in catalog.provinces) {
        final districts = catalog.districtsOf(province);
        expect(districts, isNotEmpty, reason: province);
        final food = catalog.search(province: province, category: 'food');
        final district = food.places.first.district;
        final inDistrict = catalog.search(
          province: province,
          district: district,
          category: 'food',
        );
        expect(inDistrict.total, greaterThan(0));
        expect(inDistrict.total, lessThanOrEqualTo(food.total));
        expect(inDistrict.places.every((p) => p.district == district), isTrue);
        final subdistrict = inDistrict.places.first.subdistrict;
        expect(
          catalog.subdistrictsOf(province, district),
          contains(subdistrict),
        );
        final inSubdistrict = catalog.search(
          province: province,
          district: district,
          subdistrict: subdistrict,
          category: 'food',
        );
        expect(inSubdistrict.total, greaterThan(0));
        expect(inSubdistrict.total, lessThanOrEqualTo(inDistrict.total));
        expect(
          inSubdistrict.places.every((p) => p.subdistrict == subdistrict),
          isTrue,
        );
      }
    },
  );
  test(
    'nation view clusters POIs and a city view caps individual markers honestly',
    () {
      final nation = catalog.window(
        south: 5,
        north: 21,
        west: 97,
        east: 106,
        zoom: 5,
      );
      expect(nation.total, catalog.places.length);
      expect(nation.groups.length, lessThan(300));
      expect(nation.groups.fold<int>(0, (n, g) => n + g.count), nation.total);
      expect(nation.groups.any((g) => g.count > 1), isTrue);
      final city = catalog.window(
        south: 13.70,
        north: 13.80,
        west: 100.45,
        east: 100.60,
        zoom: 14,
      );
      expect(city.total, greaterThan(100));
      expect(city.groups, hasLength(100));
      expect(city.groups.every((g) => g.place != null && g.count == 1), isTrue);
      expect(
        catalog
            .window(south: 35, north: 36, west: 130, east: 131, zoom: 14)
            .total,
        0,
      );
    },
  );
  test(
    'compound Thai/English queries and result limits do not imply full results',
    () {
      final result = catalog.search(
        query: '  PHUKET  ',
        category: 'lodging',
        limit: 7,
      );
      expect(result.total, greaterThan(7));
      expect(result.places, hasLength(7));
      expect(catalog.search(query: 'zzznosuchplace987654321').total, 0);
    },
  );
}
