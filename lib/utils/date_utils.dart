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
}) {
  final locale = Localizations.localeOf(context);
  final settings = context.read<SettingsProvider>();

  final pattern = settings.dateFormat;

  final formatter = DateFormat(pattern, locale.languageCode == 'en' ? 'en_GB' : locale.toString());

  if (hasTime) {
    formatter.add_Hm(); // 24h time
  }

  return formatter.format(dateTime);
}
