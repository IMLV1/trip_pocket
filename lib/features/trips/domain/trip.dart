// Trip model and snapshot metadata. Validation here mirrors firestore.rules,
// which remain the real enforcement point.

import '../../../core/validation.dart';

/// A trip. `status` is `active` or `deleting`.
class Trip {
  final String id, title, destination, startDate, endDate, status;
  final int budgetSatang;
  final bool completed;
  final double? destinationLatitude, destinationLongitude;
  final DateTime? createdAt, updatedAt;
  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budgetSatang,
    this.destinationLatitude,
    this.destinationLongitude,
    this.completed = false,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  /// Decodes stored fields.
  factory Trip.fromFields(
    String id,
    Map<String, dynamic> d, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Trip(
    id: id,
    title: d['title'],
    destination: d['destination'],
    startDate: d['startDate'],
    endDate: d['endDate'],
    budgetSatang: d['budgetSatang'],
    status: d['status'],
    completed: d['completed'] as bool? ?? false,
    destinationLatitude: (d['destinationLatitude'] as num?)?.toDouble(),
    destinationLongitude: (d['destinationLongitude'] as num?)?.toDouble(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// Whether a main destination pin is set.
  bool get hasDestinationPin =>
      destinationLatitude != null && destinationLongitude != null;

  /// Throws unless the pin, text, dates and budget are valid.
  ///
  /// The end date must be at least one day after the start date.
  void validate() {
    requireValid(
      (destinationLatitude == null && destinationLongitude == null) ||
          (hasDestinationPin &&
              destinationLatitude!.isFinite &&
              destinationLongitude!.isFinite &&
              destinationLatitude! >= -90 &&
              destinationLatitude! <= 90 &&
              destinationLongitude! >= -180 &&
              destinationLongitude! <= 180),
      'พิกัดพื้นที่หลักไม่ถูกต้อง',
    );
    requireValid(
      textError(title) == null && textError(destination) == null,
      'ชื่อและจุดหมายต้องมี 1–100 ตัวอักษร',
    );
    requireValid(
      validDate(startDate) &&
          validDate(endDate) &&
          startDate.compareTo(endDate) < 0,
      'วันสิ้นสุดต้องหลังวันเริ่มอย่างน้อย 1 วัน',
    );
    requireValid(
      budgetSatang >= 0 && budgetSatang <= maxMoney,
      'งบประมาณไม่ถูกต้อง',
    );
  }

  /// Encodes the fields to store.
  Map<String, dynamic> fields() => {
    'title': title.trim(),
    'destination': destination.trim(),
    'destinationLatitude': destinationLatitude,
    'destinationLongitude': destinationLongitude,
    'startDate': startDate,
    'endDate': endDate,
    'budgetSatang': budgetSatang,
    'status': status,
    'completed': completed,
  };
}

/// A value with its cache and pending-write state.
///
/// Screens use this to label stale data and disable actions during a write.
class DataSnapshot<T> {
  final T value;
  final bool cached, pending;
  const DataSnapshot(this.value, {this.cached = false, this.pending = false});
}
