import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/design.dart';

/// Grab handle at the top of a sheet's content. Material sheets draw it
/// here; the iOS glass sheet draws its own, so nothing is drawn there.
class AdaptiveSheetHandle extends StatelessWidget {
  const AdaptiveSheetHandle({
    super.key,
    this.width = 40,
    this.height = 4,
    this.margin = EdgeInsets.zero,
  });

  final double width;
  final double height;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (context) => Center(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    ),
    cupertino: (_) => const SizedBox.shrink(),
  );
}
