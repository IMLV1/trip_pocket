import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/places/daily_map.dart';
import 'package:trip_pocket/features/places/navigation_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native location permission and external Maps URL (manual CUA receiver verification)',
    (tester) async {
      const enabled = bool.fromEnvironment('RUN_NATIVE_NAVIGATION');
      const browserOnly = bool.fromEnvironment('BROWSER_ONLY');
      if (!enabled) {
        markTestSkipped('Opt in and observe OS permission/Maps UI');
        return;
      }
      const a = TripActivity(
        id: 'a',
        title: 'วัดพระสิงห์',
        date: '2026-11-06',
        timeMinutes: 540,
        estimatedCostSatang: 0,
        costKnown: false,
        latitude: 18.7885,
        longitude: 98.9814,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('TripPocket • ทดสอบแผนที่')),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    DailyMap(activities: const [a], onSelect: (_) {}),
                    const Text('การทดสอบใช้ตำแหน่งจำลองของ Android Emulator'),
                    TextButton(
                      key: const Key('native-maps'),
                      onPressed: () =>
                          container.read(navigationProvider).open(a),
                      child: const Text('ทดสอบเปิด Google Maps'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      if (!browserOnly) {
        // CUA grants or denies the native prompt; never auto-grant via shell.
        await tester.tap(find.byKey(const Key('my-location')));
        for (
          var i = 0;
          i < 180 &&
              !find
                  .textContaining('ตำแหน่งที่อ่านล่าสุด')
                  .evaluate()
                  .isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(
          find.textContaining('ตำแหน่งที่อ่านล่าสุด'),
          findsOneWidget,
          reason:
              'Permission and actual OS position must succeed, not an injected location',
        );
        await binding.takeScreenshot('v21-current-location');
      }
      final uri = container.read(navigationProvider).directions(a);
      expect(uri.queryParameters.containsKey('origin'), isFalse);
      const origin = TripActivity(
        id: 'origin',
        title: 'จุดทดสอบเชียงใหม่',
        date: '2026-11-06',
        timeMinutes: 500,
        estimatedCostSatang: 0,
        latitude: 18.79,
        longitude: 98.99,
      );
      // Simulate an unavailable external handler; exercise the real browser branch.
      final service = browserOnly
          ? NavigationService(
              (uri, mode) => mode == LaunchMode.externalApplication
                  ? Future.value(false)
                  : launchUrl(uri, mode: mode),
            )
          : container.read(navigationProvider);
      final opened = service.open(a, from: browserOnly ? origin : null);
      await tester.runAsync(() => opened);
      debugPrint(
        'V21_MAPS_LAUNCH_RETURNED: external URL launch accepted; inspect receiver separately',
      );
      // Allow CUA to inspect Maps/browser and return before the test host exits.
      await tester.pump(const Duration(seconds: 45));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
