import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Approximate admin boundary, not a legal/survey boundary or full coastline.
class ThailandBoundary {
  final List<dynamic> polygons;
  ThailandBoundary(this.polygons);
  static Future<ThailandBoundary>? _cached;
  static Future<ThailandBoundary> load() =>
      _cached ??= rootBundle.loadString('assets/thailand.geojson').then((s) {
        final g = jsonDecode(s)['geometry'];
        return ThailandBoundary(
          g['type'] == 'Polygon' ? [g['coordinates']] : g['coordinates'],
        );
      });
  bool contains(LatLng p) => polygons.any(
    (polygon) =>
        _ring(p, polygon[0]) && !polygon.skip(1).any((hole) => _ring(p, hole)),
  );
  bool _ring(LatLng p, List<dynamic> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = (ring[i][0] as num).toDouble(),
          yi = (ring[i][1] as num).toDouble(),
          xj = (ring[j][0] as num).toDouble(),
          yj = (ring[j][1] as num).toDouble();
      if ((yi > p.latitude) != (yj > p.latitude) &&
          p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }
}
