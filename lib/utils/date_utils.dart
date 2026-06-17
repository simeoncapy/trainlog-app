import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:const_date_time/const_date_time.dart';

const forceRefreshDate = ConstDateTime(1970, 1, 1, 0, 0, 0);
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

  return result.trim();
}

/// Formats [dateTime] as a short date with month name, e.g. "30 Mar" (English)
/// or the locale equivalent. English always uses British ordering (d MMM).
String formatDateShort(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context);
  final localeStr = locale.languageCode == 'en' ? 'en_GB' : locale.toString();
  return DateFormat.MMMd(localeStr).format(dateTime);
}

/// Formats a date range between [start] and [end] as a compact string.
/// Same day or date-only trips: "30 Mar" / "5月27日"
/// Same month: "15–18 Apr" / "5月15日–18日"
/// Cross-month: "30 Mar–2 Apr" / "3月30日–4月2日"
/// English always uses British date ordering; other locales use their own.
String formatDateRange(BuildContext context, DateTime start, DateTime end) {
  final locale = Localizations.localeOf(context);
  final localeStr = locale.languageCode == 'en' ? 'en_GB' : locale.toString();

  final isSameDay = start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;

  if (isSameDay) {
    return DateFormat.MMMd(localeStr).format(start);
  }

  return '${DateFormat.MMMd(localeStr).format(start)}–'
      '${DateFormat.MMMd(localeStr).format(end)}';
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
  if (seconds > 0 && d.inHours < 1) { // Only show seconds for durations less than 1 hour
    parts.add('$seconds${nbsp}s');
  }

  // Fallback: show 0 min if duration is zero
  if (parts.isEmpty) {
    return '0${nbsp}min';
  }

  return parts.join(' ');
}

String formatSecondsToHMS(int totalSeconds, {bool withSeconds = false, bool hourEvenIfZero = false}) {
  int days = totalSeconds ~/ 86400; // 24 * 3600
  int remainingAfterDays = totalSeconds % 86400;

  int hours = remainingAfterDays ~/ 3600;
  int remainingSecondsAfterHours = remainingAfterDays % 3600;

  int minutes = remainingSecondsAfterHours ~/ 60;
  int seconds = remainingSecondsAfterHours % 60;

  String result = "";

  if (days > 0) {
    result += "$days d ";
  }

  if (hours != 0 || hourEvenIfZero || days > 0) {
    result += "${hours.toString().padLeft(2, '0')} h ";
  }

  result += "${minutes.toString().padLeft(2, '0')} min";

  if (withSeconds) {
    result += " ${seconds.toString().padLeft(2, '0')} s";
  }

  return result;
}

