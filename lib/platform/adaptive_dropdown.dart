import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// A platform-adaptive dropdown selector.
///
/// - Material: renders a [DropdownButton].
/// - Cupertino: renders a styled tap-target that opens a [CupertinoActionSheet].
class AdaptiveDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final String Function(T item) labelOf;
  final Icon? Function(T item)? iconOf;
  final String hintText;
  final bool isExpanded;
  final bool enabled;

  const AdaptiveDropdown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
    this.hintText = 'Select an option',
    this.isExpanded = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return _CupertinoDropdown<T>(
        items: items,
        selectedValue: selectedValue,
        onChanged: onChanged,
        labelOf: labelOf,
        iconOf: iconOf,
        hintText: hintText,
        enabled: enabled,
      );
    }

    return DropdownButton<T>(
      hint: Text(hintText),
      value: selectedValue,
      isExpanded: isExpanded,
      onChanged: enabled ? onChanged : null,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Row(
            children: [
              if (iconOf != null) ...[
                iconOf!(item) ?? const SizedBox.shrink(),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  labelOf(item),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CupertinoDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final String Function(T item) labelOf;
  final Icon? Function(T item)? iconOf;
  final String hintText;
  final bool enabled;

  const _CupertinoDropdown({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
    required this.hintText,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final label = selectedValue != null ? labelOf(selectedValue as T) : hintText;
    final icon = (selectedValue != null && iconOf != null) ? iconOf!(selectedValue as T) : null;
    final labelColor = enabled
        ? CupertinoColors.label.resolveFrom(context)
        : CupertinoColors.placeholderText.resolveFrom(context);

    return GestureDetector(
      onTap: enabled ? () => _showPicker(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: CupertinoColors.systemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  color: labelColor,
                  size: 18,
                ),
                child: icon,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.textStyle.copyWith(color: labelColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_up_chevron_down,
              size: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final cancelLabel = CupertinoLocalizations.of(context).cancelButtonLabel;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) => CupertinoActionSheet(
        actions: items.map((item) {
          final isSelected = item == selectedValue;
          final itemIcon = iconOf != null ? iconOf!(item) : null;

          return CupertinoActionSheetAction(
            isDefaultAction: isSelected,
            onPressed: () {
              Navigator.of(modalContext).pop();
              onChanged?.call(item);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (itemIcon != null) ...[
                  IconTheme(
                    data: const IconThemeData(size: 18),
                    child: itemIcon,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(labelOf(item)),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(modalContext).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
  }
}
