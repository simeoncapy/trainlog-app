import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/map/cupertino/locked_on_position_pill_cupertino.dart';
import 'package:trainlog_app/features/map/cupertino/map_search_cupertino.dart';
import 'package:trainlog_app/features/map/map_page.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/features/map/widgets/map_canvas.dart';
import 'package:trainlog_app/features/map/widgets/map_controls.dart';
import 'package:trainlog_app/widgets/osm_mark.dart';

/// Map page, iOS: the map with the OSM credit (glass capsule), the glass
/// "locked on position" pill, "New trip" at the top right with the search on
/// its left and the filter (and compass) under it, the recenter / follow
/// capsule, and the place search
/// (a glass search bar above the keyboard, the results in a blurred panel).
class MapCupertinoView extends StatelessWidget {
  const MapCupertinoView({super.key, required this.actions});

  final MapPageActions actions;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MapPageController>();
    final searching = controller.searchOpen;

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

        if (controller.following && !searching)
          const CupertinoLockedOnPositionPill(),
        if (!searching) ...[
          MapTopControls(
            rotation: actions.rotation,
            onSearch: controller.openSearch,
            onFilter: actions.openFilter,
            onResetOrientation: actions.resetOrientation,
            newTrip: actions.newTrip,
          ),
          MapLocationControls(
            following: controller.following,
            onRecenter: controller.recenter,
            onFollow: controller.toggleFollow,
          ),
        ],
        if (searching) const Positioned.fill(child: CupertinoMapSearch()),
      ],
    );
  }
}
