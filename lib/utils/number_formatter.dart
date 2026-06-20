import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

String formatCurrency(
  BuildContext context,
  double amount,
  bool showDecimal, {
  bool showSign = false,
}) {
  final locale = Localizations.localeOf(context).toString();
  final decimalDigits = showDecimal ? 2 : 0;

  final formatter = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimalDigits,
  );

  final formattedAmount = formatter.format(amount.abs());

  // Add + sign if needed
  if (showSign) {
    if (amount > 0) {
      return '+$formattedAmount';
    } else if (amount < 0) {
      return '-$formattedAmount';
    } else {
      return '0'; // No sign for zero
    }
  }

  // Default behavior: no + sign for positive
  return formatter.format(amount);
}

String formatNumber(BuildContext context, num value, {bool noDecimal = false}) {
  final locale = Localizations.localeOf(context).toString();
  final pattern = noDecimal ? "#,##0" : "#,##0.##"; // strip trailing zeros when decimals allowed
  final formatter = NumberFormat(pattern, locale);
  return formatter.format(value);
}

/// Formats a percentage [value] (already expressed in the 0–100 range) using the
/// locale's percent rules, including the space before `%` used by e.g. French.
///
/// Trailing zeros are stripped (`5 %`, `2,27 %` in fr / `5%`, `2.27%` in en).
String formatPercent(BuildContext context, num value, {int maxDecimals = 2}) {
  final locale = Localizations.localeOf(context).toString();
  final formatter = NumberFormat.percentPattern(locale)
    ..maximumFractionDigits = maxDecimals
    ..minimumFractionDigits = 0;
  // percentPattern multiplies by 100 internally, so undo the 0–100 scaling.
  return formatter.format(value / 100);
}

/// Formats [value] for compact, leaderboard-style display.
///
/// Values of one million or more are scaled and suffixed (`2.8M`, `1.3B`) with
/// [fractionDigits] decimals, while smaller values keep their full thousands
/// separators (`938,685`). The decimal separator follows the active locale.
String formatCompactNumber(
  BuildContext context,
  num value, {
  int fractionDigits = 1,
}) {
  final locale = Localizations.localeOf(context).toString();
  final abs = value.abs();

  String scaled(num scaledValue, String suffix) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: fractionDigits,
    );
    return '${formatter.format(scaledValue)}$suffix';
  }

  if (abs >= 1e9) return scaled(value / 1e9, 'B');
  if (abs >= 1e6) return scaled(value / 1e6, 'M');
  return NumberFormat('#,##0', locale).format(value);
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final RegExp _regExp = RegExp(r'^\d*([.,]\d*)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}