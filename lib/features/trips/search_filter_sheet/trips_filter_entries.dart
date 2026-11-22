import 'package:flutter/widgets.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/filter_group_section.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_controller.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// The controller's countries as displayable entries (flag + localized
/// name), ordered by trip count. Shared by both views and the picker.
List<GroupEntry> countryEntries(
  BuildContext context,
  TripsFilterController filter,
) => [
  for (final c in filter.countryChoices)
    GroupEntry(
      value: c.value,
      // Context-aware rendering: translates codes CountryLocalizations
      // doesn't know (e.g. "UN" → international waters).
      label: countryCodeToName(c.value, context),
      leading: Text(
        countryCodeToEmoji(c.value),
        style: const TextStyle(fontSize: 18),
      ),
      tripCount: c.count,
    ),
];

/// The controller's operators as displayable entries (logo + name), ordered
/// by trip count.
List<GroupEntry> operatorEntries(
  BuildContext context,
  TripsFilterController filter,
  TrainlogProvider trainlog,
) => [
  for (final o in filter.operatorChoices)
    GroupEntry(
      value: o.value,
      label: o.value,
      leading: withOperatorLogoBg(
        context,
        trainlog.getOperatorImage(o.value, maxWidth: 32, maxHeight: 32),
      ),
      tripCount: o.count,
    ),
];
