import 'package:latlong2/latlong.dart';
import '../../places/destination_preview.dart';
import '../../places/day_plan.dart';
import '../../places/curated_places.dart';
import '../../places/recommendations_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets.dart';
import '../../../core/design_system.dart';
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
  int section = 0;
  final visited = <int>{0};
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

  Future<void> finishTrip() async {
    if (busy) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ยืนยันจบทริป?'),
        content: const Text(
          'ทริปจะย้ายไปหมวดจบทริปแล้ว คุณยังเปิดดูและแก้รายละเอียดได้ ข้อมูลจะไม่ถูกลบ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            key: const Key('confirm-complete-trip'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('ยืนยันจบทริป'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(travelRepositoryProvider)
          .completeTrip(widget.uid, widget.tripId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('จบทริปแล้ว ดูได้ในหมวดจบทริปแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('แผนเที่ยว'),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'จัดการทริป',
          enabled: !busy,
          onSelected: (action) async {
            final t = ref.read(tripProvider(tripKey)).value?.value;
            if (t == null || t.status != 'active') return;
            if (action == 'edit') {
              context.push('/trips/${t.id}/edit');
              return;
            }
            if (!await confirmDelete(context, 'ลบทริปและทุกกิจกรรม?') ||
                !mounted) {
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
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('แก้ไขทริป')),
            PopupMenuItem(value: 'delete', child: Text('ลบทริป')),
          ],
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: section,
      onDestinationSelected: (i) => setState(() {
        section = i;
        visited.add(i);
      }),
      destinations: const [
        NavigationDestination(
          key: Key('tab-plan'),
          icon: Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route),
          label: 'แผนเที่ยว',
        ),
        NavigationDestination(
          key: Key('tab-map'),
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'แผนที่',
        ),
        NavigationDestination(
          key: Key('tab-packing'),
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: 'เตรียมของ',
        ),
      ],
    ),
    body: AsyncContent(
      value: ref.watch(tripProvider(tripKey)),
      retry: () => ref.invalidate(tripProvider(tripKey)),
      data: (snapshot) {
        final t = snapshot.value;
        if (t == null || t.status != 'active') {
          return Center(
            child: TextButton(
              onPressed: () => context.go('/trips'),
              child: Text(
                t == null
                    ? 'ไม่พบทริป • กลับรายการ'
                    : 'ทริปกำลังลบ • กลับรายการเพื่อลองต่อ',
              ),
            ),
          );
        }
        final selected =
            day != null &&
                day!.compareTo(t.startDate) >= 0 &&
                day!.compareTo(t.endDate) <= 0
            ? day!
            : t.startDate;
        return IndexedStack(
          index: section,
          children: [
            for (var page = 0; page < 3; page++)
              !visited.contains(page)
                  ? const SizedBox.shrink()
                  : page == 2
                  ? PageBody(
                      children: [
                        const FormIntro(
                          'พร้อมออกเดินทาง',
                          'เช็กของให้ครบก่อนเริ่มทริป',
                          icon: Icons.backpack_outlined,
                        ),
                        PackingChecklist(
                          key: ValueKey('${widget.uid}/${t.id}'),
                          tripKey: tripKey,
                        ),
                      ],
                    )
                  : PageBody(
                      key: PageStorageKey('trip-page-$page'),
                      children: [
                        Text(
                          t.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${t.destination} • ${prettyDate(t.startDate)} – ${prettyDate(t.endDate, year: true)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (t.completed)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: SoftBadge(
                              'จบทริปแล้ว',
                              icon: Icons.task_alt,
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (page == 0 && t.hasDestinationPin) ...[
                          const SectionTitle(
                            'พื้นที่หลักของทริป',
                            subtitle: 'หมุดพื้นที่หลักแยกจากจุดแวะรายวัน',
                          ),
                          DestinationPreview(
                            point: LatLng(
                              t.destinationLatitude!,
                              t.destinationLongitude!,
                            ),
                            label: t.destination,
                          ),
                          const SizedBox(height: 16),
                        ],
                        AsyncContent(
                          value: ref.watch(activitiesProvider(tripKey)),
                          retry: () =>
                              ref.invalidate(activitiesProvider(tripKey)),
                          data: (s) {
                            final budget = planBudget(s.value);
                            final total = budget.total,
                                remaining = t.budgetSatang - total;
                            final disabled =
                                busy || s.pending || snapshot.pending;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (s.cached || snapshot.cached)
                                  const SoftBadge(
                                    'ข้อมูลที่โหลดไว้ล่าสุด',
                                    icon: Icons.cloud_off_outlined,
                                  ),
                                if (s.pending || snapshot.pending)
                                  const Text(
                                    'กำลังรอยืนยันการบันทึกจากเซิร์ฟเวอร์',
                                  ),
                                if (page == 0) ...[
                                  if (!t.completed)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: OutlinedButton.icon(
                                        key: const Key('complete-trip'),
                                        onPressed: disabled ? null : finishTrip,
                                        icon: const Icon(Icons.flag_outlined),
                                        label: const Text('จบทริป'),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: TripColors.ink,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          remaining < 0
                                              ? 'เกินงบที่ตั้งไว้'
                                              : 'งบคงเหลือจากราคาที่ทราบ',
                                          style: const TextStyle(
                                            color: Color(0xffcedfd6),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${money(remaining.abs())} ฿',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge
                                              ?.copyWith(
                                                color: remaining < 0
                                                    ? const Color(0xffffc8c8)
                                                    : Colors.white,
                                              ),
                                        ),
                                        const SizedBox(height: 18),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: t.budgetSatang > 0
                                                ? (total / t.budgetSatang)
                                                      .clamp(0.0, 1.0)
                                                : 0,
                                            minHeight: 6,
                                            color: TripColors.accent,
                                            backgroundColor: Colors.white24,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'งบทริป ${money(t.budgetSatang)} บาท',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'วางแผนแล้ว ${money(total)} บาท',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'กิจกรรม ${money(budget.activities)} • เดินทาง ${money(budget.transport)} บาท',
                                          style: const TextStyle(
                                            color: Color(0xffcedfd6),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (budget.unknown > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: Text(
                                              'ยังไม่รวม ${budget.unknown} รายการ/ช่วงที่ไม่ทราบราคา',
                                              style: const TextStyle(
                                                color: TripColors.accent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: disabled
                                        ? null
                                        : () => showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            constraints: BoxConstraints(
                                              maxHeight:
                                                  MediaQuery.sizeOf(
                                                    context,
                                                  ).height *
                                                  .85,
                                            ),
                                            builder: (_) => SharePlanSheet(
                                              text: formatTripShare(t, s.value),
                                              cached:
                                                  s.cached || snapshot.cached,
                                            ),
                                          ),
                                    icon: const Icon(Icons.ios_share_outlined),
                                    label: const Text('แชร์แผนเที่ยว'),
                                  ),
                                ],
                                SectionTitle(
                                  page == 0
                                      ? 'จุดหมายประจำวัน'
                                      : 'สำรวจเส้นทางของคุณ',
                                  subtitle: page == 0
                                      ? 'เรียงจุดหมายตามลำดับที่อยากไป'
                                      : 'แตะหมุดเพื่อดูหรือแก้ไขสถานที่',
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
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  label: Text(prettyDate(selected, year: true)),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  key: const Key('add-stop'),
                                  icon: const Icon(
                                    Icons.add_location_alt_outlined,
                                  ),
                                  label: const Text('เพิ่มจุดหมาย'),
                                  onPressed: disabled
                                      ? null
                                      : () => context.push(
                                          '/trips/${t.id}/activities/new',
                                          extra: ActivitySeed.pin(
                                            null,
                                            selected,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  key: const Key('recommend-places'),
                                  icon: const Icon(Icons.search),
                                  label: const Text('ค้นหา / แนะนำทั่วไทย'),
                                  onPressed: disabled
                                      ? null
                                      : () async {
                                          final daily = sortedActivities(
                                            s.value.where(
                                              (a) => a.date == selected,
                                            ),
                                          );
                                          final place =
                                              await showModalBottomSheet<
                                                CuratedPlace
                                              >(
                                                context: context,
                                                isScrollControlled: true,
                                                useSafeArea: true,
                                                builder: (_) =>
                                                    RecommendationsSheet(
                                                      anchor: daily.isEmpty
                                                          ? null
                                                          : daily.last,
                                                      remaining: remaining,
                                                    ),
                                              );
                                          if (place != null &&
                                              context.mounted) {
                                            context.push(
                                              '/trips/${t.id}/activities/new',
                                              extra: ActivitySeed(
                                                place,
                                                selected,
                                              ),
                                            );
                                          }
                                        },
                                ),
                                const SizedBox(height: 12),
                                if (page == 0 &&
                                    s.value
                                        .where((a) => a.date == selected)
                                        .isEmpty)
                                  const EmptyPanel(
                                    icon: Icons.add_location_alt_outlined,
                                    title: 'วันนี้ยังไม่มีจุดหมาย',
                                    message:
                                        'ค้นหาสถานที่ที่อยากไป หรือเลือกหมุดบนแผนที่',
                                  ),
                                DayPlan(
                                  date: selected,
                                  uid: widget.uid,
                                  trip: t,
                                  activities: s.value
                                      .where((a) => a.date == selected)
                                      .toList(),
                                  disabled: disabled,
                                  onDelete: deleteActivity,
                                  showMap: page == 1,
                                  showStops: page == 0,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
          ],
        );
      },
    ),
  );
}
