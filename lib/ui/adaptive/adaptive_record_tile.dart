import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveRecordTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  // NEW: control wrappers
  final bool materialUseCard;        // default true for your normal lists
  final bool cupertinoUseBackground; // default true for your normal lists

  const AdaptiveRecordTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.materialUseCard = true,
    this.cupertinoUseBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isApple) {
      final theme = Theme.of(context);

      final tile = ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        leading: leading,
        title: title,
        subtitle: subtitle,
        isThreeLine: true,
        selected: selected,
        trailing: trailing,
        onTap: onTap,
      );

      if (!materialUseCard) {
        // Plain list row (like your original dialog)
        return tile;
      }

      return Card(
        color: selected ? theme.colorScheme.primaryContainer : null,
        child: tile,
      );
    }

    // iOS
    final tile = CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      leading: SizedBox(width: 34, child: Center(child: leading)),
      title: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
        child: title,
      ),
      subtitle: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
        child: subtitle,
      ),
      trailing: trailing,
      onTap: onTap,
    );

    if (!cupertinoUseBackground) {
      // Plain row (no separate rounded “cell” blocks)
      return tile;
    }

    final selectedBg = CupertinoColors.systemFill.resolveFrom(context);
    //final selectedBg = CupertinoColors.secondaryLabel.resolveFrom(context);
    //final normalBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    //final normalBg = CupertinoColors.systemBackground.resolveFrom(context);
    //final normalBg = CupertinoColors.secondarySystemFill.resolveFrom(context);
    final normalBg = CupertinoColors.transparent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? selectedBg : normalBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: tile,
    );
  }
}
