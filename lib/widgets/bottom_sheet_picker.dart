import 'package:flutter/material.dart';

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
Future<void> showBottomSheetPicker<T>({
  required BuildContext context,
  required String title,
  required List<BottomSheetPickerOption<T>> options,
  required T selected,
  required ValueChanged<T> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
