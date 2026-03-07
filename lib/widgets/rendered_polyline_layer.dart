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

  @override
  void dispose() {
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
          onTapUp: (_) async {
            final result = _hitNotifier.value;
            if (result == null) return;

            for (final hit in result.hitValues) {
              await widget.onTripTap(hit);
              break;
            }
          },
          child: PolylineLayer<int>(
            hitNotifier: _hitNotifier,
            polylines: data.polylines,
          ),
        );
      },
    );
  }
}