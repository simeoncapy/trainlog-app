import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

String countryCodeToEmoji(String code) {
  return String.fromCharCodes(
    code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 65)),
  );
}

String countryCodeToName(String code, BuildContext context) {
  final details = CountryLocalizations.of(context);
  return code == "UN" ? AppLocalizations.of(context)!.internationalWaters
                      : details?.countryName(countryCode: code) ?? code;
}

String removeFlagPrefix(String s) {
  // Remove first 'grapheme cluster' (flag = 1 cluster) + following space
  // Example: "🇯🇵 Tokyo" → "Tokyo"
  final parts = s.trim().split(' ');
  if (parts.length <= 1) return s;
  return parts.sublist(1).join(' ');
}