// Place model, activity form seeds and legacy test fixtures. Production data
// comes from place_catalog.dart, not the Chiang Mai list here.

import 'package:latlong2/latlong.dart';
import '../activities/domain/trip_activity.dart';

/// A named place from the catalogue or a test fixture.
class CuratedPlace {
  final String id, name, category, source;
  final double latitude, longitude;
  final String province, district, subdistrict, checkedAt, aliases;
  final bool community;
  const CuratedPlace(
    this.id,
    this.name,
    this.category,
    this.latitude,
    this.longitude,
    this.source, {
    this.province = 'เชียงใหม่',
    this.district = '',
    this.subdistrict = '',
    this.checkedAt = '2026-10-26',
    this.aliases = '',
    this.community = false,
  });

  /// Country code of the data.
  String get country => 'TH';
  // Editorial approximate points, not an API geocode or verified entrance.
  /// Coordinates of the place.
  LatLng get point => LatLng(latitude, longitude);
}

/// Joins subdistrict, district and province for display.
String placeArea(CuratedPlace p) => [
  p.subdistrict,
  p.district,
  p.province,
].where((e) => e.isNotEmpty).join(' • ');

/// Initial values for the activity form.
class ActivitySeed {
  final CuratedPlace? place;
  final LatLng? selectedPoint;
  final String date;

  /// Starts from a place. The pin still needs confirming in the form.
  const ActivitySeed(this.place, this.date) : selectedPoint = null;

  /// Starts from a point tapped on the map.
  const ActivitySeed.pin(this.selectedPoint, this.date) : place = null;
}

// Legacy curated samples for deterministic regression fixtures; production uses placeCatalogProvider.
/// Fixture data for regression tests. Not used in production.
const chiangMaiPlaces = <CuratedPlace>[
  CuratedPlace(
    'phra-singh',
    'วัดพระสิงห์วรมหาวิหาร',
    'attraction',
    18.7885,
    98.9814,
    'https://thai.tourismthailand.org/Attraction/วัดพระสิงห์วรมหาวิหาร',
  ),
  CuratedPlace(
    'doi-suthep',
    'วัดพระธาตุดอยสุเทพ',
    'attraction',
    18.8049,
    98.9216,
    'https://www.tourismthailand.org/Attraction/wat-phra-that-doi-suthep',
  ),
  CuratedPlace(
    'jasmine',
    'Jasmine • Dusit Princess Chiang Mai',
    'food',
    18.7828,
    98.9993,
    'https://www.dusit.com/dusitprincess-chiangmai/',
  ),
  CuratedPlace(
    'dusit-princess',
    'Dusit Princess Chiang Mai',
    'lodging',
    18.7828,
    98.9993,
    'https://www.dusit.com/dusitprincess-chiangmai/',
  ),
];

/// A fixture place with its distance from an anchor.
class PlaceSuggestion {
  final CuratedPlace place;
  final double? distanceKm;
  const PlaceSuggestion(this.place, this.distanceKm);

  /// Explains why this place was suggested.
  String get reason => distanceKm == null
      ? 'หมวดที่เลือก • ชุดเชียงใหม่'
      : 'หมวดที่เลือก • ห่างหมุดล่าสุดประมาณ ${distanceKm!.toStringAsFixed(1)} กม. ทางตรง';
}

/// Searches the fixture list. Used only by tests.
List<PlaceSuggestion> suggestPlaces({
  required String category,
  TripActivity? anchor,
  String query = '',
}) {
  final values = chiangMaiPlaces
      .where(
        (p) =>
            (category == 'all' || p.category == category) &&
            '${p.name} ${p.province} ${activityCategories[p.category]}'
                .toLowerCase()
                .contains(query.trim().toLowerCase()),
      )
      .map(
        (p) => PlaceSuggestion(
          p,
          anchor == null
              ? null
              : const Distance().as(
                  LengthUnit.Kilometer,
                  LatLng(anchor.latitude, anchor.longitude),
                  p.point,
                ),
        ),
      )
      .toList();
  values.sort((a, b) {
    final d = (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0);
    return d != 0 ? d : a.place.id.compareTo(b.place.id);
  });
  return values;
}
