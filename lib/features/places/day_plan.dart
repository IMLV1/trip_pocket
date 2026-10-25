import 'curated_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';
import '../activities/domain/trip_activity.dart';
import '../trips/domain/trip.dart';
import 'daily_map.dart';
import 'navigation_service.dart';

class DayPlan extends ConsumerStatefulWidget {
  final String uid;
  final Trip trip;
  final List<TripActivity> activities;
  final bool disabled;
  final Future<void> Function(TripActivity) onDelete;
  const DayPlan({
    super.key,
    required this.uid,
    required this.trip,
    required this.activities,
    required this.onDelete,
    this.disabled = false,
  });
  @override
  ConsumerState<DayPlan> createState() => _DayPlanState();
}

class _DayPlanState extends ConsumerState<DayPlan> {
  bool working = false;
  Future<void> run(Future<void> Function() action) async {
    if (working || widget.disabled) return;
    setState(() => working = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  void edit(TripActivity a) {
    if (!working && !widget.disabled) {
      context.push('/trips/${widget.trip.id}/activities/${a.id}/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = sortedActivities(widget.activities);
    final disabled = working || widget.disabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.isNotEmpty)
          DailyMap(
            activities: list,
            onSelect: edit,
            onAdd: disabled
                ? null
                : (p) => context.push(
                    '/trips/${widget.trip.id}/activities/new',
                    extra: ActivitySeed.pin(p, list.first.date),
                  ),
          ),
        if (list.asMap().entries.any(
          (e) => e.key > 0 && list[e.key - 1].timeMinutes > e.value.timeMinutes,
        ))
          const Text(
            'เวลาไม่เรียงตามลำดับจุดหมาย กรุณาตรวจและแก้เวลาก่อนเดินทาง',
          ),
        if (list.length > 100)
          const Text('เรียงได้ครั้งละไม่เกิน 100 จุดต่อวัน'),
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0)
            Card(
              child: ListTile(
                title: Text('${list[i - 1].title} → ${list[i].title}'),
                subtitle: Text(
                  validSegment(list[i - 1], list[i])
                      ? '${travelModes[list[i].travelMode]} • ${list[i].travelCostKnown ? '${money(list[i].travelCostSatang)} บาท (กรอกเอง)' : 'ยังไม่ทราบราคา'}'
                      : 'ยังไม่กำหนด หรือจุด/เวลาเปลี่ยนแล้ว • ยังไม่ทราบราคา',
                ),
                trailing: IconButton(
                  key: ValueKey('travel-${list[i].id}'),
                  tooltip: 'กำหนดการเดินทาง',
                  onPressed: disabled
                      ? null
                      : () => run(() async {
                          final result =
                              await showModalBottomSheet<TripActivity>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (c) => TravelEditor(
                                  from: list[i - 1],
                                  to: list[i],
                                ),
                              );
                          if (result != null) {
                            await ref
                                .read(travelRepositoryProvider)
                                .saveActivity(
                                  widget.uid,
                                  widget.trip.id,
                                  result,
                                  create: false,
                                );
                          }
                        }),
                  icon: const Icon(Icons.directions_bus),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: categoryColor(list[i].category),
                      foregroundColor: Colors.white,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(
                      '${clockText(list[i].timeMinutes)}  ${list[i].title}',
                    ),
                    subtitle: Text(
                      '${activityCategories[list[i].category]} • ${list[i].costKnown ? '${money(list[i].estimatedCostSatang)} บาท' : 'ยังไม่ทราบราคา'}${list[i].note.isEmpty ? '' : '\n${list[i].note}'}',
                    ),
                    onTap: disabled ? null : () => edit(list[i]),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        key: ValueKey('up-${list[i].id}'),
                        tooltip: 'เลื่อนขึ้น',
                        onPressed: disabled || i == 0 || list.length > 100
                            ? null
                            : () => run(() async {
                                final reordered = [...list];
                                final a = reordered.removeAt(i);
                                reordered.insert(i - 1, a);
                                await ref
                                    .read(travelRepositoryProvider)
                                    .reorderActivities(
                                      widget.uid,
                                      widget.trip.id,
                                      reordered,
                                    );
                              }),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        key: ValueKey('down-${list[i].id}'),
                        tooltip: 'เลื่อนลง',
                        onPressed:
                            disabled ||
                                i == list.length - 1 ||
                                list.length > 100
                            ? null
                            : () => run(() async {
                                final reordered = [...list];
                                final a = reordered.removeAt(i);
                                reordered.insert(i + 1, a);
                                await ref
                                    .read(travelRepositoryProvider)
                                    .reorderActivities(
                                      widget.uid,
                                      widget.trip.id,
                                      reordered,
                                    );
                              }),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      TextButton.icon(
                        key: ValueKey('navigate-${list[i].id}'),
                        onPressed: disabled
                            ? null
                            : () => run(
                                () => ref
                                    .read(navigationProvider)
                                    .open(
                                      list[i],
                                      from: i == 0 ? null : list[i - 1],
                                    ),
                              ),
                        icon: const Icon(Icons.navigation),
                        label: const Text('นำทาง'),
                      ),
                      IconButton(
                        tooltip: 'ลบกิจกรรม',
                        onPressed: disabled
                            ? null
                            : () => run(() => widget.onDelete(list[i])),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (list.length > 1)
          const Text(
            'ลำดับกำหนดเอง เวลาเดิมไม่ถูกเลื่อนอัตโนมัติ • กดนำทางเปิด Maps ภายนอก ไม่มีผลเส้นทาง/ราคาส่งกลับ',
          ),
      ],
    );
  }
}

class TravelEditor extends StatefulWidget {
  final TripActivity from, to;
  const TravelEditor({super.key, required this.from, required this.to});
  @override
  State<TravelEditor> createState() => _TravelEditorState();
}

class _TravelEditorState extends State<TravelEditor> {
  final form = GlobalKey<FormState>();
  late String mode = validSegment(widget.from, widget.to)
      ? widget.to.travelMode
      : 'none';
  late final cost = TextEditingController(
    text: validSegment(widget.from, widget.to) && widget.to.travelCostKnown
        ? moneyInput(widget.to.travelCostSatang)
        : '',
  );
  @override
  void dispose() {
    cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.from.title} → ${widget.to.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'ราคาเดินทางรวมทั้งกลุ่มสำหรับช่วงนี้ กรอกเอง ไม่ใช่ค่าโดยสารจากผู้ให้บริการ\nมอเตอร์ไซค์: Maps ภายนอกอาจใช้เส้นทางรถยนต์ ให้ตรวจโหมดใน Maps อีกครั้ง',
            ),
            DropdownButtonFormField<String>(
              key: const Key('travel-mode'),
              initialValue: mode,
              items: travelModes.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => mode = v!),
              decoration: const InputDecoration(labelText: 'วิธีเดินทาง'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('travel-cost'),
              controller: cost,
              enabled: mode != 'none',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'ค่าเดินทาง (บาท)',
                helperText:
                    'เว้นว่าง = ยังไม่ทราบราคา • 0 = ยืนยันว่าไม่มีค่าใช้จ่าย',
              ),
              validator: (v) => mode == 'none' || (v ?? '').trim().isEmpty
                  ? null
                  : moneyError(v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-travel'),
              onPressed: () {
                if (!form.currentState!.validate()) return;
                final active = mode != 'none',
                    known = mode != 'none' && cost.text.trim().isNotEmpty;
                Navigator.pop(
                  context,
                  TripActivity.fromFields(widget.to.id, {
                    ...widget.to.fields(),
                    'travelMode': mode,
                    'travelFromId': active ? widget.from.id : '',
                    'travelSignature': active
                        ? segmentSignature(widget.from, widget.to)
                        : '',
                    'travelCostKnown': known,
                    'travelCostSatang': known ? parseMoney(cost.text)! : 0,
                  }),
                );
              },
              child: const Text('บันทึกการเดินทาง'),
            ),
          ],
        ),
      ),
    ),
  );
}
