import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/pages/fab_interface.dart';
import 'package:trainlog_app/utils/polyline_utils.dart';
import '../providers/trips_provider.dart';

class MapPage extends StatefulWidget  implements FabPage {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
  
  @override
  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Action (e.g. open a filter)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Map FAB pressed')),
        );
      },
      child: const Icon(Icons.filter_alt),
    );
  }
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(35.681236, 139.767125);
  double _zoom = 13.0;
  List<PolylineEntry> _polylines = [];
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

      final Map<VehicleType, Color> colours = {
        VehicleType.train: Colors.blue,
        VehicleType.plane: Colors.green,
        VehicleType.tram: Colors.lightBlue,
        VehicleType.metro: Colors.deepOrange,
        VehicleType.bus: Colors.deepPurple,
        VehicleType.car: Colors.purple,
        VehicleType.ferry: Colors.teal,
        VehicleType.unknown: Colors.grey,
      };

      //final List<Polyline> polylines = [];
      final args = {
        'entries': pathData,
        'colors': colours,
      };
      final polylines = await compute(decodePolylinesBatch, args);

      if (mounted) {
        setState(() {
          _polylines = polylines;
          _loading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Trips\' path loading, please wait', //: ${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
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
              PolylineLayer(polylines: _polylines
                .where((e) => e.type == VehicleType.train && e.startDate?.year == 2025)
                .map((e) => e.polyline)
                .toList(),),
              MarkerLayer(markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: LatLng(35.681236, 139.767125),
                  child: const Icon(Icons.location_pin, color: Colors.red),
                ),
              ]),
            ],
          );
  }
}

