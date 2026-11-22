import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// iOS: the graphical calendar of the compact date picker, in a popover
/// card. Tapping a day picks it and closes; tapping outside cancels.
Future<DateTime?> showGlassDatePopover(
  BuildContext context, {
  required DateTime initial,
  required DateTime minimum,
}) async {
  final locale = Localizations.localeOf(context).toString();
  final effectiveInitial = initial.isBefore(minimum) ? minimum : initial;
  // Flutter: 0 = Sunday; the picker: 7 = Sunday, 1 = Monday.
  final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final firstDayOfWeek = first == 0 ? 7 : first;
  final monthNames = [
    for (int m = 1; m <= 12; m++)
      _capitalize(DateFormat.MMMM(locale).format(DateTime(2024, m, 1))),
  ];
  // 2024-01-07 is a Sunday; shift to the first day of the week.
  final weekdayNames = [
    for (int i = 0; i < 7; i++)
      DateFormat.E(
        locale,
      ).format(DateTime(2024, 1, 7 + (first + i) % 7)).toUpperCase(),
  ];

  DateTime? picked;
  await showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x14000000),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: lg.GlassDatePicker(
            initialDateTime: effectiveInitial,
            minimumDate: minimum,
            maximumDate: DateTime(2200),
            tintColor: CupertinoTheme.of(context).primaryColor,
            firstDayOfWeek: firstDayOfWeek,
            monthNames: monthNames,
            weekdayNames: weekdayNames,
            surfaceStyle: lg.GlassSurfaceStyle.solid,
            // Fires only when a day is tapped: pick it and close, as the
            // iOS compact date picker does.
            onDateTimeChanged: (d) {
              picked = d;
              Navigator.of(ctx, rootNavigator: true).maybePop();
            },
          ),
        ),
      ),
    ),
  );
  return picked;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
