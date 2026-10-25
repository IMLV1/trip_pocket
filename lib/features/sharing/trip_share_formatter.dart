import '../trips/domain/trip.dart';
import '../activities/domain/trip_activity.dart';
import '../../core/validation.dart';

String formatTripShare(Trip trip, List<TripActivity> activities) {
  final out = StringBuffer(
    'TripPocket: ${trip.title}\nจุดหมาย: ${trip.destination}\n${trip.startDate} ถึง ${trip.endDate}\n',
  );
  String? day;
  for (final a in sortedActivities(activities)) {
    if (day != a.date) {
      day = a.date;
      out.writeln('\n$day');
    }
    out.writeln(
      '${clockText(a.timeMinutes)} ${a.title} — ${money(a.estimatedCostSatang)} บาท',
    );
  }
  if (activities.isEmpty) out.writeln('\nยังไม่มีกิจกรรมในแผน');
  final planned = plannedTotal(activities),
      remaining = trip.budgetSatang - planned;
  out.writeln('\nงบทั้งหมด: ${money(trip.budgetSatang)} บาท');
  out.writeln('ค่าใช้จ่ายที่วางแผน: ${money(planned)} บาท');
  out.write(
    '${remaining < 0 ? 'เกินงบ' : 'คงเหลือ'}: ${money(remaining.abs())} บาท',
  );
  return out.toString();
}
