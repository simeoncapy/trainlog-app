import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/design.dart';

/// A spinner: the iOS activity indicator or a Material circular one.
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({super.key, this.strokeWidth = 4});

  /// Width of the Material circle's line.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => CircularProgressIndicator(strokeWidth: strokeWidth),
    cupertino: (_) => const CupertinoActivityIndicator(),
  );
}
