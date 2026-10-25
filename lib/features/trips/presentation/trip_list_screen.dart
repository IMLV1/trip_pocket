import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets.dart';

class TripListScreen extends ConsumerStatefulWidget {
  final String uid;
  const TripListScreen({super.key, required this.uid});
  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  bool resuming = false, loggingOut = false;
  String? cleanupError;
  @override
  void initState() {
    super.initState();
    Future.microtask(resume);
  }

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
      onPressed: () => context.push('/trips/new'),
      icon: const Icon(Icons.add),
      label: const Text('สร้างทริป'),
    ),
    body: PageBody(
      children: [
        Text(
          'ออกไปเก็บความทรงจำ',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text('จัดแผนรายวัน งบ และของที่ต้องเตรียมในที่เดียว'),
        const SizedBox(height: 20),
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
              if (s.cached)
                const Text('ข้อมูลที่โหลดไว้ล่าสุด • อาจยังไม่เป็นปัจจุบัน'),
              if (s.value.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'ยังไม่มีทริป\nกด “สร้างทริป” เพื่อเริ่มต้น',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final t in s.value)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(child: Icon(Icons.luggage)),
                    title: Text(t.title),
                    subtitle: Text(
                      '${t.destination}\n${t.startDate} ถึง ${t.endDate}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/trips/${t.id}'),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
