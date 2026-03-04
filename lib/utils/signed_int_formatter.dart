import 'package:flutter/services.dart';

class SignedIntFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow intermediate states while typing
    if (text.isEmpty || text == "+" || text == "-") return newValue;

    // Must match an optional sign + digits
    final m = RegExp(r'^[+-]?\d+$').firstMatch(text);
    if (m == null) return oldValue;

    final value = int.tryParse(text);
    if (value == null) return oldValue;

    final formatted = value >= 0 ? '+$value' : value.toString();

    // Try to keep cursor near the end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}