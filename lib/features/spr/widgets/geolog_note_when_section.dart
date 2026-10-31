import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/signed_int_formatter.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';

/// Date block of the Geolog note page: the date and time the Geolog stands
/// for (the recorded ones until changed), then an On time / Delayed selector
/// with the delay in minutes.
class GeologNoteWhenSection extends StatefulWidget {
  const GeologNoteWhenSection({
    super.key,
    required this.recordedDateTime,
    required this.dateTime,
    required this.delayMinutes,
    required this.onDateTimeChanged,
    required this.onDelayChanged,
  });

  /// When the Geolog was recorded.
  final DateTime recordedDateTime;

  /// The date and time set on the note; null keeps the recorded one.
  final DateTime? dateTime;

  final int? delayMinutes;

  final ValueChanged<DateTime?> onDateTimeChanged;
  final ValueChanged<int?> onDelayChanged;

  @override
  State<GeologNoteWhenSection> createState() => _GeologNoteWhenSectionState();
}

class _GeologNoteWhenSectionState extends State<GeologNoteWhenSection> {
  late bool _delayed = widget.delayMinutes != null;
  late final TextEditingController _delayCtl = TextEditingController(
    text: _signedText(widget.delayMinutes),
  );

  @override
  void dispose() {
    _delayCtl.dispose();
    super.dispose();
  }

  DateTime get _current => widget.dateTime ?? widget.recordedDateTime;

  static String _signedText(int? minutes) {
    if (minutes == null) return '';
    return minutes >= 0 ? '+$minutes' : '$minutes';
  }

  Future<void> _pickDate() async {
    final current = _current;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime(2500),
    );
    if (picked == null) return;
    widget.onDateTimeChanged(
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final current = _current;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    widget.onDateTimeChanged(
      DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  void _setDelayed(bool delayed) {
    setState(() {
      _delayed = delayed;
      if (!delayed) _delayCtl.clear();
    });
    if (!delayed) widget.onDelayChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final current = _current;
    final edited =
        widget.dateTime != null && widget.dateTime != widget.recordedDateTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFormCard(
          children: [
            TripFormValueTile(
              icon: Icons.calendar_today,
              label: loc.geologNoteDateLabel,
              hasValue: edited,
              value: Text(
                formatDateTime(context, current, hasTime: false),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _pickDate,
            ),
            TripFormValueTile(
              icon: Icons.access_time,
              label: loc.geologNoteTimeLabel,
              hasValue: edited,
              value: Text(
                formatDateTime(context, current, timeOnly: true),
                style: AppTheme.monoFont.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: _pickTime,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                loc.geologNoteRecordedAt(
                  formatDateTime(context, widget.recordedDateTime),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (edited)
              TextButton(
                onPressed: () => widget.onDateTimeChanged(null),
                child: Text(loc.geologNoteResetDateTime),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppStepsTabBar(
          tabs: [
            AppStepsTab(label: loc.addTripOnTime),
            AppStepsTab(label: loc.addTripDelayed),
          ],
          selectedIndex: _delayed ? 1 : 0,
          onTabChanged: (index) => _setDelayed(index == 1),
        ),
        if (_delayed) ...[const SizedBox(height: 12), _delayField(theme)],
      ],
    );
  }

  Widget _delayField(ThemeData theme) {
    final minutes = widget.delayMinutes;
    final isDark = theme.brightness == Brightness.dark;

    // Green for early, red for late; neutral otherwise.
    final Color delayColour;
    if (minutes == null || minutes == 0) {
      delayColour = theme.colorScheme.onSurface;
    } else if (minutes > 0) {
      delayColour = theme.colorScheme.error;
    } else {
      delayColour = isDark ? AppColors.successDark : AppColors.successLight;
    }

    return TextFormField(
      controller: _delayCtl,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: false,
        signed: true,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: delayColour,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: Text(
            'min',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: delayColour,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^[+-]?\d*$')),
        SignedIntFormatter(),
      ],
      onChanged: (value) => widget.onDelayChanged(int.tryParse(value)),
    );
  }
}
