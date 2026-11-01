// Packing checklist UI.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
import '../../core/widgets.dart';
import 'packing_repository.dart';

/// Checklist card for one trip.
class PackingChecklist extends ConsumerStatefulWidget {
  final TripKey tripKey;
  const PackingChecklist({super.key, required this.tripKey});
  @override
  ConsumerState<PackingChecklist> createState() => _PackingChecklistState();
}

class _PackingChecklistState extends ConsumerState<PackingChecklist> {
  final text = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  /// Saves the full list and reloads. Set [clear] to empty the input.
  Future<void> save(List<PackingItem> items, {bool clear = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref
          .read(packingRepositoryProvider)
          .save(widget.tripKey.uid, widget.tripKey.tripId, items);
      if (mounted) {
        ref.invalidate(packingProvider(widget.tripKey));
        if (clear) text.clear();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เช็กลิสต์ก่อนออกเดินทาง',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('บันทึกเฉพาะเครื่องนี้ ใช้ได้แม้ออฟไลน์'),
          AsyncContent(
            value: ref.watch(packingProvider(widget.tripKey)),
            retry: () => ref.invalidate(packingProvider(widget.tripKey)),
            data: (items) => Column(
              children: [
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: items.isEmpty
                      ? 0
                      : items.where((e) => e.checked).length / items.length,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text(
                  'เตรียมแล้ว ${items.where((e) => e.checked).length} / ${items.length} รายการ',
                ),
                const SizedBox(height: 8),
                for (final item in items)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.text),
                    value: item.checked,
                    onChanged: busy
                        ? null
                        : (v) => save(
                            items
                                .map((e) => e.id == item.id ? e.toggle() : e)
                                .toList(),
                          ),
                    secondary: IconButton(
                      tooltip: 'ลบ ${item.text}',
                      onPressed: busy
                          ? null
                          : () => save(
                              items.where((e) => e.id != item.id).toList(),
                            ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('packing-text'),
                        controller: text,
                        enabled: !busy,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'ของที่ต้องเตรียม',
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('packing-add'),
                      tooltip: 'เพิ่มของ',
                      onPressed: busy
                          ? null
                          : () {
                              if (text.text.trim().isEmpty) return;
                              save([
                                ...items,
                                PackingItem(
                                  const Uuid().v4(),
                                  text.text.trim(),
                                  false,
                                ),
                              ], clear: true);
                            },
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
