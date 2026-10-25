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
      end = widget.initial?.endDate ?? start;
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    destination.dispose();
    budget.dispose();
    super.dispose();
  }

  Future<void> pick(bool first) async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(first ? start : end),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (value != null && mounted) {
      setState(() {
        if (first) {
          start = dateKey(value);
        } else {
          end = dateKey(value);
        }
      });
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (end.compareTo(start) < 0) {
      showError(context, StateError('วันสิ้นสุดต้องไม่ก่อนวันเริ่ม'));
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
              title: title.text,
              destination: destination.text,
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
                  decoration: const InputDecoration(labelText: 'จุดหมาย'),
                  validator: textError,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('วันเริ่ม'),
                  subtitle: Text(start),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: busy ? null : () => pick(true),
                ),
                ListTile(
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
                  onPressed: busy ? null : save,
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
