// แผนที่ขนาดเล็กแบบดูอย่างเดียว แสดงหมุดพื้นที่หลักของทริป

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Read-only destination preview; choosing a new point uses the confirmed picker.
class DestinationPreview extends StatelessWidget {
  final LatLng point;
  final String label;
  const DestinationPreview({
    super.key,
    required this.point,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 190,
      child: FlutterMap(
        key: ValueKey('${point.latitude}/${point.longitude}'),
        options: MapOptions(
          initialCenter: point,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: const String.fromEnvironment(
              'TILE_URL',
              defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            userAgentPackageName: 'com.imlv1.trippocket',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 48,
                height: 48,
                child: Semantics(
                  label: 'หมุดพื้นที่หลัก $label',
                  child: const Icon(
                    Icons.location_pin,
                    size: 46,
                    color: Color(0xff126b5e),
                  ),
                ),
              ),
            ],
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
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
