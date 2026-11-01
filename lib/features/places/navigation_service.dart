// สร้างลิงก์ Google Maps Directions แล้วเปิดแอปภายนอก
// ถ้าเปิดไม่ได้จะลองเปิดในเบราว์เซอร์ก่อนแจ้ง error

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../activities/domain/trip_activity.dart';

typedef MapsLauncher = Future<bool> Function(Uri uri, LaunchMode mode);
final navigationProvider = Provider<NavigationService>(
  (ref) => NavigationService((uri, mode) => launchUrl(uri, mode: mode)),
);

class NavigationService {
  final MapsLauncher launch;
  NavigationService(this.launch);
  Uri directions(TripActivity to, {TripActivity? from}) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${to.latitude},${to.longitude}',
        if (from != null) 'origin': '${from.latitude},${from.longitude}',
        'travelmode': switch (to.travelMode) {
          'walk' => 'walking',
          'transit' => 'transit',
          _ => 'driving',
        },
      });
  Future<void> open(TripActivity to, {TripActivity? from}) async {
    final uri = directions(to, from: from);
    var opened = false;
    try {
      opened = await launch(uri, LaunchMode.externalApplication);
    } catch (_) {
      /* Try browser next. */
    }
    if (opened) return;
    try {
      opened = await launch(uri, LaunchMode.inAppBrowserView);
    } catch (_) {
      /* Surface a recoverable error. */
    }
    if (!opened) throw StateError('เปิดแผนที่ไม่ได้ กรุณาลองใหม่');
  }
}
