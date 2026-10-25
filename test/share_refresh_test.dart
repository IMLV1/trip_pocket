import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/presentation/trip_detail_screen.dart';

void main() {
  testWidgets(
    'preview freezes its text and reopening reflects edited/deleted activities',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final packing = PackingRepository(await SharedPreferences.getInstance());
      final repo = DemoTravelRepository(packing);
      const trip = Trip(
        id: 't',
        title: 'เชียงใหม่',
        destination: 'เชียงใหม่',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 300000,
      );
      TripActivity activity(int cost) => TripActivity(
        id: 'a',
        title: 'คาเฟ่',
        date: '2026-11-06',
        timeMinutes: 540,
        estimatedCostSatang: cost,
        latitude: 18.78,
        longitude: 98.98,
        note: 'private note',
      );
      await repo.saveTrip('a', trip, create: true);
      await repo.saveActivity('a', 't', activity(20000), create: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            travelRepositoryProvider.overrideWithValue(repo),
            packingRepositoryProvider.overrideWithValue(packing),
          ],
          child: const MaterialApp(
            home: TripDetailScreen(uid: 'a', tripId: 't'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> open() async {
        await tester.ensureVisible(find.text('แชร์แผนเที่ยว'));
        await tester.tap(find.text('แชร์แผนเที่ยว'));
        await tester.pumpAndSettle();
      }

      Future<void> close() async {
        await tester.tap(find.byIcon(Icons.close).last);
        await tester.pumpAndSettle();
      }

      String text() =>
          tester.widget<SelectableText>(find.byType(SelectableText)).data!;
      await open();
      final frozen = text();
      expect(frozen, contains('200.00 บาท'));
      expect(frozen, isNot(contains('private note')));
      await repo.saveActivity('a', 't', activity(35000), create: false);
      await tester.pumpAndSettle();
      expect(text(), frozen);
      await close();
      await open();
      expect(text(), contains('350.00 บาท'));
      expect(text(), contains('คงเหลือ: 2,650.00 บาท'));
      await close();
      await repo.deleteActivity('a', 't', 'a');
      await tester.pumpAndSettle();
      await open();
      expect(text(), contains('ยังไม่มีกิจกรรมในแผน'));
      expect(text(), contains('คงเหลือ: 3,000.00 บาท'));
      await close();
      expect((await repo.watchActivities('a', 't').first).value, isEmpty);
    },
  );
}
