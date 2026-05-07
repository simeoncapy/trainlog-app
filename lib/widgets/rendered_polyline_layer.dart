import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/providers/polyline_provider.dart';

class RenderedPolylineLayer extends StatefulWidget {
  final Future<void> Function(int tripId) onTripTap;

  const RenderedPolylineLayer({
    super.key,
    required this.onTripTap,
  });

  @override
  State<RenderedPolylineLayer> createState() => _RenderedPolylineLayerState();
}

class _RenderedPolylineLayerState extends State<RenderedPolylineLayer> {
  final LayerHitNotifier<int> _hitNotifier = ValueNotifier(null);
  Timer? _singleTapTimer;

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _hitNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PolylineProvider, ({List<Polyline<int>> polylines, int revision})>(
      selector: (_, provider) => (
        polylines: provider.renderedPolylines,
        revision: provider.renderRevision,
      ),
      shouldRebuild: (prev, next) => prev.revision != next.revision,
      builder: (context, data, child) {
        return GestureDetector(
          onTapUp: (_) {
            final result = _hitNotifier.value;
            if (result == null) return;
            final hit = result.hitValues.firstOrNull;
            if (hit == null) return;

            _singleTapTimer?.cancel();
            _singleTapTimer = Timer(const Duration(milliseconds: 150), () async {
              await widget.onTripTap(hit);
            });
          },
          onDoubleTap: () => _singleTapTimer?.cancel(),
          child: PolylineLayer<int>(
            hitNotifier: _hitNotifier,
            polylines: data.polylines,
          ),
        );
      },
    );
  }
}