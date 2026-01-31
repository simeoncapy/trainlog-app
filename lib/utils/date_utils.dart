import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:const_date_time/const_date_time.dart';

const unknownPast = ConstDateTime(0, 1, 1, 0, 0, 0);
const unknownFuture = ConstDateTime(9999, 1, 1, 0, 0, 0); // When reaching year 9999 please update to more future

enum DateType {
  precise, // preciseDates
  unknown,
  date // onlyDate
}

extension DateTypeExtension on DateType {
  String get apiName {
    switch (this) {
      case DateType.precise:
        return 'preciseDates';
      case DateType.unknown:
        return 'unknown';
      case DateType.date:
        return 'onlyDate';
    }
  }
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

String formatDurationFixed(Duration d) {
  final parts = <String>[];
  const nbsp = '\u00A0';

  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;

  if (days > 0) {
    parts.add('$days${nbsp}d');
  }
  if (hours > 0) {
    parts.add('$hours${nbsp}h');
  }
  if (minutes > 0) {
    parts.add('$minutes${nbsp}min');
  }
  if (seconds > 0) {
    parts.add('$seconds${nbsp}s');
  }

  // Fallback: show 0 min if duration is zero
  if (parts.isEmpty) {
    return '0${nbsp}min';
  }

  return parts.join(' ');
}

