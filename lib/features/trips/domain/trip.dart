import '../../../core/validation.dart';

class Trip {
  final String id, title, destination, startDate, endDate, status;
  final int budgetSatang;
  final DateTime? createdAt, updatedAt;
  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budgetSatang,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });
  void validate() {
    requireValid(
      textError(title) == null && textError(destination) == null,
      'ชื่อและจุดหมายต้องมี 1–100 ตัวอักษร',
    );
    requireValid(
      validDate(startDate) &&
          validDate(endDate) &&
          startDate.compareTo(endDate) <= 0,
      'ช่วงวันที่ไม่ถูกต้อง',
    );
    requireValid(
      budgetSatang >= 0 && budgetSatang <= maxMoney,
      'งบประมาณไม่ถูกต้อง',
    );
  }

  Map<String, dynamic> fields() => {
    'title': title.trim(),
    'destination': destination.trim(),
    'startDate': startDate,
    'endDate': endDate,
    'budgetSatang': budgetSatang,
    'status': status,
  };
}

class DataSnapshot<T> {
  final T value;
  final bool cached, pending;
  const DataSnapshot(this.value, {this.cached = false, this.pending = false});
}
