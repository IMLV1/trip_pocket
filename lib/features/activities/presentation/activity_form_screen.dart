import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/validation.dart';
import '../../../core/widgets.dart';
import '../../trips/domain/trip.dart';
import '../domain/trip_activity.dart';
import '../../places/place_picker_sheet.dart';

class ActivityFormScreen extends ConsumerWidget {
  final String uid, tripId;
  final String? activityId;
  const ActivityFormScreen({
    super.key,
    required this.uid,
    required this.tripId,
    this.activityId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (uid: uid, tripId: tripId);
    return AsyncContent(
      value: ref.watch(tripProvider(key)),
      retry: () => ref.invalidate(tripProvider(key)),
      data: (s) {
        if (s.value == null || s.value!.status != 'active') {
          return const Scaffold(
            body: Center(child: Text('ไม่พบทริปที่แก้ไขได้')),
          );
        }
        if (activityId == null) return ActivityEditor(uid: uid, trip: s.value!);
        return AsyncContent(
          value: ref.watch(activitiesProvider(key)),
          retry: () => ref.invalidate(activitiesProvider(key)),
          data: (a) {
            final matches = a.value.where((e) => e.id == activityId);
            return matches.isEmpty
                ? const Scaffold(body: Center(child: Text('ไม่พบกิจกรรม')))
                : ActivityEditor(
                    key: ValueKey(activityId),
                    uid: uid,
                    trip: s.value!,
                    initial: matches.first,
                  );
          },
        );
      },
    );
  }
}

class ActivityEditor extends ConsumerStatefulWidget {
  final String uid;
  final Trip trip;
  final TripActivity? initial;
  const ActivityEditor({
    super.key,
    required this.uid,
    required this.trip,
    this.initial,
  });
  @override
  ConsumerState<ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends ConsumerState<ActivityEditor> {
  final form = GlobalKey<FormState>();
  late final id = widget.initial?.id ?? const Uuid().v4();
  late final title = TextEditingController(text: widget.initial?.title),
      note = TextEditingController(text: widget.initial?.note),
      cost = TextEditingController(
        text: moneyInput(widget.initial?.estimatedCostSatang ?? 0),
      );
  late String date = widget.initial?.date ?? widget.trip.startDate;
  late int minutes = widget.initial?.timeMinutes ?? 540;
  late LatLng? point = widget.initial == null
      ? null
      : LatLng(widget.initial!.latitude, widget.initial!.longitude);
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    note.dispose();
    cost.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (point == null) {
      showError(context, StateError('กรุณาเลือกและยืนยันตำแหน่ง'));
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(travelRepositoryProvider)
          .saveActivity(
            widget.uid,
            widget.trip.id,
            TripActivity(
              id: id,
              title: title.text,
              date: date,
              timeMinutes: minutes,
              estimatedCostSatang: parseMoney(cost.text)!,
              latitude: point!.latitude,
              longitude: point!.longitude,
              note: note.text,
            ),
            create: widget.initial == null,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'เพิ่มกิจกรรม' : 'แก้ไขกิจกรรม'),
      ),
      body: PageBody(
        children: [
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('activity-title'),
                  controller: title,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'ชื่อกิจกรรม'),
                  validator: textError,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('วันที่'),
                  subtitle: Text(date),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(date),
                            firstDate: DateTime.parse(widget.trip.startDate),
                            lastDate: DateTime.parse(widget.trip.endDate),
                          );
                          if (picked != null && mounted) {
                            setState(() => date = dateKey(picked));
                          }
                        },
                ),
                ListTile(
                  title: const Text('เวลา'),
                  subtitle: Text(clockText(minutes)),
                  trailing: const Icon(Icons.schedule),
                  onTap: busy
                      ? null
                      : () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: minutes ~/ 60,
                              minute: minutes % 60,
                            ),
                          );
                          if (t != null && mounted) {
                            setState(() => minutes = t.hour * 60 + t.minute);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('activity-cost'),
                  controller: cost,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'ค่าใช้จ่ายประมาณ (บาท)',
                  ),
                  validator: moneyError,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: note,
                  enabled: !busy,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ (ไม่แชร์ออกไป)',
                  ),
                  validator: (s) => (s ?? '').runes.length <= 500
                      ? null
                      : 'ไม่เกิน 500 ตัวอักษร',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('pick-place'),
                  onPressed: busy
                      ? null
                      : () async {
                          final p = await pickPlace(context, point);
                          if (p != null && mounted) setState(() => point = p);
                        },
                  icon: const Icon(Icons.map),
                  label: Text(
                    point == null
                        ? 'เลือกตำแหน่งบนแผนที่'
                        : 'เปลี่ยนหมุด ${point!.latitude.toStringAsFixed(4)}, ${point!.longitude.toStringAsFixed(4)}',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('save-activity'),
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'กำลังบันทึก…' : 'บันทึกกิจกรรม'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
