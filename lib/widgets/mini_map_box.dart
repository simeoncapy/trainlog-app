import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMapBox extends StatefulWidget {
  final double? lat;
  final double? long;
  final String emptyMessage;
  final Color markerColor;
  final double zoom;
  final double? size;

  const MiniMapBox({
    super.key,
    required this.lat,
    required this.long,
    required this.emptyMessage,
    required this.markerColor,
    this.zoom = 13,
    this.size,
  });

  @override
  State<MiniMapBox> createState() => _MiniMapBoxState();
}

class _MiniMapBoxState extends State<MiniMapBox> {
  final MapController _mapController = MapController();
  bool _mapReady = false;


  @override
  void didUpdateWidget(covariant MiniMapBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_mapReady) return; // controller not ready yet

    final updated = widget.lat != oldWidget.lat || widget.long != oldWidget.long;

    if (updated && widget.lat != null && widget.long != null) {
      _mapController.move(
        LatLng(widget.lat!, widget.long!),
        widget.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _buildContent(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        return SizedBox(
          width: maxWidth,
          height: maxWidth,
          child: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    final hasCoords = widget.lat != null && widget.long != null;
    final theme = Theme.of(context);

    if (!hasCoords) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          widget.emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.lat!, widget.long!),
        initialZoom: widget.zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom,
        ),
        onMapReady: () {
          setState(() => _mapReady = true);

          // Immediately recenter once when map becomes ready
          if (widget.lat != null && widget.long != null) {
            _mapController.move(
              LatLng(widget.lat!, widget.long!),
              widget.zoom,
            );
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'me.trainlog.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40,
              height: 40,
              point: LatLng(widget.lat!, widget.long!),
              child: Icon(Icons.location_pin, size: 40, color: widget.markerColor),
            ),
          ],
        ),
      ],
    );
  }
}
