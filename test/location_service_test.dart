import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trip_pocket/features/places/location_service.dart';

void main() {
  test(
    'GPS service only reads after permission; denial and disabled remain recoverable',
    () async {
      var reads = 0, requests = 0;
      Future<Position> read() async {
        reads++;
        return Position(
          longitude: 98.98,
          latitude: 18.78,
          timestamp: DateTime(2026, 10, 26),
          accuracy: 20,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      final service = LocationService(
        enabled: () async => true,
        check: () async => LocationPermission.denied,
        request: () async {
          requests++;
          return LocationPermission.whileInUse;
        },
        read: read,
      );
      expect(reads, 0);
      final fix = await service.locate();
      expect(fix.point.latitude, 18.78);
      expect(reads, 1);
      expect(requests, 1);
      final denied = LocationService(
        enabled: () async => true,
        check: () async => LocationPermission.deniedForever,
        request: () async {
          requests++;
          return LocationPermission.denied;
        },
        read: read,
      );
      await expectLater(denied.locate(), throwsStateError);
      expect(reads, 1);
      expect(requests, 1);
      final disabled = LocationService(enabled: () async => false, read: read);
      await expectLater(disabled.locate(), throwsStateError);
      expect(reads, 1);
    },
  );
  test(
    'GPS timeout becomes an actionable error without persisting a false fix',
    () async {
      final service = LocationService(
        enabled: () async => true,
        check: () async => LocationPermission.whileInUse,
        read: () async => throw TimeoutException('no fix'),
      );
      await expectLater(
        service.locate(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('ยังหาตำแหน่งไม่พบ'),
          ),
        ),
      );
    },
  );
}
