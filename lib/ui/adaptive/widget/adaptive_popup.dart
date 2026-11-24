import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/ui/adaptive/widget/adaptive_widget_base.dart';

/// A single item in an [AdaptivePopup] menu.
///
/// [leading] is shown before the label on both platforms (icon, etc.).
class AdaptivePopupItem<T> {
  const AdaptivePopupItem({required this.value, required this.label, this.leading});

  final T value;
  final String label;
  final Widget? leading;
}

/// A popup menu button that uses [PopupMenuButton] on Material and a
/// Liquid Glass pull-down menu on Apple platforms.
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

  Widget _itemChild(AdaptivePopupItem<T> item) {
    if (item.leading == null) return Text(item.label);
    return Row(
      children: [
        item.leading!,
        const SizedBox(width: 10),
        Text(item.label),
      ],
    );
  }

  @override
  Widget buildMaterial(BuildContext context) {
    return PopupMenuButton<T>(
      enabled: enabled,
      initialValue: initialValue,
      onSelected: onSelected,
      itemBuilder: (_) => items
          .map((item) => PopupMenuItem<T>(
                value: item.value,
                child: _itemChild(item),
              ))
          .toList(),
      child: child,
    );
  }

  /// iOS 26 pull-down menu: the package's Liquid Glass menu morphing out of
  /// [child], the current value checked, an item's [AdaptivePopupItem.leading]
  /// on the trailing side as in Apple's menus.
  @override
  Widget buildCupertino(BuildContext context) {
    if (!enabled) return child;
    final label = CupertinoColors.label.resolveFrom(context);
    final checkable = initialValue != null;
    return lg.GlassMenu(
      trigger: child,
      menuWidth: 250,
      menuAlignment: lg.GlassMenuAlignment.topRight,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      items: [
        for (final item in items)
          lg.GlassMenuItem(
            title: item.label,
            titleStyle: TextStyle(fontSize: 17, color: label),
            icon: checkable
                ? SizedBox(
                    width: 20,
                    child: item.value == initialValue
                        ? const Icon(CupertinoIcons.checkmark, size: 17)
                        : null,
                  )
                : null,
            iconSize: 17,
            semanticsChecked: checkable ? item.value == initialValue : null,
            trailing: item.leading,
            onTap: () => onSelected(item.value),
          ),
      ],
    );
  }
}
