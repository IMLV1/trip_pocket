import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../activities/domain/trip_activity.dart';
import '../../core/validation.dart';
import 'curated_places.dart';

class RecommendationsSheet extends StatefulWidget {
  final TripActivity? anchor;
  final int remaining;
  const RecommendationsSheet({super.key, this.anchor, required this.remaining});
  @override
  State<RecommendationsSheet> createState() => _RecommendationsSheetState();
}

class _RecommendationsSheetState extends State<RecommendationsSheet> {
  String category = 'all', query = '';
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * .85 -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(220.0, MediaQuery.sizeOf(context).height * .85),
        child: Column(
          children: [
            ListTile(
              title: const Text('ค้นหา / แนะนำ • เชียงใหม่'),
              trailing: IconButton(
                tooltip: 'ปิดคำแนะนำ',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                key: const Key('place-search'),
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  labelText: 'ค้นหาชื่อสถานที่',
                  hintText: 'ค้นจากชุดเชียงใหม่ในแอป',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in {
                    'all': 'ทั้งหมด',
                    ...activityCategories,
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: category == entry.key,
                        onSelected: (_) => setState(() => category = entry.key),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${widget.remaining < 0 ? 'เกินงบ' : 'เหลือจากราคาที่ทราบ'} ${money(widget.remaining.abs())} บาท\nยังไม่ทราบราคาสถานที่แนะนำ จึงยืนยันว่าอยู่ในงบไม่ได้ • ไม่แก้แผนอัตโนมัติ',
                    ),
                  ),
                  if (suggestPlaces(
                    category: category,
                    anchor: widget.anchor,
                    query: query,
                  ).isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'ไม่พบในชุดข้อมูลเชียงใหม่ ลองคำอื่นหรือเลือกหมุดเอง',
                      ),
                    ),
                  for (final s in suggestPlaces(
                    category: category,
                    query: query,
                    anchor: widget.anchor,
                  ))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              s.place.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(s.reason),
                            const Text(
                              'ยังไม่ทราบราคา/เวลาเปิดปิด • พิกัดโดยประมาณ ต้องตรวจและยืนยันหมุด',
                            ),
                            Text(
                              'ประเทศไทย • ${s.place.province} • ตรวจชื่อ/หมวดจากแหล่งข้อมูล ${s.place.checkedAt}',
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  if (!await launchUrl(
                                    Uri.parse(s.place.source),
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                    throw StateError('เปิดไม่ได้');
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'เปิดแหล่งข้อมูลไม่ได้ ลองใหม่ภายหลัง',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                'แหล่งข้อมูล: ${Uri.parse(s.place.source).host}',
                              ),
                            ),
                            OutlinedButton(
                              key: ValueKey('recommend-${s.place.id}'),
                              onPressed: () => Navigator.pop(context, s.place),
                              child: const Text(
                                'เลือกและตรวจรายละเอียดก่อนเพิ่ม',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
