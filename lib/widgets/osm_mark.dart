import 'package:flutter/widgets.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/widgets/cupertino/osm_mark_cupertino.dart';
import 'package:trainlog_app/widgets/material/osm_mark_material.dart';
import 'package:url_launcher/url_launcher.dart';

enum MarkOrientation { horizontal, vertical }

/// The OpenStreetMap credit shown over a map; tapping it opens the OSM
/// copyright page. A translucent tag on Android, a Liquid Glass capsule on
/// iOS.
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

  String get text => isCompact ? osmCreditCompact : osmCredit;

  /// [label], turned upwards when the mark is [MarkOrientation.vertical].
  Widget orient(Widget label) => orientation == MarkOrientation.horizontal
      ? label
      : RotatedBox(quarterTurns: 3, child: label);

  static void openCredit() => launchUrl(
    Uri.parse(osmCreditUrl),
    mode: LaunchMode.externalApplication,
  );

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialOsmMark(mark: this),
    cupertino: (_) => CupertinoOsmMark(mark: this),
  );
}
