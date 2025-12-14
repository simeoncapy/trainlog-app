import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// MINI MAP BOX (WITH OPTIONAL MOVABLE COORDINATES + FULLSCREEN)
// ---------------------------------------------------------------------------

class MiniMapBox extends StatefulWidget {
  final double? lat;
  final double? long;
  final String emptyMessage;
  final Color markerColor;
  final IconData marker;
  final double zoom;
  final double? size;

  // NEW
  final bool isCoordinateMovable;
  final void Function(double lat, double long)? onCoordinateChanged;

  const MiniMapBox({
    super.key,
    required this.lat,
    required this.long,
    required this.emptyMessage,
    required this.markerColor,
    this.marker = Icons.location_pin,
    this.zoom = 13,
    this.size,

    // NEW defaults
    this.isCoordinateMovable = false,
    this.onCoordinateChanged,
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

    if (!_mapReady) return;

    final updated = widget.lat != oldWidget.lat || widget.long != oldWidget.long;

    // Outside change: recenter map
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
        final width = constraints.maxWidth;
        return SizedBox(
          width: width,
          height: width,
          child: _buildContent(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------

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

    return Stack(
      children: [
        _buildMap(),

        // NEW — the centered pin, only when movable
        if (widget.isCoordinateMovable)
          Center(
            child: Icon(widget.marker, size: 40, color: widget.markerColor),
          ),

        // Maximize button (unchanged)
        Positioned(
          top: 8,
          right: 8,
          child: ClipOval(
            child: Material(
              color: Colors.black.withOpacity(0.5),
              child: InkWell(
                onTap: _openFullScreenMap,
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.fullscreen, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MAP LOGIC
  // ---------------------------------------------------------------------------

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.lat!, widget.long!),
        initialZoom: widget.zoom,
        onMapReady: () {
          setState(() => _mapReady = true);
        },

        // NEW — notify parent when user moves the map
        onPositionChanged: (pos, _) {
          if (!widget.isCoordinateMovable) return;
          if (pos.center == null) return;

          widget.onCoordinateChanged?.call(
            pos.center.latitude,
            pos.center.longitude,
          );
        },

        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'me.trainlog.app',
        ),

        // Normal pin only when not movable
        if (!widget.isCoordinateMovable)
          MarkerLayer(markers: [
            Marker(
              width: 40,
              height: 40,
              point: LatLng(widget.lat!, widget.long!),
              child: Icon(widget.marker,
                  size: 40, color: widget.markerColor),
            ),
          ]),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FULLSCREEN
  // ---------------------------------------------------------------------------

  void _openFullScreenMap() {
    if (widget.lat == null || widget.long == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, anim1, anim2) {
          return FullscreenMapOverlay(
            lat: widget.lat!,
            long: widget.long!,
            zoom: widget.zoom,
            markerColor: widget.markerColor,
            marker: widget.marker,
            isCoordinateMovable: widget.isCoordinateMovable,     // NEW
            onCoordinateChanged: widget.onCoordinateChanged,      // NEW
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FULLSCREEN MAP OVERLAY (supports movable coordinates too)
// ---------------------------------------------------------------------------

class FullscreenMapOverlay extends StatefulWidget {
  final double lat;
  final double long;
  final double zoom;
  final Color markerColor;
  final IconData marker;

  final bool isCoordinateMovable;                     // NEW
  final void Function(double lat, double long)? onCoordinateChanged; // NEW

  const FullscreenMapOverlay({
    super.key,
    required this.lat,
    required this.long,
    required this.zoom,
    required this.markerColor,
    required this.marker,
    required this.isCoordinateMovable,
    this.onCoordinateChanged,
  });

  @override
  State<FullscreenMapOverlay> createState() => _FullscreenMapOverlayState();
}

class _FullscreenMapOverlayState extends State<FullscreenMapOverlay> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: LatLng(widget.lat, widget.long),
              initialZoom: widget.zoom,

              // NEW movable coordinate tracking
              onPositionChanged: (pos, _) {
                if (!widget.isCoordinateMovable) return;
                if (pos.center == null) return;

                widget.onCoordinateChanged?.call(
                  pos.center!.latitude,
                  pos.center!.longitude,
                );
              },

              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'me.trainlog.app',
              ),

              if (!widget.isCoordinateMovable)
                MarkerLayer(markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(widget.lat, widget.long),
                    child: Icon(widget.marker,
                        size: 40, color: widget.markerColor),
                  ),
                ]),
            ],
          ),

          // NEW center pin when movable
          if (widget.isCoordinateMovable)
            Center(
              child: Icon(widget.marker, size: 40, color: widget.markerColor),
            ),

          // Exit fullscreen
          Positioned(
            top: 40,
            right: 20,
            child: ClipOval(
              child: Material(
                color: Colors.black.withOpacity(0.6),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.fullscreen_exit,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
