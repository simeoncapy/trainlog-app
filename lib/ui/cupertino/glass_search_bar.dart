import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// The iOS 26 search bar: liquid_glass_widgets' glass pill with its
/// search glyph, clear button and a round glass ✕ (cancel) that slides in
/// while the field has focus. Typed in Hanken Grotesk, like the rest of the
/// app.
class AppGlassSearchBar extends StatelessWidget {
  const AppGlassSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.onCancel,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final VoidCallback onCancel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Height of the bar.
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: CupertinoColors.label.resolveFrom(context),
      letterSpacing: 0,
    );
    return lg.GlassSearchBar(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      showsCancelButton: true,
      onCancel: onCancel,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textStyle: body,
      placeholderStyle: body?.copyWith(
        color: CupertinoColors.placeholderText.resolveFrom(context),
      ),
      useOwnLayer: true,
      quality: lg.GlassQuality.premium,
      height: height,
    );
  }
}
