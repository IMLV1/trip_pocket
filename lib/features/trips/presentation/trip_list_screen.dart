// Trip list screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets.dart';
import '../../../core/design_system.dart';

/// Upcoming and completed trips, with search.
class TripListScreen extends ConsumerStatefulWidget {
  final String uid;
  const TripListScreen({super.key, required this.uid});
  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  bool resuming = false, loggingOut = false;
  String? cleanupError;
  final searchText = TextEditingController();
  bool searching = false, showCompleted = false;
  String query = '';
  @override
  void dispose() {
    searchText.dispose();
    super.dispose();
  }

  /// Toggles the search field, clearing the query on close.
  void toggleSearch() => setState(() {
    searching = !searching;
    if (!searching) {
      query = '';
      searchText.clear();
    }
  });
  @override
  void initState() {
    super.initState();
    Future.microtask(resume);
  }

  /// Continues unfinished deletes and offers a retry on failure.
  Future<void> resume() async {
    if (resuming) return;
    setState(() {
      resuming = true;
      cleanupError = null;
    });
    try {
      await ref.read(travelRepositoryProvider).resumePendingDeletes(widget.uid);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              cleanupError = 'การลบค้างยังไม่เสร็จ ตรวจอินเทอร์เน็ตแล้วลองใหม่',
        );
      }
    } finally {
      if (mounted) setState(() => resuming = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('ทริปของฉัน'),
      actions: [
        IconButton(
          key: const Key('search-trips'),
          tooltip: searching ? 'ปิดการค้นหาทริป' : 'ค้นหาทริป',
          onPressed: toggleSearch,
          icon: Icon(searching ? Icons.search_off : Icons.search),
        ),
        IconButton(
          key: const Key('open-profile'),
          tooltip: 'โปรไฟล์ของฉัน',
          onPressed: loggingOut ? null : () => context.push('/profile'),
          icon: const Icon(Icons.account_circle_outlined),
        ),
        IconButton(
          tooltip: 'ออกจากระบบ',
          onPressed: loggingOut
              ? null
              : () async {
                  setState(() => loggingOut = true);
                  try {
                    await ref.read(authRepositoryProvider).signOut();
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  } finally {
                    if (mounted) setState(() => loggingOut = false);
                  }
                },
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        setState(() => showCompleted = false);
        context.push('/trips/new');
      },
      icon: const Icon(Icons.add),
      label: const Text('สร้างทริป'),
    ),
    body: PageBody(
      children: [
        if (searching)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              key: const Key('trip-search'),
              controller: searchText,
              autofocus: true,
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: 'ค้นหาชื่อทริป',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'ล้างคำค้นทริป',
                  onPressed: () => setState(() {
                    searchText.clear();
                    query = '';
                  }),
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
          ),
        if (!searching)
          Container(
            decoration: BoxDecoration(
              color: TripColors.ink,
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: const RouteMotif(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SoftBadge(
                      'YOUR NEXT JOURNEY',
                      icon: Icons.explore_outlined,
                      color: TripColors.accent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ออกไปเก็บ\nความทรงจำ',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'แผนเที่ยว งบ และของที่ต้องเตรียม\nพร้อมสำหรับการเดินทางครั้งใหม่',
                      style: TextStyle(color: Color(0xffcedfd6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SectionTitle(
          'การเดินทางของคุณ',
          subtitle: 'เลือกทริปเพื่อจัดแผนรายวัน',
        ),
        if (cleanupError != null)
          Card(
            child: ListTile(
              title: Text(cleanupError!),
              trailing: TextButton(
                onPressed: resuming ? null : resume,
                child: const Text('ลองต่อ'),
              ),
            ),
          ),
        ref
            .watch(deletingTripsProvider(widget.uid))
            .when(
              data: (s) => s.value.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      child: ListTile(
                        title: Text('กำลังลบ / ลบค้าง ${s.value.length} ทริป'),
                        trailing: TextButton(
                          onPressed: resuming ? null : resume,
                          child: Text(resuming ? 'กำลังลบ…' : 'ลองต่อ'),
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
        AsyncContent(
          value: ref.watch(tripsProvider(widget.uid)),
          retry: () => ref.invalidate(tripsProvider(widget.uid)),
          data: (s) => Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('trips-upcoming'),
                    label: Text(
                      'กำลังจะไป (${s.value.where((t) => !t.completed).length})',
                    ),
                    selected: !showCompleted,
                    onSelected: (_) => setState(() => showCompleted = false),
                  ),
                  ChoiceChip(
                    key: const Key('trips-completed'),
                    label: Text(
                      'จบทริปแล้ว (${s.value.where((t) => t.completed).length})',
                    ),
                    selected: showCompleted,
                    onSelected: (_) => setState(() => showCompleted = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (s.cached)
                const Text('ข้อมูลที่โหลดไว้ล่าสุด • อาจยังไม่เป็นปัจจุบัน'),
              if (s.value.isEmpty)
                const EmptyPanel(
                  icon: Icons.luggage_outlined,
                  title: 'ยังไม่มีทริป',
                  message: 'กด “สร้างทริป” เพื่อเริ่มการเดินทาง',
                ),
              if (s.value.isNotEmpty &&
                  !s.value.any((t) => t.completed == showCompleted))
                EmptyPanel(
                  icon: Icons.luggage_outlined,
                  title: showCompleted
                      ? 'ยังไม่มีทริปที่จบแล้ว'
                      : 'ยังไม่มีทริปที่กำลังจะไป',
                  message: showCompleted
                      ? 'กดยืนยันจบทริปจากหน้ารายละเอียดทริป'
                      : 'กดสร้างทริปเพื่อวางแผนครั้งใหม่',
                ),
              if (s.value.any((t) => t.completed == showCompleted) &&
                  s.value
                      .where(
                        (t) =>
                            t.completed == showCompleted &&
                            t.title.toLowerCase().contains(query),
                      )
                      .isEmpty)
                const EmptyPanel(
                  icon: Icons.search_off,
                  title: 'ไม่พบชื่อทริปที่ค้นหา',
                  message: 'ลองเปลี่ยนคำค้น หรือล้างคำค้นเพื่อดูทริปทั้งหมด',
                ),
              for (final t in s.value.where(
                (t) =>
                    t.completed == showCompleted &&
                    t.title.toLowerCase().contains(query),
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: TripColors.mint,
                        child: Icon(
                          Icons.luggage_outlined,
                          color: TripColors.primary,
                        ),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        '${t.destination == t.title ? 'จุดหมายในทริป' : t.destination}\n${prettyDate(t.startDate)} – ${prettyDate(t.endDate, year: true)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/trips/${t.id}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
