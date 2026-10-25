import '../../places/recommendations_sheet.dart';
import '../../places/thailand_boundary.dart';
import '../../places/curated_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/validation.dart';
import '../../../core/widgets.dart';
import '../../../core/design_system.dart';
import '../../trips/domain/trip.dart';
import '../domain/trip_activity.dart';
import '../../places/place_picker_sheet.dart';

class ActivityFormScreen extends ConsumerWidget {
  final String uid, tripId;
  final String? activityId;
  final ActivitySeed? seed;
  const ActivityFormScreen({
    super.key,
    required this.uid,
    required this.tripId,
    this.activityId,
    this.seed,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (uid: uid, tripId: tripId);
    return AsyncContent(
      screenTitle: activityId == null ? 'เพิ่มกิจกรรม' : 'แก้ไขกิจกรรม',
      value: ref.watch(tripProvider(key)),
      retry: () => ref.invalidate(tripProvider(key)),
      data: (s) {
        if (s.value == null || s.value!.status != 'active') {
          return UnavailablePage(
            title: 'กิจกรรม',
            message: 'ไม่พบทริปที่แก้ไขได้',
            onExit: () => context.go('/trips'),
          );
        }
        if (activityId == null) {
          return ActivityEditor(uid: uid, trip: s.value!, seed: seed);
        }
        return AsyncContent(
          screenTitle: activityId == null ? 'เพิ่มกิจกรรม' : 'แก้ไขกิจกรรม',
          value: ref.watch(activitiesProvider(key)),
          retry: () => ref.invalidate(activitiesProvider(key)),
          data: (a) {
            final matches = a.value.where((e) => e.id == activityId);
            return matches.isEmpty
                ? UnavailablePage(
                    title: 'กิจกรรม',
                    message: 'ไม่พบกิจกรรม',
                    onExit: () => context.go('/trips'),
                  )
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
  final ActivitySeed? seed;
  const ActivityEditor({
    super.key,
    required this.uid,
    required this.trip,
    this.initial,
    this.seed,
  });
  @override
  ConsumerState<ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends ConsumerState<ActivityEditor> {
  final form = GlobalKey<FormState>();
  late final id = widget.initial?.id ?? const Uuid().v4();
  late final title = TextEditingController(
        text: widget.initial?.title ?? widget.seed?.place?.name,
      ),
      note = TextEditingController(text: widget.initial?.note),
      cost = TextEditingController(
        text: widget.initial == null || !widget.initial!.costKnown
            ? ''
            : moneyInput(widget.initial!.estimatedCostSatang),
      );
  late String date =
      widget.initial?.date ?? widget.seed?.date ?? widget.trip.startDate;
  late int minutes = widget.initial?.timeMinutes ?? 540;
  late LatLng? point = widget.initial == null
      ? widget.seed?.selectedPoint
      : LatLng(widget.initial!.latitude, widget.initial!.longitude);
  late String category =
      widget.initial?.category ?? widget.seed?.place?.category ?? 'other';
  late CuratedPlace? chosenPlace = widget.seed?.place;
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
      final boundary = await ThailandBoundary.load();
      final unchanged =
          widget.initial != null &&
          widget.initial!.latitude == point!.latitude &&
          widget.initial!.longitude == point!.longitude;
      requireValid(
        unchanged || boundary.contains(point!),
        'กรุณาเลือกหมุดในประเทศไทย',
      );
      final items = await ref
          .read(travelRepositoryProvider)
          .watchActivities(widget.uid, widget.trip.id)
          .first;
      final peers = items.value.where((a) => a.date == date && a.id != id);
      final nextRank =
          peers.fold<int>(-1000, (n, a) => a.rank > n ? a.rank : n) + 1000;
      final rank = widget.initial?.date == date
          ? widget.initial!.rank
          : nextRank;
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
              estimatedCostSatang: cost.text.trim().isEmpty
                  ? 0
                  : parseMoney(cost.text)!,
              costKnown: cost.text.trim().isNotEmpty,
              category: category,
              orderIndex: rank,
              travelMode: widget.initial?.travelMode ?? 'none',
              travelFromId: widget.initial?.travelFromId ?? '',
              travelSignature: widget.initial?.travelSignature ?? '',
              travelCostSatang: widget.initial?.travelCostSatang ?? 0,
              travelCostKnown: widget.initial?.travelCostKnown ?? false,
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
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            const FormIntro(
              'จุดหมายของคุณ',
              'ค้นหาหรือเลือกหมุด แล้วตรวจรายละเอียดก่อนบันทึก',
            ),
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  key: const Key('search-place'),
                  icon: const Icon(Icons.search),
                  label: const Text('ค้นหาสถานที่ทั่วไทย'),
                  onPressed: busy
                      ? null
                      : () async {
                          final p = await showModalBottomSheet<CuratedPlace>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (c) => RecommendationsSheet(
                              remaining: widget.trip.budgetSatang,
                            ),
                          );
                          if (p != null && mounted) {
                            setState(() {
                              chosenPlace = p;
                              cost.clear();
                              title.text = p.name;
                              category = p.category;
                              point = null;
                            });
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('activity-title'),
                  controller: title,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'ชื่อกิจกรรม'),
                  validator: textError,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('activity-category-$category'),
                  isExpanded: true,
                  initialValue: category,
                  items: activityCategories.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => category = v!),
                  decoration: const InputDecoration(labelText: 'ประเภทสถานที่'),
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
                    labelText: 'ค่าใช้จ่ายกิจกรรมรวม (บาท)',
                    helperText:
                        'กรอกเองสำหรับทั้งกลุ่ม • ว่าง = ยังไม่ทราบราคา • ไม่รวมค่าเดินทาง',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? null : moneyError(v),
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
                if (chosenPlace != null)
                  Text(
                    'แหล่งข้อมูล: ${chosenPlace!.source} • ข้อมูล ณ ${chosenPlace!.checkedAt}\nพิกัดอาจไม่ใช่ทางเข้า กรุณาตรวจและยืนยันก่อนบันทึก',
                  ),
                OutlinedButton.icon(
                  key: const Key('pick-place'),
                  onPressed: busy
                      ? null
                      : () async {
                          final p = await pickPlace(
                            context,
                            point ?? chosenPlace?.point,
                          );
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
