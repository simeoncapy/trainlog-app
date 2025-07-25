import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(35.681236, 139.767125);
  double _zoom = 13.0;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: _zoom,
        keepAlive: true,  // prevents reset on rebuild inside PageView or tabs
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            // position.center or position.zoom updated → update state
            setState(() {
              _center = position.center ?? _center;
              _zoom = position.zoom ?? _zoom;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'fr.scapy.app', // TODO Change the User Agent, and the URL
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 80,
              height: 80,
              point: LatLng(35.681236, 139.767125),
              child: const Icon(Icons.location_pin, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}
