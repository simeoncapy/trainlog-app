import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_sheet.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// One choice in a [showBottomSheetPicker] sheet.
///
/// [label] is the primary line; [subtitle] (optional) renders beneath it.
/// [leading] and [trailing] are optional widgets shown before / after the text
/// (e.g. a flag emoji). The selected option additionally shows a check mark.
class BottomSheetPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const BottomSheetPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

/// Shows a modal bottom sheet listing [options] and resolves the user's choice
/// through [onChanged]. Shared across features (settings, ranking, …) so the
/// picker styling stays consistent and isn't duplicated.
///
/// The currently [selected] value is marked with a trailing check.
///
/// Android shows a Material modal bottom sheet. Apple shows a Liquid Glass
/// sheet over the tab bar, at half height and pulled up to full height (as
/// the trips filter sheet), with a glass ✕ beside the grab handle and the
/// options as an inset grouped list.
Future<void> showBottomSheetPicker<T>({
  required BuildContext context,
  required String title,
  required List<BottomSheetPickerOption<T>> options,
  required T selected,
  required ValueChanged<T> onChanged,
}) {
  if (AppPlatform.isApple) {
    return showAppleDetentSheet<void>(
      context: context,
      topInset: kAppleSheetHeaderInset,
      builder: (ctx) => _ApplePicker<T>(
        title: title,
        options: options,
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }

  return showAdaptiveContentSheet<void>(
    context: context,
    maxHeightFactor: 0.8,
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.8;
      final cs = Theme.of(ctx).colorScheme;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.value == selected;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        onChanged(option.value);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            if (option.leading != null) ...[
                              option.leading!,
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    option.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (option.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      option.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (option.trailing != null) ...[
                              const SizedBox(width: 12),
                              option.trailing!,
                            ],
                            if (isSelected) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.check_rounded, color: cs.primary),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The picker on Apple: ✕ / title bar level with the grab handle, then the
/// options in an inset grouped card, a check mark on the selected one.
class _ApplePicker<T> extends StatelessWidget {
  const _ApplePicker({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<BottomSheetPickerOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final tint = CupertinoTheme.of(context).primaryColor;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          child: Row(
            children: [
              GlassIconButton(
                icon: CupertinoIcons.xmark,
                shadow: false,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
              ),
              // Balances the ✕ so the title stays centred.
              const SizedBox(width: 44),
            ],
          ),
        ),
        Expanded(
          // No physics here: the sheet grows before the list scrolls.
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottom + 16),
            children: [
              GlassFormGroup(
                children: [
                  for (final o in options)
                    GlassFormRow(
                      title: o.label,
                      leading: o.leading,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (o.subtitle != null)
                            Text(
                              o.subtitle!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: secondary, letterSpacing: 0),
                            ),
                          if (o.trailing != null) ...[
                            const SizedBox(width: 8),
                            o.trailing!,
                          ],
                          SizedBox(
                            width: 28,
                            child: o.value == selected
                                ? Icon(
                                    CupertinoIcons.checkmark_alt,
                                    size: 20,
                                    color: tint,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onChanged(o.value);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
