import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/polyline_utils.dart';
import 'package:trainlog_app/widgets/dropdown_radio_list.dart';
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
  late Map<VehicleType, Color> _colours;

  // final Map<VehicleType, Color> _colours = {
  //       VehicleType.train: Colors.blue,
  //       VehicleType.plane: Colors.green,
  //       VehicleType.tram: Colors.lightBlue,
  //       VehicleType.metro: Colors.deepOrange,
  //       VehicleType.bus: Colors.deepPurple,
  //       VehicleType.car: Colors.purple,
  //       VehicleType.ferry: Colors.teal,
  //       VehicleType.unknown: Colors.grey,
  //     };

  Set<int> _selectedYears = {};
  Set<VehicleType> _selectedTypes = {};
  bool _showFilterModal = false;
  int _selectedYearFilterOption = 0;

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
    final settings = context.read<SettingsProvider>();
    _colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    _loadPolylines();

    // Trigger FAB rebuild after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadPolylines() async {
    final repo = context.read<TripsProvider>().repository;
    final settings = context.read<SettingsProvider>();
    if (repo != null) {
      final pathData = await repo.getPathExtendedData(settings.pathDisplayOrder);      

      final args = {
        'entries': pathData,
        'colors': _colours,
      };
      final polylines = await compute(decodePolylinesBatch, args);

      if (mounted) {
        setState(() {
          _polylines = polylines;
          _loading = false;
          _selectedYears = availableYears.toSet();
          _selectedTypes = availableTypes.toSet();
        });
        widget.onFabReady(buildFloatingActionButton(context)!);
      }
    }
  }

  void _sortedPolylines(List<PolylineEntry> filteredPolylines, PathDisplayOrder displayOrder)
  {
    switch (displayOrder) {
      case PathDisplayOrder.creationDate:
        filteredPolylines.sort((a, b) =>
            (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDate:
        filteredPolylines.sort((a, b) =>
            (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = filteredPolylines
            .where((e) => e.type != VehicleType.plane)
            .toList()
          ..sort((a, b) => (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        final air = filteredPolylines
            .where((e) => e.type == VehicleType.plane)
            .toList()
          ..sort((a, b) => (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        filteredPolylines
          ..clear()
          ..addAll(nonAir)
          ..addAll(air);
        break;
    }
  }

  void _changePolylineColor(Map<VehicleType, Color> newPalette)
  {
    setState(() {
      _polylines = _polylines.map((entry) {
        final newColor = newPalette[entry.type] ?? Colors.grey;

        return PolylineEntry(
          type: entry.type,
          startDate: entry.startDate,
          creationDate: entry.creationDate,
          isFuture: entry.isFuture,
          polyline: Polyline(
            points: entry.polyline.points,
            color: newColor,
            pattern: entry.isFuture
                ? StrokePattern.dashed(segments: [20, 20])
                : StrokePattern.solid(),
            strokeWidth: 4.0,
          ),
        );
      }).toList();
    });
  }


  @override
Widget build(BuildContext context) {
  final appLocalizations = AppLocalizations.of(context)!;
  final settings = context.watch<SettingsProvider>();
  final displayOrder = settings.pathDisplayOrder;
  final newPalette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

  if(newPalette != _colours)
  {
    _colours = newPalette;
    _changePolylineColor(newPalette);
  }

  // Filtered list first
  final filteredPolylines = _polylines.where((e) =>
    (_selectedYears.isEmpty || _selectedYears.contains(e.startDate?.year)) &&
    (_selectedTypes.isEmpty || _selectedTypes.contains(e.type))
  ).toList();
  _sortedPolylines(filteredPolylines, displayOrder);

  return _loading
      ? Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                appLocalizations.tripPathLoading,
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
                      _center = position.center;
                      _zoom = position.zoom;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'me.trainlog.app',//'fr.scapy.app',
                ),
                PolylineLayer(
                  polylines: filteredPolylines.map((e) => e.polyline).toList(),
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
                        Text(appLocalizations.yearTitle, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        _yearFilterBuilder(),
                        const SizedBox(height: 16),
                        Text(appLocalizations.typeTitle, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        _typeFilterBuilder(context),
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
                            icon: Icon(Icons.close),
                            label: Text(MaterialLocalizations.of(context).closeButtonLabel),
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

  DropdownRadioList _yearFilterBuilder() {
    return DropdownRadioList(
      items: [
        MultiLevelItem(title: AppLocalizations.of(context)!.yearAllList, subItems: []),
        MultiLevelItem(title: AppLocalizations.of(context)!.yearPastList, subItems: []),
        MultiLevelItem(title: AppLocalizations.of(context)!.yearFutureList, subItems: []),
        MultiLevelItem(title: AppLocalizations.of(context)!.yearYearList, subItems: availableYears.map((e) => e.toString()).toList()),
      ],
      selectedTopIndex: _selectedYearFilterOption,
      selectedSubStates: {3: availableYears.map((year) => _selectedYears.contains(year)).toList()},
      onChanged: (top, sub) {
        setState(() {
          switch (top)
          {
            case 0: // all
              _selectedYears = availableYears.toSet();
              break;
            case 1: // past
              // TODO
              break;
            case 2: // future
              // TODO
              break;
            case 3: // years
              _selectedYears = sub.asMap().entries
                .where((e) => e.value)
                .map((e) => availableYears[e.key])
                .toSet();
              break;
          }
          _selectedYearFilterOption = top;
        });

      },
    );
  }

  Wrap _typeFilterBuilder(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTypes.map((type) {
        final selected = _selectedTypes.contains(type);
        final backgroundColor = _colours[type];
        final brightness = backgroundColor != null
            ? ThemeData.estimateBrightnessForColor(backgroundColor)
            : Brightness.light; // Default fallback

        final textColor = brightness == Brightness.dark ? Colors.white : Colors.black;
        return FilterChip(
          label: Text(
            type.label(context),
            style: TextStyle(color: selected? textColor : Theme.of(context).chipTheme.labelStyle?.color),
          ),
          avatar: IconTheme(
            data: IconThemeData(
              color: selected
                  ? textColor
                  : Theme.of(context).chipTheme.labelStyle?.color,
            ),
            child: type.icon(),
          ),
          selectedColor: backgroundColor,// != null ? WidgetStateProperty.all(backgroundColor) : null,
          selected: selected,
          showCheckmark: false,
          onSelected: (_) {
            setState(() {
              selected ? _selectedTypes.remove(type) : _selectedTypes.add(type);
            });
          },
        );
      }).toList(),
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

