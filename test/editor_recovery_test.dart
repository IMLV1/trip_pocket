import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';
import 'package:trip_pocket/features/trips/presentation/trip_form_screen.dart';
import 'package:trip_pocket/features/activities/presentation/activity_form_screen.dart';

const trip = Trip(
  id: 'trip',
  title: 'เชียงใหม่',
  destination: 'เชียงใหม่',
  startDate: '2026-11-06',
  endDate: '2026-11-08',
  budgetSatang: 300000,
);

class LoadingRepository extends DemoTravelRepository {
  final events = StreamController<DataSnapshot<Trip?>>.broadcast();
  LoadingRepository(super.packing);
  @override
  Stream<DataSnapshot<Trip?>> watchTrip(String uid, String tripId) =>
      events.stream;
}

class FailingSaveRepository extends DemoTravelRepository {
  final firstSave = Completer<void>();
  final attempts = <String>[];
  FailingSaveRepository(super.packing);
  @override
  Future<void> saveTrip(String uid, Trip value, {required bool create}) {
    attempts.add(value.id);
    if (attempts.length == 1) return firstSave.future;
    return super.saveTrip(uid, value, create: create);
  }
}

Future<void> openEditor(
  WidgetTester tester,
  DemoTravelRepository repo,
  Widget screen,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/editor'),
            child: const Text('เปิดฟอร์ม'),
          ),
        ),
      ),
      GoRoute(path: '/editor', builder: (context, state) => screen),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [travelRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('เปิดฟอร์ม'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<PackingRepository> packing() async {
  SharedPreferences.setMockInitialValues({});
  return PackingRepository(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('trip loading and failure keep an app back button', (
    tester,
  ) async {
    final repo = LoadingRepository(await packing());
    await openEditor(
      tester,
      repo,
      const TripFormScreen(uid: 'a', tripId: 'trip'),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    repo.events.addError(StateError('เครือข่ายขัดข้อง'));
    await tester.pumpAndSettle();
    expect(find.text('เครือข่ายขัดข้อง'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('เปิดฟอร์ม'), findsOneWidget);
    await repo.events.close();
  });
  testWidgets('missing activity has back navigation and an explicit exit', (
    tester,
  ) async {
    final repo = DemoTravelRepository(await packing());
    await repo.saveTrip('a', trip, create: true);
    await openEditor(
      tester,
      repo,
      const ActivityFormScreen(uid: 'a', tripId: 'trip', activityId: 'deleted'),
    );
    await tester.pumpAndSettle();
    expect(find.text('ไม่พบกิจกรรม'), findsOneWidget);
    expect(find.text('กลับรายการทริป'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('เปิดฟอร์ม'), findsOneWidget);
  });
  testWidgets(
    'failed trip save retains draft and retry id; busy rejects double tap',
    (tester) async {
      final repo = FailingSaveRepository(await packing());
      await openEditor(tester, repo, const TripEditor(uid: 'a'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trip-title')),
        'ทริปที่ยังไม่บันทึก',
      );
      await tester.enterText(find.byKey(const Key('destination')), 'เชียงใหม่');
      await tester.enterText(find.byKey(const Key('budget')), '2500.50');
      await tester.ensureVisible(find.byKey(const Key('save-trip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-trip')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-trip')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('save-trip')));
      expect(repo.attempts, hasLength(1));
      repo.firstSave.completeError(StateError('บันทึกไม่สำเร็จ'));
      await tester.pumpAndSettle();
      expect(find.text('ทริปที่ยังไม่บันทึก'), findsOneWidget);
      expect(find.text('2500.50'), findsOneWidget);
      expect(find.text('บันทึกไม่สำเร็จ'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-trip')));
      await tester.pumpAndSettle();
      expect(repo.attempts, hasLength(2));
      expect(repo.attempts[0], repo.attempts[1]);
      expect(find.text('เปิดฟอร์ม'), findsOneWidget);
    },
  );
  testWidgets(
    'small screen with keyboard inset can scroll to and submit save',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final repo = DemoTravelRepository(await packing());
      await openEditor(tester, repo, const TripEditor(uid: 'a'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trip-title')),
        'ทริปบนจอเล็ก',
      );
      await tester.enterText(find.byKey(const Key('destination')), 'เชียงใหม่');
      await tester.enterText(find.byKey(const Key('budget')), '3000');
      await tester.ensureVisible(find.byKey(const Key('save-trip')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byKey(const Key('save-trip'))).dy,
        lessThanOrEqualTo(338),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('save-trip')));
      await tester.pumpAndSettle();
      expect(find.text('เปิดฟอร์ม'), findsOneWidget);
    },
  );
}
