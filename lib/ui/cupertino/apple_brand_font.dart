import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Redraws its text in "Hanken Grotesk" inside Cupertino widgets that force
/// the system font (alert dialogs, action sheets): the app uses Hanken
/// Grotesk everywhere, iOS included.
///
/// Only the adaptive layer (dialogs, alerts, action sheets, popups) uses it,
/// so screens never need to.
///
/// Those widgets set their own [DefaultTextStyle] with San Francisco; this
/// keeps every other part of that style (size, weight, colour) and swaps only
/// the font, with its own letter spacing. Wrap the title, message and action
/// labels with it.
class AppleBrandFont extends StatelessWidget {
  const AppleBrandFont({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isApple) return child;
    final inherited = DefaultTextStyle.of(context);
    return DefaultTextStyle(
      style: GoogleFonts.hankenGrotesk(
        textStyle: inherited.style.copyWith(letterSpacing: 0),
      ),
      textAlign: inherited.textAlign,
      softWrap: inherited.softWrap,
      overflow: inherited.overflow,
      maxLines: inherited.maxLines,
      textWidthBasis: inherited.textWidthBasis,
      textHeightBehavior: inherited.textHeightBehavior,
      child: child,
    );
  }
}
