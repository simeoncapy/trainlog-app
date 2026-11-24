import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveExpansionTile extends StatelessWidget {
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  final Widget? leading;
  final Widget title;
  final List<Widget> children;

  // Material-only options if you want them
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;

  const AdaptiveExpansionTile({
    super.key,
    required this.initiallyExpanded,
    this.onExpansionChanged,
    this.leading,
    required this.title,
    required this.children,
    this.tilePadding,
    this.childrenPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isApple) {
      return ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        leading: leading,
        title: title,
        tilePadding: tilePadding,
        childrenPadding: childrenPadding,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }

    // iOS: the package's Liquid Glass disclosure group (SwiftUI's
    // DisclosureGroup), on its own glass card.
    return lg.GlassDisclosureGroup.standalone(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: leading,
      title: title,
      showDividers: false,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ],
    );
  }
}
