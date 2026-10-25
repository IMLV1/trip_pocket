import 'package:firebase_core/firebase_core.dart';

String errorText(Object e) {
  if (e is FirebaseException) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'email-already-in-use' => 'อีเมลนี้มีบัญชีแล้ว',
      'weak-password' => 'รหัสผ่านไม่ปลอดภัยพอ',
      'network-request-failed' ||
      'unavailable' => 'เชื่อมต่อไม่ได้ กรุณาตรวจอินเทอร์เน็ตแล้วลองใหม่',
      'permission-denied' => 'ไม่มีสิทธิ์เข้าถึง หรือข้อมูลไม่ผ่านกฎการบันทึก',
      'too-many-requests' => 'ทำรายการถี่เกินไป กรุณาลองภายหลัง',
      _ => 'ทำรายการไม่สำเร็จ (${e.code})',
    };
  }
  if (e is StateError) return e.message.toString();
  if (e is FormatException) return e.message;
  return 'ทำรายการไม่สำเร็จ กรุณาลองใหม่';
}
