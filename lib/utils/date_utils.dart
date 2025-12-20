import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';

enum DateType {
  precise,
  unknown,
  date
}

// String formatDateTime(BuildContext context, DateTime dateTime, {bool hasTime = true}) {
//   final locale = Localizations.localeOf(context);
//   // Example: show both date and time in a typical way
//   final formatter = DateFormat.yMd(
//     locale.languageCode == 'en' ? 'en_GB' : locale.toString(),
//   );

//   if (hasTime) formatter.add_Hm(); // 24h format

//   return formatter.format(dateTime);
// }

String formatDateTime(
  BuildContext context,
  DateTime dateTime, {
  bool hasTime = true,
  bool timeOnly = false,
}) {
  final locale = Localizations.localeOf(context);
  final settings = context.read<SettingsProvider>();

  final timeFormat12h = settings.hourFormat12;
  final showTime = timeOnly || hasTime;

  // Decide base pattern
  final basePattern = timeOnly ? '' : settings.dateFormat;

  final formatter = DateFormat(
    basePattern,
    locale.languageCode == 'en' ? 'en_GB' : locale.toString(),
  );

  if (showTime) {
    if (timeFormat12h) {
      formatter.addPattern('h:mma');
    } else {
      formatter.add_Hm();
    }
  }

  var result = formatter.format(dateTime);

  if (showTime && timeFormat12h) {
    result = result
        .replaceAll(RegExp(r'AM', caseSensitive: false), 'a')
        .replaceAll(RegExp(r'PM', caseSensitive: false), 'p')
        .replaceAll(RegExp(r'a\.m\.', caseSensitive: false), 'a')
        .replaceAll(RegExp(r'p\.m\.', caseSensitive: false), 'p');
  }

  return result;
}

