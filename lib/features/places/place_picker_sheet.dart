import 'thailand_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

Future<LatLng?> pickPlace(BuildContext context, LatLng? initial) async {
  final boundary = await ThailandBoundary.load();
  if (!context.mounted) return null;
  return showModalBottomSheet<LatLng>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) => PlacePickerSheet(initial: initial, boundary: boundary),
  );
}

class PlacePickerSheet extends StatefulWidget {
  final LatLng? initial;
  final ThailandBoundary? boundary;
  const PlacePickerSheet({super.key, this.initial, this.boundary});
  @override
  State<PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<PlacePickerSheet> {
  late LatLng? selected = widget.initial;
  bool tileError = false;
  int attempt = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .85,
    child: Column(
      children: [
        ListTile(
          title: const Text('แตะแผนที่เพื่อเลือกหมุดในไทย'),
          trailing: IconButton(
            tooltip: 'ยกเลิก',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        if (tileError)
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('โหลดแผนที่บางส่วนไม่ได้ ตรวจอินเทอร์เน็ต'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  tileError = false;
                  attempt++;
                }),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        Expanded(
          child: FlutterMap(
            key: ValueKey(attempt),
            options: MapOptions(
              initialCenter: selected ?? const LatLng(15, 101),
              initialZoom: selected == null ? 5 : 13,
              onTap: (tap, p) {
                if (widget.boundary != null && !widget.boundary!.contains(p)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'เลือกหมุดในประเทศไทยตามขอบเขตโดยประมาณ • เกาะเล็ก/จุดริมแดนอาจไม่มีในข้อมูล',
                      ),
                    ),
                  );
                } else {
                  setState(() => selected = p);
                }
              },
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
                  if (!tileError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => tileError = true);
                    });
                    // A network failure can arrive while no frame is scheduled.
                    WidgetsBinding.instance.ensureVisualUpdate();
                  }
                },
              ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        size: 44,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              SimpleAttributionWidget(
                source: const Text('OpenStreetMap contributors'),
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                selected == null
                    ? 'ยังไม่ได้เลือกตำแหน่ง'
                    : '${selected!.latitude.toStringAsFixed(5)}, ${selected!.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('confirm-place'),
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(context, selected),
                child: const Text('ยืนยันตำแหน่ง'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
