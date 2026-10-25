import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/activities/presentation/activity_form_screen.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

class FailedTile extends Fake implements TileImage {}

void main() {
  testWidgets(
    'tile failure and retry keep the activity draft and confirmed point',
    (tester) async {
      const trip = Trip(
        id: 't',
        title: 'ทริป',
        destination: 'เชียงใหม่',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 300000,
      );
      const activity = TripActivity(
        id: 'a',
        title: 'คาเฟ่',
        date: '2026-11-06',
        timeMinutes: 540,
        estimatedCostSatang: 20000,
        latitude: 18.78,
        longitude: 98.98,
      );
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActivityEditor(uid: 'a', trip: trip, initial: activity),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('activity-title')),
        'ชื่อที่ยังไม่บันทึก',
      );
      await tester.enterText(find.byKey(const Key('activity-cost')), '234.56');
      await tester.ensureVisible(find.byKey(const Key('pick-place')));
      await tester.tap(find.byKey(const Key('pick-place')));
      await tester.pumpAndSettle();
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      layer.errorTileCallback!(
        FailedTile(),
        StateError('offline'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('โหลดแผนที่บางส่วนไม่ได้'), findsOneWidget);
      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('ชื่อที่ยังไม่บันทึก'), findsOneWidget);
      expect(find.text('234.56'), findsOneWidget);
      expect(find.textContaining('18.7800, 98.9800'), findsOneWidget);
    },
  );
}
