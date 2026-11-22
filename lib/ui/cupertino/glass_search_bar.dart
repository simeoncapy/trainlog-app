import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialLocalizations, Theme;
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// The iOS 26 search bar: liquid_glass_widgets' glass pill with its
/// search glyph and clear button, and a round glass ✕ beside it, always
/// shown, that closes the search. Typed in Hanken Grotesk, like the rest of the
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
    // The package shows its ✕ only while the field has focus; Apple's apps
    // keep it, so the bar draws its own, always there. The clear button
    // stays inside the field while there is text.
    return Row(
      children: [
        Expanded(
          child: lg.GlassSearchBar(
            controller: controller,
            focusNode: focusNode,
            placeholder: placeholder,
            showsCancelButton: false,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textStyle: body,
            placeholderStyle: body?.copyWith(
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
            useOwnLayer: true,
            quality: lg.GlassQuality.premium,
            height: height,
          ),
        ),
        const SizedBox(width: 10),
        GlassIconButton(
          icon: CupertinoIcons.xmark,
          size: height,
          tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
          onPressed: onCancel,
        ),
      ],
    );
  }
}
