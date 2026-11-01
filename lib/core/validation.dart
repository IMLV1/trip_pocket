// ฟังก์ชันกลางสำหรับแปลงและตรวจเงิน วันที่ เวลา ข้อความ อีเมล และรหัสผ่าน
// เงินในแอปเก็บเป็นสตางค์จำนวนเต็ม

import 'package:intl/intl.dart';

const maxMoney = 1000000000;
int? parseMoney(String value) {
  final s = value.trim();
  if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final amount =
      int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return amount <= maxMoney ? amount : null;
}

String money(int value) => NumberFormat('#,##0.00', 'en').format(value / 100);
String moneyInput(int value) =>
    '${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
bool validDate(String s) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return false;
  final d = DateTime.tryParse(s);
  return d != null && d.year >= 1900 && d.year <= 2100 && dateKey(d) == s;
}

String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
String? textError(String? s, [int max = 100]) => s == null || s.trim().isEmpty
    ? 'กรุณากรอกข้อมูล'
    : s.trim().runes.length > max
    ? 'ไม่เกิน $max ตัวอักษร'
    : null;
String? moneyError(String? s) => parseMoney(s ?? '') == null
    ? 'กรอกเงิน 0–10,000,000 บาท ทศนิยมไม่เกิน 2 ตำแหน่ง'
    : null;
String? emailError(String? s) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((s ?? '').trim())
    ? null
    : 'กรอกอีเมลให้ถูกต้อง';
String? passwordError(String? s) =>
    (s ?? '').length >= 6 ? null : 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
void requireValid(bool condition, String message) {
  if (!condition) throw StateError(message);
}
