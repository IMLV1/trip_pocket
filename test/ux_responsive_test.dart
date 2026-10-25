import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_pocket/app/app.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/core/design_system.dart';
import 'package:trip_pocket/features/places/curated_places.dart';
import 'package:trip_pocket/features/places/place_catalog.dart';
import 'package:trip_pocket/features/places/recommendations_sheet.dart';

void main() {
  testWidgets(
    'small screen and enlarged Thai text keeps login validation and password toggle reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [modeProvider.overrideWithValue('demo')],
          child: const SessionApp(uid: null),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('password')), 140);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('แสดงรหัสผ่าน'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('แสดงรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('password')),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isFalse,
      );
      await tester.ensureVisible(find.byKey(const Key('auth-submit')));
      await tester.tap(find.byKey(const Key('auth-submit')));
      await tester.pumpAndSettle();
      expect(find.text('กรอกอีเมลให้ถูกต้อง'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search results remain selectable with keyboard on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            placeCatalogProvider.overrideWith(
              (ref) async => PlaceCatalog(chiangMaiPlaces),
            ),
          ],
          child: MaterialApp(
            theme: buildTripTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) =>
                        const RecommendationsSheet(remaining: 10000),
                  ),
                  child: const Text('ค้นหา'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ค้นหา'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(find.byKey(const Key('place-search')), 'Jasmine');
      await tester.pumpAndSettle();
      final target = find.byKey(const Key('recommend-jasmine'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('place-map-view')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
