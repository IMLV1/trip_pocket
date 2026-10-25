import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trip_pocket/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android UI: form, map confirm/cancel, budget, packing and preview',
    (tester) async {
      await app.bootstrap(modeOverride: 'demo');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('email')),
        'ui-demo@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'demo1234');
      await tester.tap(find.byKey(const Key('auth-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('สร้างทริป'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trip-title')),
        'เชียงใหม่ UI',
      );
      await tester.enterText(find.byKey(const Key('destination')), 'เชียงใหม่');
      await tester.enterText(find.byKey(const Key('budget')), '3000');
      for (
        var attempt = 0;
        attempt < 30 && tester.view.viewInsets.bottom == 0;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        tester.view.viewInsets.bottom,
        greaterThan(0),
        reason: 'Native Android keyboard must be visible for this check',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('save-trip')));
      await tester.pumpAndSettle();
      final visibleBottom =
          (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
          tester.view.devicePixelRatio;
      expect(
        tester.getBottomRight(find.byKey(const Key('save-trip'))).dy,
        lessThanOrEqualTo(visibleBottom + 1),
        reason: 'Save button must be scrollable above the keyboard',
      );
      debugPrint(
        'P7 native keyboard verified with nonzero inset and visible save button',
      );
      await tester.tap(find.byKey(const Key('save-trip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เชียงใหม่ UI'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('add-stop')));
      await tester.tap(find.byKey(const Key('add-stop')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('activity-title')), 'คาเฟ่');
      await tester.enterText(find.byKey(const Key('activity-cost')), '200.25');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('pick-place')));
      await tester.tap(find.byKey(const Key('pick-place')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('confirm-place')))
            .onPressed,
        isNull,
      );
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('confirm-place')))
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('OpenStreetMap'), findsWidgets);
      for (var attempt = 0; attempt < 20; attempt++) {
        final loaded = tester
            .widgetList<RawImage>(
              find.descendant(
                of: find.byType(FlutterMap),
                matching: find.byType(RawImage),
              ),
            )
            .any((image) => image.image != null);
        if (loaded) break;
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(
        tester
            .widgetList<RawImage>(
              find.descendant(
                of: find.byType(FlutterMap),
                matching: find.byType(RawImage),
              ),
            )
            .any((image) => image.image != null),
        isTrue,
        reason: 'At least one real map tile must render',
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('map-picker');
      await tester.tap(find.byKey(const Key('confirm-place')));
      await tester.pumpAndSettle();
      final previous = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('pick-place')),
              matching: find.byType(Text),
            ),
          )
          .data;
      await tester.tap(find.byKey(const Key('pick-place')));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(40, 40),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('pick-place')),
                matching: find.byType(Text),
              ),
            )
            .data,
        previous,
      );
      await tester.ensureVisible(find.byKey(const Key('save-activity')));
      await tester.tap(find.byKey(const Key('save-activity')));
      await tester.pumpAndSettle();
      expect(find.text('วางแผนแล้ว 200.25 บาท'), findsOneWidget);
      await binding.takeScreenshot('trip-budget');
      await tester.tap(find.byKey(const Key('tab-packing')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('packing-text')));
      await tester.enterText(find.byKey(const Key('packing-text')), 'สายชาร์จ');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('packing-add')));
      await tester.pumpAndSettle();
      expect(find.text('สายชาร์จ'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tab-plan')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('แชร์แผนเที่ยว'));
      await tester.tap(find.text('แชร์แผนเที่ยว'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.textContaining('คงเหลือ: 2,799.75'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เชียงใหม่ UI'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-packing')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('สายชาร์จ'));
      expect(find.text('สายชาร์จ'), findsOneWidget);
    },
  );
}
