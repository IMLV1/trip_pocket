// Maps errors to user-facing Thai messages.

import 'package:firebase_core/firebase_core.dart';

/// Returns a Thai message suitable for showing to the user.
String errorText(Object e) {
  if (e is FirebaseException) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'requires-recent-login' =>
        'กรุณาเข้าสู่ระบบใหม่เพื่อยืนยันตัวตนก่อนทำรายการ',
      'operation-not-allowed' => 'ยังไม่ได้เปิดวิธีเข้าสู่ระบบนี้ใน Firebase',
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        'บัญชีนี้เชื่อมกับวิธีเข้าสู่ระบบอื่นอยู่ กรุณาเข้าด้วยวิธีเดิมก่อน',
      'provider-already-linked' => 'บัญชี Google นี้เชื่อมต่อแล้ว',
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
