// หน้าสร้างและแก้ไขทริป: ชื่อ จุดหมาย หมุดพื้นที่หลัก วันที่ และงบประมาณ
// วันสิ้นสุดต้องอยู่หลังวันเริ่มอย่างน้อย 1 วัน

import 'package:latlong2/latlong.dart';
import '../../places/place_picker_sheet.dart';
import '../../places/curated_places.dart';
import '../../places/recommendations_sheet.dart';
import '../../places/destination_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/validation.dart';
import '../../../core/widgets.dart';
import '../../../core/design_system.dart';
import '../domain/trip.dart';

class TripFormScreen extends ConsumerWidget {
  final String uid;
  final String? tripId;
  const TripFormScreen({super.key, required this.uid, this.tripId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tripId == null) return TripEditor(uid: uid);
    final key = (uid: uid, tripId: tripId!);
    return AsyncContent(
      screenTitle: 'แก้ไขทริป',
      value: ref.watch(tripProvider(key)),
      retry: () => ref.invalidate(tripProvider(key)),
      data: (s) => s.value == null || s.value!.status != 'active'
          ? UnavailablePage(
              title: 'แก้ไขทริป',
              message: 'ไม่พบทริปที่แก้ไขได้',
              onExit: () => context.go('/trips'),
            )
          : TripEditor(key: ValueKey(tripId), uid: uid, initial: s.value),
    );
  }
}

class TripEditor extends ConsumerStatefulWidget {
  final String uid;
  final Trip? initial;
  const TripEditor({super.key, required this.uid, this.initial});
  @override
  ConsumerState<TripEditor> createState() => _TripEditorState();
}

class _TripEditorState extends ConsumerState<TripEditor> {
  final form = GlobalKey<FormState>();
  late final id = widget.initial?.id ?? const Uuid().v4();
  late final title = TextEditingController(text: widget.initial?.title),
      destination = TextEditingController(text: widget.initial?.destination),
      budget = TextEditingController(
        text: moneyInput(widget.initial?.budgetSatang ?? 0),
      );
  late String start = widget.initial?.startDate ?? dateKey(DateTime.now()),
      end =
          widget.initial?.endDate ??
          dateKey(DateTime.parse(start).add(const Duration(days: 1)));
  bool busy = false, selecting = false;
  late LatLng? destinationPoint = widget.initial?.hasDestinationPin == true
      ? LatLng(
          widget.initial!.destinationLatitude!,
          widget.initial!.destinationLongitude!,
        )
      : null;
  Future<void> chooseDestination({bool search = false}) async {
    if (busy || selecting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => selecting = true);
    try {
      CuratedPlace? place;
      if (search) {
        place = await showModalBottomSheet<CuratedPlace>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) =>
              RecommendationsSheet(remaining: parseMoney(budget.text) ?? 0),
        );
        if (place == null || !mounted) return;
      }
      if (!mounted) return;
      final point = await pickPlace(context, place?.point ?? destinationPoint);
      if (point == null || !mounted) return;
      setState(() {
        destinationPoint = point;
        if (place != null) destination.text = place.name;
        if (destination.text.trim().isEmpty) {
          destination.text = 'พื้นที่ที่เลือก';
        }
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => selecting = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    destination.dispose();
    budget.dispose();
    super.dispose();
  }

  Future<void> pick(bool first) async {
    final minimum = first
        ? DateTime(1900)
        : DateTime.parse(start).add(const Duration(days: 1));
    final maximum = first ? DateTime(2100, 12, 30) : DateTime(2100, 12, 31);
    if (minimum.isAfter(maximum)) {
      showError(context, StateError('กรุณาเลือกวันเริ่มก่อน 31 ธันวาคม 2100'));
      return;
    }
    final old = DateTime.parse(first ? start : end);
    final initial = old.isBefore(minimum)
        ? minimum
        : old.isAfter(maximum)
        ? maximum
        : old;
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minimum,
      lastDate: maximum,
    );
    if (value != null && mounted) {
      setState(() {
        if (first) {
          start = dateKey(value);
          if (end.compareTo(start) <= 0) {
            end = dateKey(value.add(const Duration(days: 1)));
          }
        } else {
          end = dateKey(value);
        }
      });
    }
  }

  Future<void> save() async {
    if (busy || selecting || !form.currentState!.validate()) return;
    if (end.compareTo(start) <= 0) {
      showError(
        context,
        StateError('วันสิ้นสุดต้องหลังวันเริ่มอย่างน้อย 1 วัน'),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(travelRepositoryProvider)
          .saveTrip(
            widget.uid,
            Trip(
              id: id,
              completed: widget.initial?.completed ?? false,
              title: title.text,
              destination: destination.text,
              destinationLatitude: destinationPoint?.latitude,
              destinationLongitude: destinationPoint?.longitude,
              startDate: start,
              endDate: end,
              budgetSatang: parseMoney(budget.text)!,
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
        title: Text(widget.initial == null ? 'สร้างทริป' : 'แก้ไขทริป'),
      ),
      body: PageBody(
        children: [
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            const FormIntro(
              'เริ่มต้นการเดินทาง',
              'ตั้งชื่อทริป เลือกวัน และงบที่อยากใช้',
            ),
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('trip-title'),
                  controller: title,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'ชื่อทริป'),
                  validator: textError,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('destination'),
                  controller: destination,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'จังหวัด / พื้นที่ที่จะไป',
                    hintText: 'เช่น เชียงใหม่ หรือชื่อสถานที่',
                    helperText: 'ชื่อนี้เป็นป้ายกำกับ เปลี่ยนชื่อไม่ย้ายหมุด',
                  ),
                  validator: textError,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('search-destination'),
                  onPressed: busy || selecting
                      ? null
                      : () => chooseDestination(search: true),
                  icon: const Icon(Icons.search),
                  label: const Text('ค้นหาสถานที่ / จังหวัด'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('pick-destination'),
                  onPressed: busy || selecting ? null : chooseDestination,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    selecting
                        ? 'กำลังเปิดแผนที่…'
                        : destinationPoint == null
                        ? 'เลือกพื้นที่บนแผนที่'
                        : 'เปลี่ยนตำแหน่งหมุด',
                  ),
                ),
                if (destinationPoint != null) ...[
                  const SizedBox(height: 12),
                  DestinationPreview(
                    key: const Key('destination-preview'),
                    point: destinationPoint!,
                    label: destination.text,
                  ),
                  Text(
                    '${destinationPoint!.latitude.toStringAsFixed(4)}, ${destinationPoint!.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    key: const Key('clear-destination-pin'),
                    onPressed: busy || selecting
                        ? null
                        : () => setState(() => destinationPoint = null),
                    child: const Text('เอาหมุดพื้นที่หลักออก'),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ยังไม่มีหมุดพื้นที่หลัก • ค้นหาหรือแตะแผนที่เพื่อระบุตำแหน่ง',
                    ),
                  ),
                const Text(
                  'หมุดนี้ระบุพื้นที่หลักของทริป ส่วนร้านอาหาร ที่พัก และจุดแวะเพิ่มในแผนรายวันได้',
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('trip-start-date'),
                  title: const Text('วันเริ่ม'),
                  subtitle: Text(start),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: busy ? null : () => pick(true),
                ),
                ListTile(
                  key: const Key('trip-end-date'),
                  title: const Text('วันสิ้นสุด'),
                  subtitle: Text(end),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: busy ? null : () => pick(false),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('budget'),
                  controller: budget,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'งบประมาณ (บาท)',
                  ),
                  validator: moneyError,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('save-trip'),
                  onPressed: busy || selecting ? null : save,
                  child: Text(busy ? 'กำลังบันทึก…' : 'บันทึกทริป'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
