import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/map/map_page.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/features/map/widgets/locked_on_position_pill.dart';
import 'package:trainlog_app/features/map/widgets/map_canvas.dart';
import 'package:trainlog_app/features/map/widgets/map_controls.dart';
import 'package:trainlog_app/features/map/widgets/map_search_overlay.dart';
import 'package:trainlog_app/widgets/osm_mark.dart';

/// Map page, Material: the map with the OSM credit, the "locked on
/// position" pill, search / filter / compass at the top right, recenter /
/// follow above the "New trip" button, and a full-screen place search.
class MapMaterialView extends StatefulWidget {
  const MapMaterialView({super.key, required this.actions});

  final MapPageActions actions;

  @override
  State<MapMaterialView> createState() => _MapMaterialViewState();
}

class _MapMaterialViewState extends State<MapMaterialView> {
  late final MapSearchOverlay _search;

  @override
  void initState() {
    super.initState();
    _search = MapSearchOverlay(context.read<MapPageController>());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MapPageController>();
    final actions = widget.actions;

    return Stack(
      children: [
        MapCanvas(
          mapController: actions.mapController,
          rotation: actions.rotation,
        ),

        // The map runs under the status bar, so keep the credit below it.
        const SafeArea(
          child: OsmMark(isCompact: false, alignment: Alignment.topLeft),
        ),

        if (controller.following) const LockedOnPositionPill(),
        MapTopControls(
          rotation: actions.rotation,
          onSearch: () => _search.open(context),
          onFilter: actions.openFilter,
          onResetOrientation: actions.resetOrientation,
        ),
        MapLocationControls(
          following: controller.following,
          onRecenter: controller.recenter,
          onFollow: controller.toggleFollow,
        ),
      ],
    );
  }
}
