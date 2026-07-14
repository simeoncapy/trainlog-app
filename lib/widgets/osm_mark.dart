import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum MarkOrientation { horizontal, vertical }

class OsmMark extends StatelessWidget {
  final bool isCompact;
  final Alignment alignment;
  final EdgeInsets margin;
  final MarkOrientation orientation;

  static const osmCredit = "© OpenStreetMap";
  static const osmCreditCompact = "© OSM";
  static const osmCreditUrl = "https://www.openstreetmap.org/copyright";

  const OsmMark({
    super.key,
    this.isCompact = false,
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.all(6),
    this.orientation = MarkOrientation.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final text = isCompact ? osmCreditCompact : osmCredit;

    final label = Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: isCompact ? 9 : 11,
        decoration: TextDecoration.underline,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
      ),
    );

    final content = orientation == MarkOrientation.horizontal
        ? label
        : RotatedBox(
            quarterTurns: 3,
            child: label,
          );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: margin,
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => launchUrl(
              Uri.parse(osmCreditUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 6,
                vertical: 2,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}