import 'package:flutter/widgets.dart';
import 'package:trainlog_app/features/map/filter/cupertino/map_filter_cupertino_view.dart';
import 'package:trainlog_app/features/map/filter/material/map_filter_material_view.dart';
import 'package:trainlog_app/ui/design.dart';

/// Map filter sheet content: years and vehicle types shown on the map.
///
/// The state and actions live in [PolylineProvider] (shared); this entry
/// only picks the view. Host it with `showAdaptiveContentSheet`; [onClose]
/// dismisses the sheet (e.g. `Navigator.pop`).
class MapFilterSheet extends StatelessWidget {
  const MapFilterSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MapFilterMaterialView(onClose: onClose),
    cupertino: (_) => MapFilterCupertinoView(onClose: onClose),
  );
}
