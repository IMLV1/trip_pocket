import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android native text share sheet opens and returns its selected action',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('TripPocket native share check')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final result = SharePlus.instance.share(
        ShareParams(
          text:
              'TripPocket: เชียงใหม่\nงบทั้งหมด: 3,000.00 บาท\nคงเหลือ: 2,800.00 บาท',
        ),
      );
      const receiverCheck = bool.fromEnvironment('CHECK_SHARE_RECEIVER');
      debugPrint(
        receiverCheck
            ? 'NATIVE_SHARE_OPEN: select a text receiver and inspect its content'
            : 'NATIVE_SHARE_OPEN: cancel the Android sheet to complete the check',
      );
      final status = await result.timeout(const Duration(seconds: 60));
      expect(
        status.status,
        receiverCheck ? ShareResultStatus.success : ShareResultStatus.dismissed,
      );
      if (receiverCheck) debugPrint('SHARE_RECEIVER: ${status.raw}');
    },
    skip: !const bool.fromEnvironment('RUN_MANUAL_SHARE'),
  );
}
