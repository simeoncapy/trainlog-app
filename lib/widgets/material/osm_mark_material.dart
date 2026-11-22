import 'package:flutter/material.dart';
import 'package:trainlog_app/widgets/osm_mark.dart';

/// Android: the OpenStreetMap credit on a translucent surface tag.
class MaterialOsmMark extends StatelessWidget {
  const MaterialOsmMark({super.key, required this.mark});

  final OsmMark mark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = Text(
      mark.text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: mark.isCompact ? 9 : 11,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
      ),
    );

    return Align(
      alignment: mark.alignment,
      child: Padding(
        padding: mark.margin,
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: OsmMark.openCredit,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: mark.isCompact ? 4 : 6,
                vertical: 2,
              ),
              child: mark.orient(label),
            ),
          ),
        ),
      ),
    );
  }
}
