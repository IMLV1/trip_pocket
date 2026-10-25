import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_pocket/core/validation.dart';
import 'package:trip_pocket/features/trips/domain/trip.dart';
import 'package:trip_pocket/features/activities/domain/trip_activity.dart';
import 'package:trip_pocket/features/packing/packing_repository.dart';
import 'package:trip_pocket/features/sharing/trip_share_formatter.dart';
import 'package:trip_pocket/features/trips/data/demo_travel_repository.dart';

const trip = Trip(
  id: 'private-id',
  title: 'เชียงใหม่',
  destination: 'เชียงใหม่',
  startDate: '2026-11-06',
  endDate: '2026-11-08',
  budgetSatang: 30000,
);
TripActivity activity(
  String id, {
  String day = '2026-11-07',
  int time = 540,
  int cost = 20000,
}) => TripActivity(
  id: id,
  title: 'คาเฟ่ $id',
  date: day,
  timeMinutes: time,
  estimatedCostSatang: cost,
  latitude: 18.78,
  longitude: 98.98,
  note: 'secret-note',
);
void main() {
  test('money parsing uses satang exactly and rejects malformed inputs', () {
    expect(parseMoney('0.01'), 1);
    expect(parseMoney('3000.10'), 300010);
    expect(parseMoney('10000000'), maxMoney);
    for (final s in ['-1', 'NaN', '1e3', '1.001', '1,000', '10000000.01', '']) {
      expect(parseMoney(s), isNull, reason: s);
    }
    expect(moneyInput(1), '0.01');
  });
  test('actual calendar dates and activity bounds', () {
    expect(validDate('2024-02-29'), isTrue);
    expect(validDate('2026-02-29'), isFalse);
    expect(validDate('2026-02-30'), isFalse);
    expect(validDate('2026-2-01'), isFalse);
    expect(
      () => activity('a', day: '2026-11-09').validate(trip),
      throwsStateError,
    );
    expect(() => activity('a', time: 1440).validate(trip), throwsStateError);
    expect(() => activity('a', cost: -1).validate(trip), throwsStateError);
  });
  test('share sorting, money, privacy and overspending', () {
    final items = [activity('b', time: 600), activity('a', time: 540)];
    final text = formatTripShare(trip, items);
    expect(text.indexOf('09:00'), lessThan(text.indexOf('10:00')));
    expect(text, contains('เกินงบ: 100.00 บาท'));
    for (final hidden in [
      'secret-note',
      'private-id',
      '18.78',
      '98.98',
      'users/',
    ]) {
      expect(text, isNot(contains(hidden)));
    }
    expect(formatTripShare(trip, []), contains('ยังไม่มีกิจกรรมในแผน'));
    expect(formatTripShare(trip, []), contains('คงเหลือ: 300.00'));
    expect(plannedTotal([activity('a', cost: 0)]), 0);
  });
  test(
    'packing persists, isolates account/trip and refuses corrupt overwrite',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PackingRepository(prefs);
      await repo.save('a', '1', [const PackingItem('item', 'สายชาร์จ', true)]);
      expect(
        (await PackingRepository(prefs).load('a', '1')).single.checked,
        isTrue,
      );
      expect(await repo.load('b', '1'), isEmpty);
      expect(await repo.load('a', '2'), isEmpty);
      await prefs.setString(repo.key('a', 'bad'), 'not json');
      await expectLater(repo.load('a', 'bad'), throwsFormatException);
      await expectLater(repo.save('a', 'bad', []), throwsFormatException);
      expect(prefs.getString(repo.key('a', 'bad')), 'not json');
    },
  );
  test(
    'date shrinking refused; queued active checklist preserved; completed deletion cleans',
    () async {
      SharedPreferences.setMockInitialValues({});
      final packing = PackingRepository(await SharedPreferences.getInstance());
      final repo = DemoTravelRepository(packing);
      await repo.saveTrip('a', trip, create: true);
      await repo.saveActivity('a', trip.id, activity('1'), create: true);
      await packing.save('a', trip.id, [const PackingItem('x', 'ของ', false)]);
      await packing.queueCleanup('a', trip.id);
      await repo.resumePendingDeletes('a');
      expect(await packing.load('a', trip.id), hasLength(1));
      await expectLater(
        repo.saveTrip(
          'a',
          Trip(
            id: trip.id,
            title: 't',
            destination: 'd',
            startDate: '2026-11-06',
            endDate: '2026-11-06',
            budgetSatang: 0,
          ),
          create: false,
        ),
        throwsStateError,
      );
      await repo.deleteTrip('a', trip.id);
      expect(await packing.load('a', trip.id), isEmpty);
      expect(packing.cleanupQueue('a'), isEmpty);
      expect((await repo.watchActivities('a', trip.id).first).value, isEmpty);
    },
  );
}
