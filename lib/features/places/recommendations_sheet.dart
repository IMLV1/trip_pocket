import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../activities/domain/trip_activity.dart';
import '../../core/validation.dart';
import 'curated_places.dart';
import 'place_catalog.dart';
import 'poi_map_layer.dart';

class RecommendationsSheet extends ConsumerStatefulWidget {
  final TripActivity? anchor;
  final int remaining;
  const RecommendationsSheet({super.key, this.anchor, required this.remaining});
  @override
  ConsumerState<RecommendationsSheet> createState() =>
      _RecommendationsSheetState();
}

class _RecommendationsSheetState extends ConsumerState<RecommendationsSheet> {
  String category = 'all', query = '', province = '';
  bool showMap = true;
  String? resultKey;
  PlaceResults? result;
  Future<void> select(CuratedPlace place) async {
    final confirmed = await chooseSuggestedPlace(context, place);
    if (confirmed != null && mounted) Navigator.pop(context, confirmed);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * .9 -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(170.0, MediaQuery.sizeOf(context).height * .9),
        child: Column(
          children: [
            ListTile(
              title: const Text('ค้นหา / แนะนำทั่วไทย'),
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
                  labelText: 'ค้นหาชื่อสถานที่หรือจังหวัด',
                  hintText: 'เช่น วัดอรุณ • ภูเก็ต • คาเฟ่',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ref
                  .watch(placeCatalogProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(
                      child: TextButton(
                        onPressed: () => ref.invalidate(placeCatalogProvider),
                        child: const Text('โหลดฐานสถานที่ไม่ได้ • ลองใหม่'),
                      ),
                    ),
                    data: (catalog) {
                      final key =
                          '${identityHashCode(catalog)}/$query/$category/$province';
                      if (resultKey != key) {
                        resultKey = key;
                        result = catalog.search(
                          query: query,
                          category: category,
                          province: province,
                          near: query.trim().isEmpty && widget.anchor != null
                              ? LatLng(
                                  widget.anchor!.latitude,
                                  widget.anchor!.longitude,
                                )
                              : null,
                        );
                      }
                      final matches = result!;
                      return ListView.builder(
                        key: const Key('place-results'),
                        itemCount: matches.places.length + 1,
                        itemBuilder: (c, i) {
                          if (i == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: DropdownButtonFormField<String>(
                                    key: const Key('poi-province'),
                                    initialValue: province,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('ทุกจังหวัด'),
                                      ),
                                      for (final p in catalog.provinces)
                                        DropdownMenuItem(
                                          value: p,
                                          child: Text(p),
                                        ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => province = v!),
                                    decoration: const InputDecoration(
                                      labelText: 'จังหวัด',
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (final e in {
                                        'all': 'ทั้งหมด',
                                        ...activityCategories,
                                      }.entries)
                                        Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: ChoiceChip(
                                            label: Text(e.value),
                                            selected: category == e.key,
                                            onSelected: (_) => setState(
                                              () => category = e.key,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'พบ ${matches.total} แห่ง • แสดงรายการ ${matches.places.length} แห่งแรก\nฐานข้อมูล ${catalog.places.length} แห่งทั่วไทย • ข้อมูล ณ ${catalog.dataTimestamp}',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => showMap = !showMap),
                                  icon: const Icon(Icons.map),
                                  label: Text(
                                    showMap
                                        ? 'ซ่อนแผนที่แนะนำ'
                                        : 'แสดงแผนที่แนะนำ',
                                  ),
                                ),
                                if (showMap &&
                                    MediaQuery.viewInsetsOf(context).bottom ==
                                        0)
                                  SizedBox(
                                    height: 250,
                                    child: DiscoveryMap(
                                      key: ValueKey(
                                        '$query/$province/$category',
                                      ),
                                      results: matches.places,
                                      category: category,
                                      province: province,
                                      query: query,
                                      anchor: widget.anchor,
                                      onSelected: select,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '${widget.remaining < 0 ? 'เกินงบ' : 'เหลือจากราคาที่ทราบ'} ${money(widget.remaining.abs())} บาท\nยังไม่ทราบราคาสถานที่แนะนำ จึงยืนยันว่าอยู่ในงบไม่ได้ • ไอคอนแนะนำยังไม่ใช่จุดในทริป',
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'ค้นหาในข้อมูลชุมชนที่มากับแอป อาจไม่มีบางร้านหรือข้อมูลเปลี่ยนแล้ว • ซูม/แตะกลุ่มบนแผนที่เพื่อเลือกสถานที่',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => launchUrl(
                                    Uri.parse(
                                      'https://www.openstreetmap.org/copyright',
                                    ),
                                  ),
                                  child: const Text(
                                    '© OpenStreetMap contributors • ODbL',
                                  ),
                                ),
                                if (matches.total == 0)
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'ไม่พบในข้อมูล ลองคำสั้นลง เปลี่ยนจังหวัด/หมวด หรือเลือกหมุดเอง',
                                    ),
                                  ),
                              ],
                            );
                          }
                          final p = matches.places[i - 1];
                          return Card(
                            child: ListTile(
                              leading: Icon(placeIcon(p.category)),
                              title: Text(p.name),
                              subtitle: Text(
                                '${activityCategories[p.category]} • ${p.province}\nยังไม่ทราบราคา • ${widget.anchor == null ? 'ตรงคำค้น/หมวดที่เลือก' : 'เรียงความใกล้เมื่อไม่ใส่คำค้น • ระยะทางตรง'}',
                              ),
                              trailing: IconButton(
                                key: ValueKey('recommend-${p.id}'),
                                tooltip: 'เลือกสถานที่นี้',
                                onPressed: () => select(p),
                                icon: const Icon(Icons.add_location_alt),
                              ),
                              onTap: () => select(p),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DiscoveryMap extends StatelessWidget {
  final List<CuratedPlace> results;
  final String category, province, query;
  final TripActivity? anchor;
  final void Function(CuratedPlace) onSelected;
  const DiscoveryMap({
    super.key,
    required this.results,
    required this.category,
    required this.province,
    required this.query,
    this.anchor,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    final fit =
        results.isNotEmpty && (query.trim().isNotEmpty || province.isNotEmpty);
    return FlutterMap(
      options: MapOptions(
        initialCenter: anchor == null
            ? const LatLng(15, 101)
            : LatLng(anchor!.latitude, anchor!.longitude),
        initialZoom: anchor == null ? 5 : 12,
        initialCameraFit: fit
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(
                  results.map((p) => p.point).toList(),
                ),
                padding: const EdgeInsets.all(30),
                maxZoom: 15,
              )
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment(
            'TILE_URL',
            defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          userAgentPackageName: 'com.imlv1.trippocket',
        ),
        PoiMapLayer(
          category: category,
          province: province,
          query: query,
          onSelected: onSelected,
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  '© OpenStreetMap contributors • ODbL',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
