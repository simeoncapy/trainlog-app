import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class MinHeightScrollable extends StatelessWidget {
  const MinHeightScrollable({
    super.key,
    required this.minHeight,
    required this.child,
    this.padding,
  });

  final double minHeight;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          // optional: AlwaysScrollable helps on tall screens
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              // key change: only a MIN height; allow growth beyond viewport
              minHeight: math.max(minHeight, constraints.maxHeight),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
