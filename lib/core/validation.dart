// Parsing, formatting and validation helpers.

import 'package:intl/intl.dart';

/// Maximum amount in satang (10,000,000 baht).
const maxMoney = 1000000000;

/// Parses baht text into satang. Returns null if malformed or over [maxMoney].
int? parseMoney(String value) {
  final s = value.trim();
  if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final amount =
      int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return amount <= maxMoney ? amount : null;
}

/// Formats satang as baht for display.
String money(int value) => NumberFormat('#,##0.00', 'en').format(value / 100);

/// Formats satang as baht for a text field.
String moneyInput(int value) =>
    '${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';

/// Formats a date as YYYY-MM-DD.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Whether [s] is a real YYYY-MM-DD date between 1900 and 2100.
bool validDate(String s) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return false;
  final d = DateTime.tryParse(s);
  return d != null && d.year >= 1900 && d.year <= 2100 && dateKey(d) == s;
}

/// Formats minutes from midnight as HH:MM.
String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// Validates required text of at most [max] characters.
String? textError(String? s, [int max = 100]) => s == null || s.trim().isEmpty
    ? 'กรุณากรอกข้อมูล'
    : s.trim().runes.length > max
    ? 'ไม่เกิน $max ตัวอักษร'
    : null;

/// Validates a money field.
String? moneyError(String? s) => parseMoney(s ?? '') == null
    ? 'กรอกเงิน 0–10,000,000 บาท ทศนิยมไม่เกิน 2 ตำแหน่ง'
    : null;

/// Validates an email address.
String? emailError(String? s) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((s ?? '').trim())
    ? null
    : 'กรอกอีเมลให้ถูกต้อง';

/// Validates minimum password length.
String? passwordError(String? s) =>
    (s ?? '').length >= 6 ? null : 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';

/// Throws a [StateError] with [message] unless [condition] holds.
void requireValid(bool condition, String message) {
  if (!condition) throw StateError(message);
}
