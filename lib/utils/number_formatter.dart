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