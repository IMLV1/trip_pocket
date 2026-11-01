import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/app.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/auth/auth_repository.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

class RecordingAuth extends DemoAuthRepository {
  final resetRequests = <String>[];
  int passwordUpdates = 0;
  @override
  Future<void> sendPasswordReset(String email) async {
    resetRequests.add(email.trim());
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordUpdates++;
    await super.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

Future<(RecordingAuth, DemoTravelRepository, PackingRepository)> open(
  WidgetTester tester, {
  bool signedIn = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final packing = PackingRepository(await SharedPreferences.getInstance());
  final auth = RecordingAuth();
  final repo = DemoTravelRepository(packing);
  if (signedIn) await auth.signIn('profile@example.com', 'fixture-secret');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        modeProvider.overrideWithValue('demo'),
        authRepositoryProvider.overrideWithValue(auth),
        travelRepositoryProvider.overrideWithValue(repo),
        packingRepositoryProvider.overrideWithValue(packing),
      ],
      child: const TripPocketApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (auth, repo, packing);
}

Future<void> tap(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'forgot password validates and shows a generic result without signing in',
    (tester) async {
      final (auth, _, _) = await open(tester, signedIn: false);
      await tap(tester, 'forgot-password');
      await tap(tester, 'send-reset-email');
      expect(find.text('กรอกอีเมลให้ถูกต้อง'), findsOneWidget);
      expect(auth.resetRequests, isEmpty);
      await tester.enterText(
        find.byKey(const Key('reset-email')),
        'unknown@example.com',
      );
      await tap(tester, 'send-reset-email');
      expect(auth.resetRequests, ['unknown@example.com']);
      expect(find.textContaining('หากอีเมลนี้มีบัญชี'), findsOneWidget);
      expect(auth.currentSession, isNull);
    },
  );
  testWidgets(
    'profile saves display name while retaining uid and change password validates confirmation',
    (tester) async {
      final (auth, _, _) = await open(tester);
      final uid = auth.currentSession!.uid;
      await tap(tester, 'open-profile');
      await tester.enterText(
        find.byKey(const Key('profile-name')),
        '  นักเดินทาง  ',
      );
      await tap(tester, 'save-profile');
      expect(auth.currentSession!.uid, uid);
      expect(auth.currentSession!.displayName, 'นักเดินทาง');
      await tap(tester, 'open-change-password');
      await tester.enterText(
        find.byKey(const Key('current-password')),
        'fixture-old',
      );
      await tester.enterText(
        find.byKey(const Key('new-password')),
        'fixture-new',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-new-password')),
        'different',
      );
      await tap(tester, 'save-password');
      expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
      expect(auth.passwordUpdates, 0);
      await tester.enterText(
        find.byKey(const Key('confirm-new-password')),
        'fixture-new',
      );
      await tap(tester, 'save-password');
      expect(auth.passwordUpdates, 1);
      expect(find.text('โปรไฟล์ของฉัน'), findsOneWidget);
      expect(auth.currentSession!.uid, uid);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ออกจากระบบ'));
      await tester.pumpAndSettle();
      expect(auth.currentSession, isNull);
      expect(find.byKey(const Key('profile-name')), findsNothing);
    },
  );
  testWidgets(
    'trip search and completion separate lists, preserve data and isolate accounts',
    (tester) async {
      final (auth, repo, packing) = await open(tester);
      final uid = auth.currentSession!.uid;
      Trip t(String id, String title) => Trip(
        id: id,
        title: title,
        destination: 'ไทย',
        startDate: '2026-11-06',
        endDate: '2026-11-08',
        budgetSatang: 12345,
      );
      await repo.saveTrip(uid, t('a', 'เชียงใหม่สบายใจ'), create: true);
      await repo.saveTrip(uid, t('b', 'Phuket Holiday'), create: true);
      await repo.saveTrip('other', t('private', 'ชื่อทริปลับ'), create: true);
      await tester.pumpAndSettle();
      await tap(tester, 'search-trips');
      await tester.enterText(find.byKey(const Key('trip-search')), '  PHUKET ');
      await tester.pumpAndSettle();
      expect(find.text('Phuket Holiday'), findsOneWidget);
      expect(find.text('เชียงใหม่สบายใจ'), findsNothing);
      expect(find.text('ชื่อทริปลับ'), findsNothing);
      await tester.tap(find.byTooltip('ล้างคำค้นทริป'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เชียงใหม่สบายใจ'));
      await tester.pumpAndSettle();
      await tap(tester, 'complete-trip');
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect((await repo.watchTrip(uid, 'a').first).value!.completed, isFalse);
      await packing.save(uid, 'a', [const PackingItem('p', 'charger', true)]);
      await tap(tester, 'complete-trip');
      await tap(tester, 'confirm-complete-trip');
      expect((await repo.watchTrip(uid, 'a').first).value!.completed, isTrue);
      await repo.completeTrip(uid, 'a');
      expect((await packing.load(uid, 'a')).single.checked, isTrue);
      expect((await repo.watchTrip(uid, 'a').first).value!.budgetSatang, 12345);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('เชียงใหม่สบายใจ'), findsNothing);
      await tap(tester, 'trips-completed');
      expect(find.text('เชียงใหม่สบายใจ'), findsOneWidget);
      expect(find.text('Phuket Holiday'), findsNothing);
      await tester.enterText(find.byKey(const Key('trip-search')), 'ไม่พบ');
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบชื่อทริปที่ค้นหา'), findsOneWidget);
    },
  );
  testWidgets('end date picker excludes the start date', (tester) async {
    await open(tester);
    await tester.tap(find.text('สร้างทริป'));
    await tester.pumpAndSettle();
    final startTile = tester.widget<ListTile>(
      find.byKey(const Key('trip-start-date')),
    );
    final start = DateTime.parse((startTile.subtitle! as Text).data!);
    await tap(tester, 'trip-end-date');
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(dialog.firstDate, start.add(const Duration(days: 1)));
    expect(dialog.initialDate!.isAfter(start), isTrue);
    expect(dialog.firstDate.isAfter(start), isTrue);
  });
}
