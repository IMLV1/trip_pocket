import '../../places/day_plan.dart';
import '../../places/curated_places.dart';
import '../../places/recommendations_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets.dart';
import '../../../core/validation.dart';
import '../../activities/domain/trip_activity.dart';
import '../../packing/packing_checklist.dart';
import '../../sharing/share_plan_sheet.dart';
import '../../sharing/trip_share_formatter.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String uid, tripId;
  const TripDetailScreen({super.key, required this.uid, required this.tripId});
  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  bool busy = false;
  String? day;
  TripKey get tripKey => (uid: widget.uid, tripId: widget.tripId);
  Future<void> deleteActivity(TripActivity a) async {
    if (busy || !await confirmDelete(context, 'ลบ ${a.title}?')) return;
    setState(() => busy = true);
    try {
      await ref
          .read(travelRepositoryProvider)
          .deleteActivity(widget.uid, widget.tripId, a.id);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('แผนเที่ยว')),
    body: AsyncContent(
      value: ref.watch(tripProvider(tripKey)),
      retry: () => ref.invalidate(tripProvider(tripKey)),
      data: (snapshot) {
        final t = snapshot.value;
        if (t == null) {
          return Center(
            child: TextButton(
              onPressed: () => context.go('/trips'),
              child: const Text('ไม่พบทริป • กลับรายการ'),
            ),
          );
        }
        if (t.status != 'active') {
          return Center(
            child: TextButton(
              onPressed: () => context.go('/trips'),
              child: const Text('ทริปกำลังลบ • กลับรายการเพื่อลองต่อ'),
            ),
          );
        }
        final selected =
            day != null &&
                day!.compareTo(t.startDate) >= 0 &&
                day!.compareTo(t.endDate) <= 0
            ? day!
            : t.startDate;
        return PageBody(
          children: [
            Text(t.title, style: Theme.of(context).textTheme.headlineMedium),
            Text('${t.destination}\n${t.startDate} ถึง ${t.endDate}'),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.push('/trips/${t.id}/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('แก้ไขทริป'),
                ),
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!await confirmDelete(
                            context,
                            'ลบทริปและทุกกิจกรรม?',
                          )) {
                            return;
                          }
                          setState(() => busy = true);
                          try {
                            await ref
                                .read(travelRepositoryProvider)
                                .deleteTrip(widget.uid, t.id);
                            if (context.mounted) context.go('/trips');
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('ลบทริป'),
                ),
              ],
            ),
            AsyncContent(
              value: ref.watch(activitiesProvider(tripKey)),
              retry: () => ref.invalidate(activitiesProvider(tripKey)),
              data: (s) {
                final budget = planBudget(s.value);
                final total = budget.total, remaining = t.budgetSatang - total;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (s.cached || snapshot.cached)
                      const Text('ข้อมูลที่โหลดไว้ล่าสุด'),
                    if (s.pending || snapshot.pending)
                      const Text('กำลังรอยืนยันการบันทึกจากเซิร์ฟเวอร์'),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('งบทริป ${money(t.budgetSatang)} บาท'),
                            Text('วางแผนแล้ว ${money(total)} บาท'),
                            Text(
                              'กิจกรรม ${money(budget.activities)} • เดินทาง ${money(budget.transport)} บาท',
                            ),
                            if (budget.unknown > 0)
                              Text(
                                'ยังไม่รวมราคา ${budget.unknown} รายการ/ช่วงเดินทาง • ยอดคงเหลือคำนวณเฉพาะที่ทราบ',
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '${remaining < 0 ? 'เกินงบ' : 'คงเหลือ'} ${money(remaining.abs())} บาท',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: remaining < 0
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy || s.pending || snapshot.pending
                          ? null
                          : () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.sizeOf(context).height * .85,
                              ),
                              builder: (c) => SharePlanSheet(
                                text: formatTripShare(t, s.value),
                                cached: s.cached || snapshot.cached,
                              ),
                            ),
                      icon: const Icon(Icons.share),
                      label: const Text('แชร์แผนเที่ยว'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'แผนรายวัน',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/trips/${t.id}/activities/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('เพิ่มกิจกรรม'),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(selected),
                          firstDate: DateTime.parse(t.startDate),
                          lastDate: DateTime.parse(t.endDate),
                        );
                        if (d != null && mounted) {
                          setState(() => day = dateKey(d));
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(selected),
                    ),
                    if (s.value.where((a) => a.date == selected).isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'วันนี้ยังไม่มีกิจกรรม',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    OutlinedButton.icon(
                      key: const Key('recommend-places'),
                      icon: const Icon(Icons.explore),
                      label: const Text('แนะนำสถานที่ • เชียงใหม่'),
                      onPressed: busy || s.pending
                          ? null
                          : () async {
                              final daily = sortedActivities(
                                s.value.where((a) => a.date == selected),
                              );
                              final place =
                                  await showModalBottomSheet<CuratedPlace>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (c) => RecommendationsSheet(
                                      anchor: daily.isEmpty ? null : daily.last,
                                      remaining: remaining,
                                    ),
                                  );
                              if (place != null && context.mounted) {
                                context.push(
                                  '/trips/${t.id}/activities/new',
                                  extra: ActivitySeed(place, selected),
                                );
                              }
                            },
                    ),
                    OutlinedButton.icon(
                      key: const Key('add-stop'),
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('เพิ่มจุดหมาย'),
                      onPressed: busy || s.pending
                          ? null
                          : () => context.push(
                              '/trips/${t.id}/activities/new',
                              extra: ActivitySeed.pin(null, selected),
                            ),
                    ),
                    DayPlan(
                      date: selected,
                      uid: widget.uid,
                      trip: t,
                      activities: s.value
                          .where((a) => a.date == selected)
                          .toList(),
                      disabled: busy || s.pending || snapshot.pending,
                      onDelete: deleteActivity,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            PackingChecklist(
              key: ValueKey('${widget.uid}/${t.id}'),
              tripKey: tripKey,
            ),
          ],
        );
      },
    ),
  );
}
