import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import '../providers/trips_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(35.681236, 139.767125);
  double _zoom = 13.0;
  List<Polyline> _polylines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPolylines();
  }

  Future<void> _loadPolylines() async {
    final repo = context.read<TripsProvider>().repository;
    if (repo != null) {
      final pathData = await repo.getPathExtendedData();
      print("${pathData.length} lines");
      final limited = pathData.take(10).where((e) => (e['path'] ?? '').toString().isNotEmpty);

      final polylines = limited.map((e) {
        final path = e['path'] as String;
        final points = decodePolyline(path)
            .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
            .toList();
        return Polyline(points: points, color: Colors.blue, strokeWidth: 4.0);
      }).toList();

      setState(() {
        _polylines = polylines;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              keepAlive: true,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _center = position.center!;
                    _zoom = position.zoom!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'fr.scapy.app',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: _center,
                  child: const Icon(Icons.location_pin, color: Colors.red),
                ),
              ]),
            ],
          );
  }
}
