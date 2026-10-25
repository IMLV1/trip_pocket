import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/app/app.dart';
import 'package:trip_pocket/app/providers.dart';
import 'package:trip_pocket/features/auth/auth_repository.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';

void main() {
  testWidgets('login validation, trip CRUD UI, logout and account isolation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final packing = PackingRepository(await SharedPreferences.getInstance());
    final auth = DemoAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modeProvider.overrideWithValue('demo'),
          authRepositoryProvider.overrideWithValue(auth),
          packingRepositoryProvider.overrideWithValue(packing),
          travelRepositoryProvider.overrideWithValue(
            DemoTravelRepository(packing),
          ),
        ],
        child: const TripPocketApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('โหมดจำลอง'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('กรอกอีเมลให้ถูกต้อง'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('email')), 'a@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'test1234');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('ทริปของฉัน'), findsOneWidget);
    await tester.tap(find.text('สร้างทริป'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('trip-title')), 'เชียงใหม่');
    await tester.enterText(find.byKey(const Key('destination')), 'เชียงใหม่');
    await tester.enterText(find.byKey(const Key('budget')), '3000.10');
    await tester.ensureVisible(find.byKey(const Key('save-trip')));
    await tester.tap(find.byKey(const Key('save-trip')));
    await tester.pumpAndSettle();
    expect(find.text('เชียงใหม่'), findsOneWidget);
    await tester.tap(find.text('เชียงใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('งบทริป 3,000.10 บาท'), findsOneWidget);
    // Map is created only on demand; packing drafts survive switching tabs.
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-packing')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('packing-text')), 'แว่นกันแดด');
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('packing-text')), findsNothing);
    await tester.tap(find.byKey(const Key('tab-packing')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('packing-text')))
          .controller!
          .text,
      'แว่นกันแดด',
    );
    await tester.tap(find.byKey(const Key('packing-add')));
    await tester.pumpAndSettle();
    expect(find.text('แว่นกันแดด'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ออกจากระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('เชียงใหม่'), findsNothing);
    await auth.signIn('b@example.com', 'test1234');
    await tester.pumpAndSettle();
    expect(find.text('เชียงใหม่'), findsNothing);
    expect(find.textContaining('ยังไม่มีทริป'), findsOneWidget);
  });
}
