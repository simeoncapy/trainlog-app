import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/widgets/osm_mark.dart';

/// iOS: the OpenStreetMap credit in a small Liquid Glass capsule.
class CupertinoOsmMark extends StatelessWidget {
  const CupertinoOsmMark({super.key, required this.mark});

  final OsmMark mark;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      mark.text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: CupertinoColors.label.resolveFrom(context),
        letterSpacing: 0,
      ),
    );
    final vertical = mark.orientation == MarkOrientation.vertical;

    return Align(
      alignment: mark.alignment,
      child: Padding(
        padding: mark.margin,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: OsmMark.openCredit,
          child: LiquidGlass(
            padding: vertical
                ? const EdgeInsets.symmetric(horizontal: 3, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: mark.orient(label),
          ),
        ),
      ),
    );
  }
}
