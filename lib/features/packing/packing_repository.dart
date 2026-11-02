// Packing checklist storage. [PackingStore] is what the UI uses; the live and
// emulator modes store the list in Firestore at
// `users/{uid}/trips/{tripId}/packing/checklist`, while demo mode keeps it in
// SharedPreferences. The local store also owns the trip cleanup queue.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maximum number of items in one checklist. Mirrored in firestore.rules.
const maxPackingItems = 200;

/// One checklist entry.
class PackingItem {
  final String id, text;
  final bool checked;
  const PackingItem(this.id, this.text, this.checked);

  /// Encodes for local storage.
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'checked': checked};

  /// Returns a copy with `checked` flipped.
  PackingItem toggle() => PackingItem(id, text, !checked);

  /// Decodes one stored entry, or throws [FormatException].
  static PackingItem fromJson(Object? e) {
    if (e is! Map ||
        e['id'] is! String ||
        e['text'] is! String ||
        (e['text'] as String).trim().isEmpty ||
        e['checked'] is! bool) {
      throw const FormatException();
    }
    return PackingItem(e['id'], e['text'], e['checked']);
  }
}

/// Rejects lists that the rules or decoders would refuse.
void validatePackingItems(List<PackingItem> items) {
  if (items.any((e) => e.text.trim().isEmpty)) {
    throw const FormatException('รายการเตรียมของต้องไม่ว่าง');
  }
  if (items.any((e) => e.text.length > 100)) {
    throw const FormatException('รายการเตรียมของยาวเกิน 100 ตัวอักษร');
  }
  if (items.length > maxPackingItems) {
    throw const FormatException(
      'เช็กลิสต์มีได้ไม่เกิน $maxPackingItems รายการ',
    );
  }
}

/// Checklist storage used by the packing UI.
abstract class PackingStore {
  /// Whether the list is stored only on this device.
  bool get deviceOnly;

  /// Loads the list of one trip.
  Future<List<PackingItem>> load(String uid, String tripId);

  /// Replaces the list of one trip.
  Future<void> save(String uid, String tripId, List<PackingItem> items);
}

/// SharedPreferences store, scoped by uid and tripId.
class PackingRepository implements PackingStore {
  final SharedPreferences prefs;
  PackingRepository(this.prefs);

  @override
  bool get deviceOnly => true;

  /// Storage key for one trip.
  String key(String uid, String tripId) => 'packing.v1.$uid.$tripId';

  /// Loads the list.
  ///
  /// Throws [FormatException] on corrupt data instead of returning an empty
  /// list, which would let the next save erase it.
  @override
  Future<List<PackingItem>> load(String uid, String tripId) async {
    final raw = prefs.getString(key(uid, tripId));
    if (raw == null) return [];
    try {
      final items = jsonDecode(raw) as List;
      return items.map(PackingItem.fromJson).toList();
    } catch (_) {
      throw const FormatException(
        'ข้อมูลเช็กลิสต์ในเครื่องเสียหาย ยังไม่ได้เขียนทับข้อมูลเดิม',
      );
    }
  }

  /// Saves the list.
  ///
  /// Loads first so that corrupt data is reported rather than overwritten.
  @override
  Future<void> save(String uid, String tripId, List<PackingItem> items) async {
    validatePackingItems(items);
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
  ///
  /// Lets cleanup finish on a later launch if the app is killed midway.
  Future<void> queueCleanup(String uid, String tripId) async {
    final ids = {...cleanupQueue(uid), tripId}.toList();
    if (!await prefs.setStringList('packingCleanup.v1.$uid', ids)) {
      throw StateError('บันทึกคิวลบไม่สำเร็จ');
    }
  }

  /// Removes the local checklist only, keeping the cleanup queue.
  Future<void> clear(String uid, String tripId) async {
    if (!await prefs.remove(key(uid, tripId))) {
      throw StateError('ล้างเช็กลิสต์ในเครื่องไม่สำเร็จ');
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

/// Firestore store at `users/{uid}/trips/{tripId}/packing/checklist`.
///
/// A list saved by an older version on this device is uploaded the first time
/// the trip has no cloud checklist, then removed locally.
class FirestorePackingRepository implements PackingStore {
  final FirebaseFirestore db;
  final PackingRepository local;
  FirestorePackingRepository(this.db, this.local);

  @override
  bool get deviceOnly => false;

  /// Parent trip document.
  DocumentReference<Map<String, dynamic>> trip(String uid, String tripId) =>
      db.collection('users').doc(uid).collection('trips').doc(tripId);

  /// Checklist document of one trip.
  DocumentReference<Map<String, dynamic>> doc(String uid, String tripId) =>
      trip(uid, tripId).collection('packing').doc('checklist');

  /// Decodes the `items` field, or throws [FormatException].
  List<PackingItem> decode(Map<String, dynamic>? d) {
    try {
      final items = d?['items'];
      if (items is! List) throw const FormatException();
      return items.map(PackingItem.fromJson).toList();
    } catch (_) {
      throw const FormatException(
        'ข้อมูลเช็กลิสต์บนคลาวด์เสียหาย ยังไม่ได้เขียนทับข้อมูลเดิม',
      );
    }
  }

  @override
  Future<List<PackingItem>> load(String uid, String tripId) async {
    final snap = await doc(uid, tripId).get();
    if (snap.exists) return decode(snap.data());
    return _migrateLocal(uid, tripId);
  }

  /// Uploads a list left on this device by an older version.
  ///
  /// Corrupt local data is left untouched and treated as empty, so it never
  /// blocks the cloud checklist.
  Future<List<PackingItem>> _migrateLocal(String uid, String tripId) async {
    List<PackingItem> items;
    try {
      items = await local.load(uid, tripId);
    } on FormatException {
      return [];
    }
    if (items.isEmpty) return [];
    try {
      validatePackingItems(items);
    } on FormatException {
      return [];
    }
    final uploaded = await _write(uid, tripId, items, onlyIfMissing: true);
    if (uploaded == null) {
      await local.clear(uid, tripId);
      return items;
    }
    // Another device created the cloud list first; keep the cloud copy.
    return uploaded;
  }

  @override
  Future<void> save(String uid, String tripId, List<PackingItem> items) async {
    validatePackingItems(items);
    await _write(uid, tripId, items);
  }

  /// Writes the list in a transaction that requires an active parent trip.
  ///
  /// With [onlyIfMissing], returns the existing cloud list instead of
  /// overwriting it; otherwise returns null after writing.
  Future<List<PackingItem>?> _write(
    String uid,
    String tripId,
    List<PackingItem> items, {
    bool onlyIfMissing = false,
  }) => db.runTransaction((tx) async {
    final parent = await tx.get(trip(uid, tripId));
    if (!parent.exists || parent.data()?['status'] != 'active') {
      throw StateError('ทริปไม่พร้อมแก้ไข');
    }
    final ref = doc(uid, tripId);
    final old = await tx.get(ref);
    if (old.exists) {
      // Never silently overwrite corrupt cloud data.
      final current = decode(old.data());
      if (onlyIfMissing) return current;
    }
    tx.set(ref, {
      'items': items.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return null;
  });
}
