import 'package:flutter_test/flutter_test.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';

void main() {
  test(
    'new trip dates must be strictly increasing, including month/year transitions',
    () {
      Trip t(String a, String b) => Trip(
        id: 't',
        title: 'ทริป',
        destination: 'ไทย',
        startDate: a,
        endDate: b,
        budgetSatang: 0,
      );
      expect(() => t('2026-11-06', '2026-11-06').validate(), throwsStateError);
      expect(() => t('2026-11-07', '2026-11-06').validate(), throwsStateError);
      t('2026-11-30', '2026-12-01').validate();
      t('2026-12-31', '2027-01-01').validate();
      final legacy = Trip.fromFields('old', {
        'title': 'เดิม',
        'destination': 'ไทย',
        'startDate': '2026-11-06',
        'endDate': '2026-11-06',
        'budgetSatang': 100,
        'status': 'active',
      });
      expect(legacy.budgetSatang, 100);
      expect(legacy.validate, throwsStateError);
    },
  );
}
