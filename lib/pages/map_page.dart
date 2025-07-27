import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/polyline_utils.dart';
import '../providers/trips_provider.dart';

class MapPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;

  const MapPage({super.key, required this.onFabReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(35.681236, 139.767125);
  double _zoom = 13.0;
  List<PolylineEntry> _polylines = [];
  bool _loading = true;

  Set<int> _selectedYears = {};
  Set<VehicleType> _selectedTypes = {};
  bool _showFilterModal = false;

  List<int> get availableYears => _polylines
      .map((e) => e.startDate?.year)
      .whereType<int>()
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  List<VehicleType> get availableTypes => _polylines
      .map((e) => e.type)
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    _loadPolylines();

    // Trigger FAB rebuild after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {}); // This is safe and will force the FAB to be reevaluated
    });
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
        widget.onFabReady(buildFloatingActionButton(context)!);
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
                'Trips\' path loading, please wait',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
      : Stack(
          children: [
            FlutterMap(
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
                PolylineLayer(
                  polylines: _polylines
                      .where((e) =>
                          (_selectedYears.isEmpty ||
                              _selectedYears.contains(e.startDate?.year)) &&
                          (_selectedTypes.isEmpty ||
                              _selectedTypes.contains(e.type)))
                      .map((e) => e.polyline)
                      .toList(),
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
            ),
            if (_showFilterModal)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Années", style: Theme.of(context).textTheme.titleLarge),
                        Wrap(
                          spacing: 8,
                          children: availableYears.map((year) {
                            final selected = _selectedYears.contains(year);
                            return FilterChip(
                              label: Text(year.toString()),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selected ? _selectedYears.remove(year) : _selectedYears.add(year);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text("Types de véhicule", style: Theme.of(context).textTheme.titleLarge),
                        Wrap(
                          spacing: 8,
                          children: availableTypes.map((type) {
                            final selected = _selectedTypes.contains(type);
                            return FilterChip(
                              label: Text(type.label(context)),
                              avatar: type.icon(),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selected ? _selectedTypes.remove(type) : _selectedTypes.add(type);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showFilterModal = false;
                                widget.onFabReady(buildFloatingActionButton(context)!);
                              });
                            },
                            icon: Icon(Icons.check),
                            label: Text('OK'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
}


  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    if (_showFilterModal) return null;

    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showFilterModal = true;
          widget.onFabReady(null); // Hide FAB
        });
      },
      child: Icon(Icons.filter_alt),
    );
  }
}

