import 'package:latlong2/latlong.dart';
import '../activities/domain/trip_activity.dart';

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
  String get country => 'TH';
  // Editorial approximate points, not an API geocode or verified entrance.
  LatLng get point => LatLng(latitude, longitude);
}

String placeArea(CuratedPlace p) => [
  p.subdistrict,
  p.district,
  p.province,
].where((e) => e.isNotEmpty).join(' • ');

class ActivitySeed {
  final CuratedPlace? place;
  final LatLng? selectedPoint;
  final String date;
  const ActivitySeed(this.place, this.date) : selectedPoint = null;
  const ActivitySeed.pin(this.selectedPoint, this.date) : place = null;
}

// Legacy curated samples for deterministic regression fixtures; production uses placeCatalogProvider.
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

class PlaceSuggestion {
  final CuratedPlace place;
  final double? distanceKm;
  const PlaceSuggestion(this.place, this.distanceKm);
  String get reason => distanceKm == null
      ? 'หมวดที่เลือก • ชุดเชียงใหม่'
      : 'หมวดที่เลือก • ห่างหมุดล่าสุดประมาณ ${distanceKm!.toStringAsFixed(1)} กม. ทางตรง';
}

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
