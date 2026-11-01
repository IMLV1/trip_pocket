// Opens directions in external Google Maps.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../activities/domain/trip_activity.dart';

/// URL launcher signature, injectable for tests.
typedef MapsLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

/// Provides the [NavigationService].
final navigationProvider = Provider<NavigationService>(
  (ref) => NavigationService((uri, mode) => launchUrl(uri, mode: mode)),
);

/// Opens directions outside the app.
class NavigationService {
  final MapsLauncher launch;
  NavigationService(this.launch);

  /// Builds a directions URL. Without [from], Maps starts at the user.
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

  /// Tries the external app, then an in-app browser. Throws if both fail.
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
