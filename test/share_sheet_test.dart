import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_pocket/features/sharing/share_plan_sheet.dart';

class TestShareService extends PlatformShareService {
  final Completer<void> pending = Completer<void>();
  int calls = 0;
  String? sent;
  @override
  Future<void> share(String text, Rect origin) {
    calls++;
    sent = text;
    return pending.future;
  }
}

void main() {
  testWidgets('preview sends frozen text once and preserves preview on error', (
    tester,
  ) async {
    final service = TestShareService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SharePlanSheet(
            text: 'แผนเดิม 200.00 บาท',
            cached: true,
            service: service,
          ),
        ),
      ),
    );
    expect(find.textContaining('ข้อมูลที่โหลดไว้ล่าสุด'), findsOneWidget);
    await tester.tap(find.text('เลือกแอปที่จะแชร์'));
    await tester.pump();
    await tester.tap(find.text('กำลังเปิด…'));
    expect(service.calls, 1);
    expect(service.sent, 'แผนเดิม 200.00 บาท');
    service.pending.completeError(StateError('เปิดแอปแชร์ไม่ได้'));
    await tester.pumpAndSettle();
    expect(find.text('เปิดแอปแชร์ไม่ได้'), findsOneWidget);
    expect(find.text('แผนเดิม 200.00 บาท'), findsOneWidget);
    expect(find.text('ส่งสำเร็จ'), findsNothing);
  });
}
