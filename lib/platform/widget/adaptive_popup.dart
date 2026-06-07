import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/platform/widget/adaptive_widget_base.dart';

/// A single item in an [AdaptivePopup] menu.
class AdaptivePopupItem<T> {
  const AdaptivePopupItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A popup menu button that uses [PopupMenuButton] on Material and a
/// [CupertinoActionSheet] on Apple platforms.
///
/// The [child] is the widget used as the tap target to open the menu.
class AdaptivePopup<T> extends AdaptiveWidget {
  const AdaptivePopup({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.initialValue,
    this.enabled = true,
  });

  final List<AdaptivePopupItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget child;
  final T? initialValue;
  final bool enabled;

  @override
  Widget buildMaterial(BuildContext context) {
    return PopupMenuButton<T>(
      enabled: enabled,
      initialValue: initialValue,
      onSelected: onSelected,
      itemBuilder: (_) => items
          .map((item) => PopupMenuItem<T>(
                value: item.value,
                child: Text(item.label),
              ))
          .toList(),
      child: child,
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () => showCupertinoModalPopup<void>(
                context: context,
                builder: (_) => CupertinoActionSheet(
                  actions: items
                      .map(
                        (item) => CupertinoActionSheetAction(
                          isDefaultAction: item.value == initialValue,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onSelected(item.value);
                          },
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(CupertinoLocalizations.of(context).cancelButtonLabel),
                  ),
                ),
              )
          : null,
      child: child,
    );
  }
}
