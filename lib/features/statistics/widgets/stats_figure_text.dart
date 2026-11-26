import 'package:flutter/painting.dart';

import 'package:trainlog_app/ui/tokens/app_theme.dart';

final _figures = RegExp(r'[-–+]?\d[\d\s  .,]*\d|[-–+]?\d|–');

/// [value] with its figures in [mono] and the rest (units such as "trips",
/// "km", "h", "%") in the interface font: [mono]'s size and colour with
/// [AppTheme.bodyFont]'s family, unless [text] is given.
TextSpan statsFigureSpans(String value, {required TextStyle mono, TextStyle? text}) {
  final plain = text ??
      AppTheme.bodyFont.copyWith(
        fontSize: mono.fontSize,
        fontWeight: FontWeight.w400,
        color: mono.color,
        letterSpacing: 0,
      );
  final spans = <TextSpan>[];
  var start = 0;
  for (final m in _figures.allMatches(value)) {
    if (m.start > start) {
      spans.add(TextSpan(text: value.substring(start, m.start), style: plain));
    }
    spans.add(TextSpan(text: m.group(0), style: mono));
    start = m.end;
  }
  if (start < value.length) {
    spans.add(TextSpan(text: value.substring(start), style: plain));
  }
  return TextSpan(children: spans);
}
