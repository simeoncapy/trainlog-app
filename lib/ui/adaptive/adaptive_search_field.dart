import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/utils/platform_utils.dart';

/// Adaptive text-search input: liquid_glass_widgets' glass search bar on
/// Apple, a
/// Material [TextField] elsewhere.
class AdaptiveSearchField extends StatelessWidget {
  const AdaptiveSearchField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      final body = Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: CupertinoColors.label.resolveFrom(context),
        letterSpacing: 0,
      );
      return lg.GlassSearchBar(
        controller: controller,
        placeholder: placeholder,
        autofocus: autofocus,
        textStyle: body,
        placeholderStyle: body?.copyWith(
          color: CupertinoColors.placeholderText.resolveFrom(context),
        ),
        useOwnLayer: true,
      );
    }
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: controller.clear,
                ),
        ),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
