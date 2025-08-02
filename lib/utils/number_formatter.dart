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