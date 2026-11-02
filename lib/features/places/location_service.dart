// One-shot foreground location lookup. Runs only when the user asks; nothing is
// tracked in the background or saved.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// A transient location reading. Never persisted.
class LocationFix {
  final LatLng point;
  final double accuracy;
  final DateTime timestamp;
  const LocationFix(this.point, this.accuracy, this.timestamp);
}

/// Provides the [LocationService].
final locationProvider = Provider<LocationService>((ref) => LocationService());

/// Wraps geolocator. All calls are injectable for tests.
class LocationService {
  final Future<bool> Function() enabled;
  final Future<LocationPermission> Function() check, request;
  final Future<Position> Function() read;
  LocationService({
    Future<bool> Function()? enabled,
    Future<LocationPermission> Function()? check,
    Future<LocationPermission> Function()? request,
    Future<Position> Function()? read,
  }) : enabled = enabled ?? Geolocator.isLocationServiceEnabled,
       check = check ?? Geolocator.checkPermission,
       request = request ?? Geolocator.requestPermission,
       read =
           read ??
           (() => Geolocator.getCurrentPosition(
             locationSettings: defaultTargetPlatform == TargetPlatform.android
                 ? AndroidSettings(
                     forceLocationManager: true,
                     accuracy: LocationAccuracy.high,
                     timeLimit: const Duration(seconds: 20),
                   )
                 : const LocationSettings(
                     accuracy: LocationAccuracy.high,
                     timeLimit: Duration(seconds: 20),
                   ),
           ));

  /// Checks the service and permission, then reads once with a timeout.
  ///
  /// Failures throw a [StateError] with Thai guidance. Planning still works
  /// without a location.
  Future<LocationFix> locate() async {
    if (!await enabled()) {
      throw StateError('Location ปิดอยู่ กรุณาเปิดตำแหน่งบนอุปกรณ์แล้วลองใหม่');
    }
    var permission = await check();
    if (permission == LocationPermission.denied) permission = await request();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError(
        permission == LocationPermission.deniedForever
            ? 'สิทธิ์ตำแหน่งถูกปิดถาวร เปิดได้จากการตั้งค่าแอป หรือวางแผนต่อโดยไม่ใช้ตำแหน่ง'
            : 'ไม่ได้รับสิทธิ์ตำแหน่ง ยังเลือกหมุดและวางแผนได้ตามปกติ',
      );
    }
    try {
      final p = await read().timeout(const Duration(seconds: 22));
      if (!p.latitude.isFinite ||
          !p.longitude.isFinite ||
          p.latitude.abs() > 90 ||
          p.longitude.abs() > 180) {
        throw StateError('ข้อมูลตำแหน่งไม่ถูกต้อง');
      }
      return LocationFix(
        LatLng(p.latitude, p.longitude),
        p.accuracy,
        p.timestamp,
      );
    } on TimeoutException {
      throw StateError('ยังหาตำแหน่งไม่พบ ลองใหม่ในพื้นที่รับสัญญาณได้');
    }
  }
}
