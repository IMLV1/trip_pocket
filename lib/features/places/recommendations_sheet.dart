import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../activities/domain/trip_activity.dart';
import '../../core/validation.dart';
import '../../core/design_system.dart';
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
  String category = 'all', query = '', province = '', district = '';
  String subdistrict = '';
  bool showMap = false, filters = false;
  String? resultKey;
  PlaceResults? result;
  Future<void> select(CuratedPlace place) async {
    final confirmed = await chooseSuggestedPlace(context, place);
    if (confirmed != null && mounted) Navigator.pop(context, confirmed);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: SizedBox(
          height: (MediaQuery.sizeOf(context).height * .9 - inset).clamp(
            170.0,
            MediaQuery.sizeOf(context).height * .9,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ค้นหา / แนะนำทั่วไทย',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'ปิดคำแนะนำ',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  key: const Key('place-search'),
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    labelText: 'ค้นหาชื่อสถานที่ จังหวัด อำเภอ หรือตำบล',
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
                            '${identityHashCode(catalog)}/$query/$category/$province/$district/$subdistrict';
                        if (resultKey != key) {
                          resultKey = key;
                          result = catalog.search(
                            query: query,
                            category: category,
                            province: province,
                            district: district,
                            subdistrict: subdistrict,
                            near: query.trim().isEmpty && widget.anchor != null
                                ? LatLng(
                                    widget.anchor!.latitude,
                                    widget.anchor!.longitude,
                                  )
                                : null,
                          );
                        }
                        final matches = result!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (inset == 0) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () =>
                                            setState(() => filters = !filters),
                                        icon: const Icon(Icons.tune),
                                        label: Text(
                                          province.isEmpty
                                              ? 'ตัวกรองสถานที่'
                                              : [
                                                  subdistrict,
                                                  district,
                                                  province,
                                                ].firstWhere(
                                                  (e) => e.isNotEmpty,
                                                ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('place-list-view'),
                                      tooltip: 'แสดงรายการ',
                                      onPressed: () =>
                                          setState(() => showMap = false),
                                      isSelected: !showMap,
                                      icon: const Icon(
                                        Icons.view_list_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('place-map-view'),
                                      tooltip: 'แสดงแผนที่',
                                      onPressed: () =>
                                          setState(() => showMap = true),
                                      isSelected: showMap,
                                      icon: const Icon(Icons.map_outlined),
                                    ),
                                  ],
                                ),
                              ),
                              if (filters)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                    onChanged: (v) => setState(() {
                                      province = v!;
                                      district = '';
                                      subdistrict = '';
                                    }),
                                    decoration: const InputDecoration(
                                      labelText: 'จังหวัด',
                                    ),
                                  ),
                                ),
                              if (filters && province.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: AreaDropdown(
                                          key: ValueKey(
                                            'poi-district/$province',
                                          ),
                                          label: 'อำเภอ/เขต',
                                          allLabel: 'ทุกอำเภอ',
                                          value: district,
                                          options: catalog.districtsOf(
                                            province,
                                          ),
                                          onChanged: (v) => setState(() {
                                            district = v;
                                            subdistrict = '';
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AreaDropdown(
                                          key: ValueKey(
                                            'poi-subdistrict/$province/$district',
                                          ),
                                          label: 'ตำบล/แขวง',
                                          allLabel: 'ทุกตำบล',
                                          value: subdistrict,
                                          options: catalog.subdistrictsOf(
                                            province,
                                            district,
                                          ),
                                          onChanged: (v) =>
                                              setState(() => subdistrict = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (filters)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
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
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Text(
                                'พบ ${matches.total} แห่ง • แสดง ${matches.places.length} แห่งแรก',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Expanded(
                              child: showMap && inset == 0
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: DiscoveryMap(
                                          key: ValueKey(
                                            '$query/$province/$district/$subdistrict/$category',
                                          ),
                                          results: matches.places,
                                          category: category,
                                          province: province,
                                          district: district,
                                          subdistrict: subdistrict,
                                          query: query,
                                          anchor: widget.anchor,
                                          onSelected: select,
                                        ),
                                      ),
                                    )
                                  : matches.total == 0
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          'ไม่พบในข้อมูล ลองคำสั้นลง เปลี่ยนพื้นที่/หมวด หรือเลือกหมุดเอง',
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      key: const Key('place-results'),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      itemCount: matches.places.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (c, i) {
                                        final p = matches.places[i];
                                        return Card(
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8,
                                                ),
                                            leading: CircleAvatar(
                                              backgroundColor: TripColors.mint,
                                              child: Icon(
                                                placeIcon(p.category),
                                                color: TripColors.primary,
                                              ),
                                            ),
                                            title: Text(p.name),
                                            subtitle: Text(
                                              '${activityCategories[p.category]} • ${placeArea(p)}\nยังไม่ทราบราคา',
                                            ),
                                            trailing: IconButton(
                                              key: ValueKey(
                                                'recommend-${p.id}',
                                              ),
                                              tooltip: 'เลือกสถานที่นี้',
                                              onPressed: () => select(p),
                                              icon: const Icon(
                                                Icons.add_location_alt_outlined,
                                              ),
                                            ),
                                            onTap: () => select(p),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            if (inset == 0)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  6,
                                  20,
                                  0,
                                ),
                                child: Text(
                                  '${widget.remaining < 0 ? 'เกินงบ' : 'เหลือจากราคาที่ทราบ'} ${money(widget.remaining.abs())} บาท • ราคาสถานที่ยังไม่ทราบ จึงยืนยันว่าอยู่ในงบไม่ได้',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            if (inset == 0)
                              TextButton(
                                onPressed: () => launchUrl(
                                  Uri.parse(
                                    'https://www.openstreetmap.org/copyright',
                                  ),
                                ),
                                child: const Text(
                                  '© OpenStreetMap contributors • ODbL • เขตปกครอง: กรมแผนที่ทหาร/OCHA',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
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
}

class AreaDropdown extends StatelessWidget {
  final String label, allLabel, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const AreaDropdown({
    super.key,
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    items: [
      DropdownMenuItem(value: '', child: Text(allLabel)),
      for (final o in options)
        DropdownMenuItem(
          value: o,
          child: Text(o, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: options.isEmpty ? null : (v) => onChanged(v!),
    decoration: InputDecoration(labelText: label),
  );
}

class DiscoveryMap extends StatelessWidget {
  final List<CuratedPlace> results;
  final String category, province, district, subdistrict, query;
  final TripActivity? anchor;
  final void Function(CuratedPlace) onSelected;
  const DiscoveryMap({
    super.key,
    required this.results,
    required this.category,
    required this.province,
    this.district = '',
    this.subdistrict = '',
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
            : anchor == null
            ? CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(5.6, 97.3),
                  const LatLng(20.5, 105.7),
                ),
                padding: const EdgeInsets.all(24),
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
          district: district,
          subdistrict: subdistrict,
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
