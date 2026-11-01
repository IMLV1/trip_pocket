// โมเดลจุดหมายในทริป: การตรวจค่า การเรียงลำดับ ค่าเดินทางแต่ละช่วง และการคำนวณงบ
// ค่าเดินทางนับเฉพาะช่วงที่จุดและเวลายังตรงกับตอนบันทึก ราคาที่ไม่ทราบไม่ถือว่าฟรี

import 'dart:convert';
import '../../../core/validation.dart';
import '../../trips/domain/trip.dart';

const activityCategories = {
  'attraction': 'ท่องเที่ยว',
  'food': 'อาหาร',
  'lodging': 'ที่พัก',
  'other': 'อื่น ๆ',
};
const travelModes = {
  'none': 'ยังไม่เลือก',
  'car': 'รถยนต์',
  'motorcycle': 'มอเตอร์ไซค์',
  'walk': 'เดิน',
  'transit': 'ขนส่งสาธารณะ',
};

class TripActivity {
  final String id,
      title,
      date,
      note,
      category,
      travelMode,
      travelFromId,
      travelSignature;
  final int timeMinutes, estimatedCostSatang, travelCostSatang;
  final int? orderIndex;
  final bool costKnown, travelCostKnown;
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
    this.category = 'other',
    this.orderIndex,
    this.costKnown = true,
    this.travelMode = 'none',
    this.travelFromId = '',
    this.travelSignature = '',
    this.travelCostSatang = 0,
    this.travelCostKnown = false,
  });

  int get rank => orderIndex ?? timeMinutes * 1000;
  factory TripActivity.fromFields(
    String id,
    Map<String, dynamic> d, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TripActivity(
    id: id,
    title: d['title'],
    date: d['date'],
    timeMinutes: d['timeMinutes'],
    estimatedCostSatang: d['estimatedCostSatang'],
    latitude: (d['latitude'] as num).toDouble(),
    longitude: (d['longitude'] as num).toDouble(),
    note: d['note'],
    category: d['category'] ?? 'other',
    orderIndex: d['orderIndex'],
    costKnown: d['costKnown'] ?? true,
    travelMode: d['travelMode'] ?? 'none',
    travelFromId: d['travelFromId'] ?? '',
    travelSignature: d['travelSignature'] ?? '',
    travelCostSatang: d['travelCostSatang'] ?? 0,
    travelCostKnown: d['travelCostKnown'] ?? false,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  TripActivity withRank(int rank) => TripActivity.fromFields(
    id,
    {...fields(), 'orderIndex': rank},
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
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
      estimatedCostSatang >= 0 &&
          estimatedCostSatang <= maxMoney &&
          (costKnown || estimatedCostSatang == 0),
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
    requireValid(
      activityCategories.containsKey(category) && rank >= 0 && rank <= maxMoney,
      'หมวดหรือลำดับไม่ถูกต้อง',
    );
    requireValid(
      travelModes.containsKey(travelMode) &&
          travelFromId.length <= 128 &&
          travelSignature.length <= 1024 &&
          travelCostSatang >= 0 &&
          travelCostSatang <= maxMoney &&
          (travelCostKnown || travelCostSatang == 0),
      'ข้อมูลการเดินทางไม่ถูกต้อง',
    );
    requireValid(
      travelMode != 'none' ||
          (!travelCostKnown &&
              travelCostSatang == 0 &&
              travelFromId.isEmpty &&
              travelSignature.isEmpty),
      'กรุณาเลือกวิธีเดินทาง',
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
    'schemaVersion': 2,
    'category': category,
    'orderIndex': rank,
    'costKnown': costKnown,
    'travelMode': travelMode,
    'travelFromId': travelFromId,
    'travelSignature': travelSignature,
    'travelCostSatang': travelCostSatang,
    'travelCostKnown': travelCostKnown,
  };
}

List<TripActivity> sortedActivities(Iterable<TripActivity> items) =>
    items.toList()..sort((a, b) {
      final d = a.date.compareTo(b.date);
      if (d != 0) return d;
      final r = a.rank.compareTo(b.rank);
      if (r != 0) return r;
      final t = a.timeMinutes.compareTo(b.timeMinutes);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
String segmentSignature(TripActivity from, TripActivity to) => jsonEncode([
  from.id,
  from.date,
  from.timeMinutes,
  from.latitude,
  from.longitude,
  to.id,
  to.date,
  to.timeMinutes,
  to.latitude,
  to.longitude,
]);
bool validSegment(TripActivity from, TripActivity to) =>
    from.date == to.date &&
    to.travelMode != 'none' &&
    to.travelFromId == from.id &&
    to.travelSignature == segmentSignature(from, to);

class PlanBudget {
  final int activities, transport, unknownActivities, unknownSegments;
  const PlanBudget(
    this.activities,
    this.transport,
    this.unknownActivities,
    this.unknownSegments,
  );
  int get total => activities + transport;
  int get unknown => unknownActivities + unknownSegments;
}

PlanBudget planBudget(Iterable<TripActivity> items) {
  final list = sortedActivities(items);
  var cost = 0, travel = 0, unknown = 0, unknownTravel = 0;
  for (var i = 0; i < list.length; i++) {
    final a = list[i];
    if (a.costKnown) {
      cost += a.estimatedCostSatang;
    } else {
      unknown++;
    }
    if (i > 0 && list[i - 1].date == a.date) {
      if (validSegment(list[i - 1], a) && a.travelCostKnown) {
        travel += a.travelCostSatang;
      } else {
        unknownTravel++;
      }
    }
  }
  return PlanBudget(cost, travel, unknown, unknownTravel);
}

int plannedTotal(Iterable<TripActivity> activities) =>
    planBudget(activities).total;
