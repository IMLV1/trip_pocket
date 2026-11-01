import 'curated_places.dart';
import 'poi_map_layer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';
import '../../core/widgets.dart';
import 'thailand_boundary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../activities/domain/trip_activity.dart';

Color categoryColor(String category) => switch (category) {
  'attraction' => Colors.teal,
  'food' => Colors.deepOrange,
  'lodging' => Colors.indigo,
  _ => Colors.blueGrey,
};

class DailyMap extends ConsumerStatefulWidget {
  final List<TripActivity> activities;
  final LatLng? destination;
  final String destinationLabel;
  final void Function(TripActivity) onSelect;
  final void Function(LatLng)? onAdd;
  final void Function(CuratedPlace)? onChoosePlace;
  const DailyMap({
    super.key,
    required this.activities,
    this.destination,
    this.destinationLabel = '',
    required this.onSelect,
    this.onAdd,
    this.onChoosePlace,
  });
  @override
  ConsumerState<DailyMap> createState() => _DailyMapState();
}

class _DailyMapState extends ConsumerState<DailyMap> {
  final controller = MapController();
  LocationFix? fix;
  bool locating = false;
  List<LatLng> get points => [
    ...widget.activities.map((a) => LatLng(a.latitude, a.longitude)),
    if (widget.destination != null) widget.destination!,
  ];

  @override
  void didUpdateWidget(DailyMap old) {
    super.didUpdateWidget(old);
    final before = [
      ...old.activities.map((a) => LatLng(a.latitude, a.longitude)),
      if (old.destination != null) old.destination!,
    ];
    final after = points;
    if (after.isNotEmpty && !listEquals(before, after)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) fitStops(after);
      });
    }
  }

  void fitStops(List<LatLng> stops) => controller.fitCamera(
    CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(stops),
      padding: const EdgeInsets.all(36),
      maxZoom: 15,
    ),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    if (locating) return;
    setState(() => locating = true);
    try {
      final result = await ref.read(locationProvider).locate();
      if (!mounted) return;
      setState(() => fix = result);
      controller.move(result.point, 14);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  bool recommendations = true;
  String poiCategory = 'all';
  bool failed = false;
  int attempt = 0;
  @override
  Widget build(BuildContext context) {
    final points = this.points;
    if (points.isEmpty) points.add(const LatLng(15, 101));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failed)
          Row(
            children: [
              const Expanded(
                child: Text('โหลดพื้นแผนที่ไม่ได้ หมุดและรายการยังใช้งานได้'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  failed = false;
                  attempt++;
                }),
                child: const Text('ลองโหลดแผนที่'),
              ),
            ],
          ),
        SizedBox(
          height: 360,
          child: FlutterMap(
            mapController: controller,
            key: ValueKey(
              '${points.map((p) => '${p.latitude},${p.longitude}').join(';')}/$attempt',
            ),
            options: MapOptions(
              initialCenter: points.first,
              initialZoom:
                  widget.activities.isEmpty && widget.destination == null
                  ? 5
                  : 13,
              onTap: (tap, p) async {
                if (widget.onAdd == null) return;
                final boundary = await ThailandBoundary.load();
                if (!context.mounted) return;
                if (!boundary.contains(p)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'กรุณาเลือกจุดหมายในประเทศไทยตามขอบเขตโดยประมาณ',
                      ),
                    ),
                  );
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('เพิ่มจุดหมายตรงนี้?'),
                    content: const Text('ใส่ชื่อและรายละเอียดในขั้นตอนถัดไป'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('ยกเลิก'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('เพิ่มจุดหมายที่นี่'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) widget.onAdd?.call(p);
              },
              initialCameraFit:
                  widget.activities.isEmpty && widget.destination == null
                  ? CameraFit.bounds(
                      bounds: LatLngBounds(
                        const LatLng(5.6, 97.3),
                        const LatLng(20.5, 105.7),
                      ),
                      padding: const EdgeInsets.all(24),
                    )
                  : points.length > 1
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(36),
                      maxZoom: 15,
                    )
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: const String.fromEnvironment(
                  'TILE_URL',
                  defaultValue:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                userAgentPackageName: 'com.imlv1.trippocket',
                errorTileCallback: (tile, e, s) {
                  if (!failed) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => failed = true);
                    });
                    WidgetsBinding.instance.ensureVisualUpdate();
                  }
                },
              ),
              if (recommendations)
                PoiMapLayer(
                  category: poiCategory,
                  onSelected: widget.onChoosePlace == null
                      ? null
                      : (p) async {
                          final chosen = await chooseSuggestedPlace(context, p);
                          if (chosen != null && mounted) {
                            widget.onChoosePlace?.call(chosen);
                          }
                        },
                ),
              MarkerLayer(
                markers: [
                  if (widget.destination != null)
                    Marker(
                      point: widget.destination!,
                      width: 52,
                      height: 52,
                      child: Semantics(
                        label: 'พื้นที่หลักของทริป ${widget.destinationLabel}',
                        child: Tooltip(
                          message: 'พื้นที่หลัก: ${widget.destinationLabel}',
                          child: const Icon(
                            Icons.location_pin,
                            size: 50,
                            color: Color(0xff126b5e),
                          ),
                        ),
                      ),
                    ),
                  if (fix != null)
                    Marker(
                      point: fix!.point,
                      width: 32,
                      height: 32,
                      child: Semantics(
                        label: 'ตำแหน่งของฉันที่อ่านล่าสุด',
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  for (var i = 0; i < widget.activities.length; i++)
                    Marker(
                      point: points[i],
                      width: 48,
                      height: 48,
                      child: Semantics(
                        label: 'หมุด ${i + 1} ${widget.activities[i].title}',
                        button: true,
                        child: InkWell(
                          onTap: () => widget.onSelect(widget.activities[i]),
                          child: CircleAvatar(
                            backgroundColor: categoryColor(
                              widget.activities[i].category,
                            ),
                            foregroundColor: Colors.white,
                            child: Text('${i + 1}'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  child: InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 11, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('สถานที่แนะนำบนแผนที่'),
          subtitle: const Text('ไอคอนสีน้ำเงิน = แนะนำ • เลขหมุด = จุดในทริป'),
          value: recommendations,
          onChanged: (v) => setState(() => recommendations = v),
        ),
        if (recommendations)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in {
                  'all': 'ทั้งหมด',
                  ...activityCategories,
                }.entries)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: poiCategory == e.key,
                      onSelected: (_) => setState(() => poiCategory = e.key),
                    ),
                  ),
              ],
            ),
          ),
        Wrap(
          children: [
            TextButton.icon(
              key: const Key('my-location'),
              onPressed: locating ? null : locate,
              icon: const Icon(Icons.my_location),
              label: Text(locating ? 'กำลังหาตำแหน่ง…' : 'ตำแหน่งของฉัน'),
            ),
            TextButton(
              onPressed: () => controller.fitCamera(
                CameraFit.bounds(
                  bounds:
                      widget.activities.isEmpty && widget.destination == null
                      ? LatLngBounds(
                          const LatLng(5.6, 97.3),
                          const LatLng(20.5, 105.7),
                        )
                      : LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(36),
                  maxZoom: 15,
                ),
              ),
              child: const Text('ดูจุดหมายทั้งหมด'),
            ),
          ],
        ),
        if (fix != null)
          Text(
            'ตำแหน่งที่อ่านล่าสุด • ความคลาดเคลื่อนประมาณ ${fix!.accuracy.round()} เมตร • ${fix!.timestamp.toLocal().toString().substring(0, 19)}',
          ),
        const Text(
          'อ่านเมื่อกดปุ่มเท่านั้น ไม่ติดตามเบื้องหลังหรือบันทึกลงบัญชี',
        ),
        const Text(
          'แตะแผนที่เพิ่มจุดหมาย • แตะเลขหมุดเพื่อแก้ไข • ไม่มีเส้นทางถนนในแอป',
        ),
      ],
    );
  }
}
