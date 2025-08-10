import 'dart:math' as math;
import 'package:flutter/material.dart';

class MinHeightScrollable extends StatelessWidget {
  final double minHeight;
  final Widget child;
  const MinHeightScrollable({
    super.key,
    required this.minHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetHeight = math.max(minHeight, constraints.maxHeight);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SizedBox(
              height: targetHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
