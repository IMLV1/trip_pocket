// Device-local packing checklist storage.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One checklist entry.
class PackingItem {
  final String id, text;
  final bool checked;
  const PackingItem(this.id, this.text, this.checked);

  /// Encodes for local storage.
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'checked': checked};

  /// Returns a copy with `checked` flipped.
  PackingItem toggle() => PackingItem(id, text, !checked);
}

/// SharedPreferences store, scoped by uid and tripId.
class PackingRepository {
  final SharedPreferences prefs;
  PackingRepository(this.prefs);

  /// Storage key for one trip.
  String key(String uid, String tripId) => 'packing.v1.$uid.$tripId';

  /// Loads the list. Throws [FormatException] on corrupt data.
  Future<List<PackingItem>> load(String uid, String tripId) async {
    final raw = prefs.getString(key(uid, tripId));
    if (raw == null) return [];
    try {
      final items = jsonDecode(raw) as List;
      return items.map((e) {
        if (e is! Map ||
            e['id'] is! String ||
            e['text'] is! String ||
            (e['text'] as String).trim().isEmpty ||
            e['checked'] is! bool) {
          throw const FormatException();
        }
        return PackingItem(e['id'], e['text'], e['checked']);
      }).toList();
    } catch (_) {
      throw const FormatException(
        'ข้อมูลเช็กลิสต์ในเครื่องเสียหาย ยังไม่ได้เขียนทับข้อมูลเดิม',
      );
    }
  }

  /// Saves the list. Refuses to overwrite corrupt data.
  Future<void> save(String uid, String tripId, List<PackingItem> items) async {
    if (items.any((e) => e.text.trim().isEmpty)) {
      throw const FormatException('รายการเตรียมของต้องไม่ว่าง');
    }
    await load(uid, tripId); // Never silently overwrite corrupt data.
    if (!await prefs.setString(
      key(uid, tripId),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    )) {
      throw StateError('บันทึกในเครื่องไม่สำเร็จ');
    }
  }

  /// Trip ids awaiting local cleanup.
  List<String> cleanupQueue(String uid) =>
      prefs.getStringList('packingCleanup.v1.$uid') ?? [];

  /// Records the intent to delete before the cloud delete starts.
  Future<void> queueCleanup(String uid, String tripId) async {
    final ids = {...cleanupQueue(uid), tripId}.toList();
    if (!await prefs.setStringList('packingCleanup.v1.$uid', ids)) {
      throw StateError('บันทึกคิวลบไม่สำเร็จ');
    }
  }

  /// Removes the local checklist and its queue entry.
  Future<void> finishCleanup(String uid, String tripId) async {
    if (!await prefs.remove(key(uid, tripId))) {
      throw StateError('ล้างเช็กลิสต์ไม่สำเร็จ');
    }
    if (!await prefs.setStringList(
      'packingCleanup.v1.$uid',
      cleanupQueue(uid).where((s) => s != tripId).toList(),
    )) {
      throw StateError('ล้างคิวไม่สำเร็จ');
    }
  }
}
