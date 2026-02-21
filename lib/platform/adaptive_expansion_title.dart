import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveExpansionTile extends StatelessWidget {
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  final Widget leading;
  final Widget title;
  final List<Widget> children;

  // Material-only options if you want them
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;

  const AdaptiveExpansionTile({
    super.key,
    required this.initiallyExpanded,
    this.onExpansionChanged,
    required this.leading,
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
        children: children,
      );
    }

    return _CupertinoExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onChanged: onExpansionChanged,
      leading: leading,
      title: title,
      children: children,
    );
  }
}

class _CupertinoExpansionTile extends StatefulWidget {
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;
  final Widget leading;
  final Widget title;
  final List<Widget> children;

  const _CupertinoExpansionTile({
    required this.initiallyExpanded,
    this.onChanged,
    required this.leading,
    required this.title,
    required this.children,
  });

  @override
  State<_CupertinoExpansionTile> createState() => _CupertinoExpansionTileState();
}

class _CupertinoExpansionTileState extends State<_CupertinoExpansionTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: () {
              setState(() => _expanded = !_expanded);
              widget.onChanged?.call(_expanded);
            },
            child: Row(
              children: [
                widget.leading,
                const SizedBox(width: 10),
                Expanded(
                  child: DefaultTextStyle(
                    style: theme.textTheme.textStyle,
                    child: widget.title,
                  ),
                ),
                Icon(
                  _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  size: 18,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}
