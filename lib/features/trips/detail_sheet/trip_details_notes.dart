import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Optional notes section, rendered below the ticket. Shows a leading note icon
/// and the free-text note inside a filled, rounded container so long notes wrap
/// smoothly over multiple lines.
class TripDetailsNotes extends StatelessWidget {
  final Trips trip;

  const TripDetailsNotes({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final note = trip.notes?.trim();
    if (note == null || note.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final muted = detailMutedColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripDetailsSectionHeader(l10n.tripsDetailsSectionNotes),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: detailSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: detailBorderColor(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.sticky_note_2_outlined, size: 18, color: muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: muted,
                    height: 1.35,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
