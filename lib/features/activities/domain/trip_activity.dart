// Activity model, ordering and budget calculation. Totals are always derived
// from activities and never stored, so they cannot drift from the plan.

import 'dart:convert';
import '../../../core/validation.dart';
import '../../trips/domain/trip.dart';

/// Stored category codes and their labels.
const activityCategories = {
  'attraction': 'ท่องเที่ยว',
  'food': 'อาหาร',
  'lodging': 'ที่พัก',
  'other': 'อื่น ๆ',
};

/// Stored travel mode codes and their labels.
const travelModes = {
  'none': 'ยังไม่เลือก',
  'car': 'รถยนต์',
  'motorcycle': 'มอเตอร์ไซค์',
  'walk': 'เดิน',
  'transit': 'ขนส่งสาธารณะ',
};

/// A stop in a trip.
///
/// Travel fields describe the segment arriving at this stop from the one before
/// it. `costKnown` separates an unknown price from a real 0.
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

  /// Position within the day.
  ///
  /// Legacy records without `orderIndex` fall back to time order, so they need
  /// no migration.
  int get rank => orderIndex ?? timeMinutes * 1000;

  /// Decodes stored fields.
  ///
  /// Fields missing from schema 1 records get defaults; saving upgrades the
  /// record to schema 2.
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

  /// Returns a copy with a new rank.
  TripActivity withRank(int rank) => TripActivity.fromFields(
    id,
    {...fields(), 'orderIndex': rank},
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// Throws unless every field is valid for [trip].
  ///
  /// Mirrors `firestore.rules` to give a readable error before the server
  /// rejects the write.
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

  /// Encodes as schema 2 fields.
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

/// Sorts by date, rank, time, then id.
///
/// The id tie-break keeps the order stable across devices.
List<TripActivity> sortedActivities(Iterable<TripActivity> items) =>
    items.toList()..sort((a, b) {
      final d = a.date.compareTo(b.date);
      if (d != 0) return d;
      final r = a.rank.compareTo(b.rank);
      if (r != 0) return r;
      final t = a.timeMinutes.compareTo(b.timeMinutes);
      return t != 0 ? t : a.id.compareTo(b.id);
    });

/// Fingerprints both ends of a segment.
///
/// Stored with the travel cost, so moving or retiming either stop invalidates
/// it.
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

/// Whether the stored travel data still matches [from] and [to].
///
/// False after a reorder or edit, which shows the segment as needing a new
/// cost.
bool validSegment(TripActivity from, TripActivity to) =>
    from.date == to.date &&
    to.travelMode != 'none' &&
    to.travelFromId == from.id &&
    to.travelSignature == segmentSignature(from, to);

/// Budget summary in satang, with counts of unpriced items.
class PlanBudget {
  final int activities, transport, unknownActivities, unknownSegments;
  const PlanBudget(
    this.activities,
    this.transport,
    this.unknownActivities,
    this.unknownSegments,
  );

  /// Total of known activity and travel costs.
  int get total => activities + transport;

  /// Number of unpriced activities and segments.
  int get unknown => unknownActivities + unknownSegments;
}

/// Derives the budget from [items].
///
/// Unpriced activities and stale segments are counted as unknown, never as
/// free. The first stop of each day has no incoming segment.
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

/// Total of all known costs.
int plannedTotal(Iterable<TripActivity> activities) =>
    planBudget(activities).total;
