import '../../../core/validation.dart';
import '../../trips/domain/trip.dart';

class TripActivity {
  final String id, title, date, note;
  final int timeMinutes, estimatedCostSatang;
  final double latitude, longitude;
  final DateTime? createdAt, updatedAt;
  const TripActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.timeMinutes,
    required this.estimatedCostSatang,
    required this.latitude,
    required this.longitude,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });
  void validate(Trip trip) {
    requireValid(
      textError(title) == null && note.runes.length <= 500,
      'ชื่อหรือหมายเหตุยาวเกินกำหนด',
    );
    requireValid(
      validDate(date) &&
          date.compareTo(trip.startDate) >= 0 &&
          date.compareTo(trip.endDate) <= 0,
      'วันกิจกรรมต้องอยู่ในช่วงทริป',
    );
    requireValid(timeMinutes >= 0 && timeMinutes < 1440, 'เวลาไม่ถูกต้อง');
    requireValid(
      estimatedCostSatang >= 0 && estimatedCostSatang <= maxMoney,
      'ค่าใช้จ่ายไม่ถูกต้อง',
    );
    requireValid(
      latitude.isFinite &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude.isFinite &&
          longitude >= -180 &&
          longitude <= 180,
      'กรุณาเลือกพิกัดที่ถูกต้อง',
    );
  }

  Map<String, dynamic> fields() => {
    'title': title.trim(),
    'date': date,
    'timeMinutes': timeMinutes,
    'estimatedCostSatang': estimatedCostSatang,
    'latitude': latitude,
    'longitude': longitude,
    'note': note.trim(),
  };
}

List<TripActivity> sortedActivities(Iterable<TripActivity> items) =>
    items.toList()..sort((a, b) {
      final d = a.date.compareTo(b.date);
      if (d != 0) return d;
      final t = a.timeMinutes.compareTo(b.timeMinutes);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
int plannedTotal(Iterable<TripActivity> activities) =>
    activities.fold(0, (n, a) => n + a.estimatedCostSatang);
