// Nationwide offline place catalogue built from OpenStreetMap. Provides list
// search and map windows without any network geocoding API.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'curated_places.dart';

/// Loads the catalogue once, decoding it off the UI isolate.
final placeCatalogProvider = FutureProvider<PlaceCatalog>((ref) async {
  final text = await rootBundle.loadString('assets/thailand_pois.json');
  return compute(decodePlaceCatalog, text);
});

/// Parses and validates the bundled catalogue.
///
/// Throws on an unknown format, a malformed row or a count that does not match
/// the metadata, so a truncated asset cannot pass as complete.
PlaceCatalog decodePlaceCatalog(String text) {
  final data = jsonDecode(text) as Map<String, dynamic>;
  final metadata = data['metadata'] as Map<String, dynamic>;
  if (metadata['format'] != 2 || metadata['country'] != 'TH') {
    throw const FormatException('Unsupported place catalogue');
  }
  final date = (metadata['dataTimestamp'] as String).substring(0, 10);
  final places = (data['places'] as List)
      .map((row) {
        final r = row as List;
        final id = r[0] as String;
        final type = {'n': 'node', 'w': 'way', 'r': 'relation'}[id[0]];
        if (r.length != 9 ||
            type == null ||
            !RegExp(r'^[nwr][0-9]+$').hasMatch(id)) {
          throw const FormatException('Invalid catalogue row');
        }
        final lat = (r[3] as num).toDouble(), lon = (r[4] as num).toDouble();
        if (!lat.isFinite ||
            !lon.isFinite ||
            lat.abs() > 90 ||
            lon.abs() > 180) {
          throw const FormatException('Invalid POI coordinate');
        }
        return CuratedPlace(
          'osm-$id',
          r[1] as String,
          r[2] as String,
          lat,
          lon,
          'https://www.openstreetmap.org/$type/${id.substring(1)}',
          province: (r[5] as String).isEmpty ? 'ประเทศไทย' : r[5] as String,
          aliases: r[6] as String,
          district: r[7] as String,
          subdistrict: r[8] as String,
          checkedAt: date,
          community: true,
        );
      })
      .toList(growable: false);
  if (metadata['count'] != places.length) {
    throw const FormatException('Incomplete place catalogue');
  }
  return PlaceCatalog(places, dataTimestamp: date);
}

/// Lowercases, trims and collapses whitespace.
String normalizePlaceQuery(String text) =>
    text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

/// A page of results and the total before the limit.
class PlaceResults {
  final List<CuratedPlace> places;
  final int total;
  const PlaceResults(this.places, this.total);
}

/// A map marker: one place, or a cluster when [place] is null.
class PoiGroup {
  final LatLng point;
  final int count;
  final CuratedPlace? place;
  const PoiGroup(this.point, this.count, this.place);
}

/// Markers for the visible area and the total match count.
class PoiWindow {
  final List<PoiGroup> groups;
  final int total;
  const PoiWindow(this.groups, this.total);
}

/// Indexed catalogue with text, admin area and spatial lookups.
///
/// Indexes are built once in the constructor, so searching stays fast with tens
/// of thousands of places.
class PlaceCatalog {
  final List<CuratedPlace> places;
  final String dataTimestamp;
  late final List<String> provinces;
  final _districts = <String, Set<String>>{};
  final _subdistricts = <String, Set<String>>{};
  final _text = <String, String>{};
  final _grid = <String, List<CuratedPlace>>{};
  PlaceCatalog(this.places, {this.dataTimestamp = '2026-10-26'}) {
    final names = <String>{};
    for (final p in places) {
      _text[p.id] = normalizePlaceQuery(
        '${p.name} ${p.province} ${p.district} ${p.subdistrict} ${p.aliases}',
      );
      names.add(p.province);
      if (p.district.isNotEmpty) {
        _districts.putIfAbsent(p.province, () => {}).add(p.district);
        if (p.subdistrict.isNotEmpty) {
          _subdistricts
              .putIfAbsent('${p.province}/${p.district}', () => {})
              .add(p.subdistrict);
        }
      }
      _grid.putIfAbsent(_cell(p.latitude, p.longitude), () => []).add(p);
    }
    provinces = names.where((p) => p != 'ประเทศไทย').toList()..sort();
  }

  /// Districts of [province], sorted.
  List<String> districtsOf(String province) =>
      (_districts[province]?.toList() ?? <String>[])..sort();

  /// Subdistricts of [district], sorted.
  List<String> subdistrictsOf(String province, String district) =>
      (_subdistricts['$province/$district']?.toList() ?? <String>[])..sort();

  /// Spatial grid key, 0.25 degrees per cell.
  String _cell(double lat, double lon) =>
      '${(lat * 4).floor()}/${(lon * 4).floor()}';

  /// Whether [p] passes every filter and contains every token.
  bool _matches(
    CuratedPlace p,
    String category,
    String province,
    String district,
    String subdistrict,
    List<String> tokens,
  ) =>
      (category == 'all' || p.category == category) &&
      (province.isEmpty || p.province == province) &&
      (district.isEmpty || p.district == district) &&
      (subdistrict.isEmpty || p.subdistrict == subdistrict) &&
      tokens.every((t) => _text[p.id]!.contains(t));

  /// Searches for list views, sorted by distance from [near] or by name.
  ///
  /// Distances are approximate and precomputed, which is enough for ranking.
  /// Returns at most [limit] places plus the full match count.
  PlaceResults search({
    String query = '',
    String category = 'all',
    String province = '',
    String district = '',
    String subdistrict = '',
    LatLng? near,
    int limit = 100,
  }) {
    final normalized = normalizePlaceQuery(query);
    final tokens = normalized.isEmpty ? <String>[] : normalized.split(' ');
    final matches = places
        .where(
          (p) => _matches(p, category, province, district, subdistrict, tokens),
        )
        .toList();
    if (near != null) {
      // Rank a shortlist without recomputing haversine distances inside sort.
      final weights = {
        for (final p in matches)
          p.id:
              math.pow(p.latitude - near.latitude, 2) +
              math.pow(
                (p.longitude - near.longitude) *
                    math.cos(near.latitude * math.pi / 180),
                2,
              ),
      };
      matches.sort((a, b) {
        final d = weights[a.id]!.compareTo(weights[b.id]!);
        return d != 0 ? d : a.id.compareTo(b.id);
      });
    } else {
      // Leading quotes in community names would otherwise sort first.
      String sortName(CuratedPlace p) =>
          p.name.replaceFirst(RegExp(r'''^["'“‘(\[]+'''), '');
      matches.sort((a, b) {
        final d = sortName(a).compareTo(sortName(b));
        return d != 0 ? d : a.id.compareTo(b.id);
      });
    }
    return PlaceResults(
      matches.take(limit).toList(growable: false),
      matches.length,
    );
  }

  /// Returns the markers for the visible area.
  ///
  /// From zoom 12 it shows up to 100 places nearest the center. Below that it
  /// clusters into cells wider than a marker so they do not overlap.
  PoiWindow window({
    required double south,
    required double north,
    required double west,
    required double east,
    required double zoom,
    String category = 'all',
    String province = '',
    String district = '',
    String subdistrict = '',
    String query = '',
  }) {
    final normalized = normalizePlaceQuery(query);
    final tokens = normalized.isEmpty ? <String>[] : normalized.split(' ');
    final matches = <CuratedPlace>[];
    for (final entry in _grid.entries) {
      final cell = entry.key.split('/').map(int.parse).toList();
      if ((cell[0] + 1) / 4 < south ||
          cell[0] / 4 > north ||
          (cell[1] + 1) / 4 < west ||
          cell[1] / 4 > east) {
        continue;
      }
      for (final p in entry.value) {
        if (p.latitude >= south &&
            p.latitude <= north &&
            p.longitude >= west &&
            p.longitude <= east &&
            _matches(p, category, province, district, subdistrict, tokens)) {
          matches.add(p);
        }
      }
    }
    if (zoom >= 12) {
      final lat = (north + south) / 2, lon = (east + west) / 2;
      matches.sort(
        (a, b) =>
            (math.pow(a.latitude - lat, 2) + math.pow(a.longitude - lon, 2))
                .compareTo(
                  math.pow(b.latitude - lat, 2) +
                      math.pow(b.longitude - lon, 2),
                ),
      );
      return PoiWindow(
        matches.take(100).map((p) => PoiGroup(p.point, 1, p)).toList(),
        matches.length,
      );
    }
    // About 58 logical px per cell, wider than the 48 px cluster marker.
    final size = math.pow(2, 10 - zoom).toDouble() * .08;
    final cells = <String, List<CuratedPlace>>{};
    for (final p in matches) {
      cells
          .putIfAbsent(
            '${(p.latitude / size).floor()}/${(p.longitude / size).floor()}',
            () => [],
          )
          .add(p);
    }
    final groups = cells.values.map((items) {
      if (items.length == 1) return PoiGroup(items.first.point, 1, items.first);
      return PoiGroup(
        LatLng(
          items.fold<double>(0, (n, p) => n + p.latitude) / items.length,
          items.fold<double>(0, (n, p) => n + p.longitude) / items.length,
        ),
        items.length,
        null,
      );
    }).toList();
    return PoiWindow(groups, matches.length);
  }
}
