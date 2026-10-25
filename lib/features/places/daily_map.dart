import 'thailand_boundary.dart';
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

class DailyMap extends StatefulWidget {
  final List<TripActivity> activities;
  final void Function(TripActivity) onSelect;
  final void Function(LatLng)? onAdd;
  const DailyMap({
    super.key,
    required this.activities,
    required this.onSelect,
    this.onAdd,
  });
  @override
  State<DailyMap> createState() => _DailyMapState();
}

class _DailyMapState extends State<DailyMap> {
  bool failed = false;
  int attempt = 0;
  @override
  Widget build(BuildContext context) {
    final points = widget.activities
        .map((a) => LatLng(a.latitude, a.longitude))
        .toList();
    if (points.isEmpty) return const SizedBox.shrink();
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
          height: 280,
          child: FlutterMap(
            key: ValueKey(
              '${points.map((p) => '${p.latitude},${p.longitude}').join(';')}/$attempt',
            ),
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 13,
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
              initialCameraFit: points.length > 1
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
              MarkerLayer(
                markers: [
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
        const Text(
          'แตะแผนที่เพิ่มจุดหมาย • แตะเลขหมุดเพื่อแก้ไข • ไม่มีเส้นทางถนนในแอป',
        ),
      ],
    );
  }
}
