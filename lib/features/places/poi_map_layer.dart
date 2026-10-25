import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'curated_places.dart';
import 'place_catalog.dart';
import '../activities/domain/trip_activity.dart';

IconData placeIcon(String category) => switch (category) {
  'food' => Icons.restaurant,
  'lodging' => Icons.hotel,
  'attraction' => Icons.attractions,
  _ => Icons.park,
};

Future<CuratedPlace?> chooseSuggestedPlace(
  BuildContext context,
  CuratedPlace place,
) => showModalBottomSheet<CuratedPlace>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (c) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(place.name, style: Theme.of(c).textTheme.titleLarge),
          Text('${activityCategories[place.category]} • ${place.province}'),
          Text(
            place.community
                ? 'ข้อมูลชุมชน OpenStreetMap ณ ${place.checkedAt} ไม่ได้ยืนยันว่าร้านยังเปิดอยู่'
                : 'ชุดข้อมูลคัดเอง ณ ${place.checkedAt}',
          ),
          const Text(
            'ยังไม่ทราบราคา/เวลาเปิดปิด • หมุดอาจไม่ใช่ทางเข้า ตรวจและยืนยันในฟอร์มก่อนบันทึก',
          ),
          TextButton(
            onPressed: () async {
              try {
                await launchUrl(
                  Uri.parse(place.source),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {
                if (c.mounted) {
                  ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(content: Text('เปิดแหล่งข้อมูลไม่ได้')),
                  );
                }
              }
            },
            child: const Text('ดูแหล่งข้อมูลสถานที่'),
          ),
          FilledButton(
            key: const Key('choose-poi'),
            onPressed: () => Navigator.pop(c, place),
            child: const Text('เพิ่มจุดหมายนี้'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    ),
  ),
);

class PoiMapLayer extends ConsumerStatefulWidget {
  final void Function(CuratedPlace)? onSelected;
  final String category, province, query;
  const PoiMapLayer({
    super.key,
    this.onSelected,
    this.category = 'all',
    this.province = '',
    this.query = '',
  });
  @override
  ConsumerState<PoiMapLayer> createState() => _PoiMapLayerState();
}

class _PoiMapLayerState extends ConsumerState<PoiMapLayer> {
  Timer? timer;
  String? lastKey;
  PoiWindow window = const PoiWindow([], 0);
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(placeCatalogProvider);
    final camera = MapCamera.of(context);
    return async.when(
      loading: () => const Align(
        alignment: Alignment.topLeft,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Text('กำลังโหลดสถานที่ทั่วไทย…'),
          ),
        ),
      ),
      error: (e, s) => Align(
        alignment: Alignment.topLeft,
        child: TextButton(
          onPressed: () => ref.invalidate(placeCatalogProvider),
          child: const Text('โหลดสถานที่ไม่ได้ • ลองใหม่'),
        ),
      ),
      data: (catalog) {
        final bounds = camera.visibleBounds;
        final key =
            '${identityHashCode(catalog)}/${bounds.south}/${bounds.north}/${bounds.west}/${bounds.east}/${camera.zoom}/${widget.category}/${widget.province}/${widget.query}';
        if (key != lastKey) {
          lastKey = key;
          timer?.cancel();
          timer = Timer(const Duration(milliseconds: 140), () {
            if (mounted) {
              setState(
                () => window = catalog.window(
                  south: bounds.south,
                  north: bounds.north,
                  west: bounds.west,
                  east: bounds.east,
                  zoom: camera.zoom,
                  category: widget.category,
                  province: widget.province,
                  query: widget.query,
                ),
              );
            }
          });
        }
        return Stack(
          children: [
            MarkerLayer(
              markers: [
                for (final group in window.groups)
                  Marker(
                    point: group.point,
                    width: group.place == null ? 48 : 36,
                    height: group.place == null ? 48 : 36,
                    child: Semantics(
                      label: group.place == null
                          ? '${group.count} สถานที่แนะนำ ซูมดู'
                          : 'แนะนำ ${group.place!.name}',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          if (group.place == null) {
                            MapController.of(context).move(
                              group.point,
                              (camera.zoom + 2).clamp(3, 18).toDouble(),
                            );
                          } else {
                            widget.onSelected?.call(group.place!);
                          }
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: group.place == null
                                ? Colors.blue.shade700
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 3),
                            ],
                          ),
                          child: Center(
                            child: group.place == null
                                ? Text(
                                    '${group.count}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Icon(
                                    placeIcon(group.place!.category),
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.topRight,
              child: IgnorePointer(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      window.total == 0
                          ? 'พื้นที่นี้ยังไม่มีผลแนะนำ'
                          : 'แนะนำ ${window.total} แห่ง • ${camera.zoom >= 12 && window.total > 100 ? 'แสดง 100 ไอคอน ซูมดูเพิ่ม' : 'แตะไอคอน/กลุ่ม'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
