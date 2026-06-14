import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/style_utils.dart';

/// The "DETAILS" metadata block: vehicle type (mandatory) plus the optional
/// material, seat and registration fields laid out in a responsive grid, the
/// optional operator(s) section and the optional notes.
///
/// Every optional field is guarded so missing data simply omits its row
/// without leaving empty gaps.
class TripDetailsMetadata extends StatelessWidget {
  final Trips trip;

  const TripDetailsMetadata({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    // Vehicle is mandatory; the rest are optional.
    final fields = <_Field>[
      _Field(l10n.tripsDetailsLabelVehicle, trip.type.label(context)),
      if (clean(trip.materialType) != null)
        _Field(l10n.tripsDetailsLabelMaterial, trip.materialType!.trim()),
      if (clean(trip.seat) != null)
        _Field(l10n.tripsDetailsLabelSeat, trip.seat!.trim()),
      if (clean(trip.reg) != null)
        _Field(l10n.tripsDetailsLabelRegistration, trip.reg!.trim()),
    ];

    final operators = trip.operatorName.isEmpty
        ? const <String>[]
        : trip.operatorName
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final notes = clean(trip.notes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripDetailsSectionHeader(l10n.tripsDetailsSectionDetails),
        const SizedBox(height: 10),
        _FieldGrid(fields: fields),

        if (operators.isNotEmpty) ...[
          const SizedBox(height: 20),
          TripDetailsSectionHeader(l10n.tripsDetailsSectionOperator(operators.length)),
          const SizedBox(height: 10),
          _Operators(operators: operators),
        ],

        if (notes != null) ...[
          const SizedBox(height: 20),
          TripDetailsSectionHeader(l10n.tripsDetailsSectionNotes),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdaptiveThemeColor.surfaceVariant(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              notes,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AdaptiveThemeColor.onSurfaceVariant(context),
                height: 1.35,
              ),
              softWrap: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _Field {
  final String label;
  final String value;
  const _Field(this.label, this.value);
}

/// Lays out the [fields] in two columns, collapsing to a single column on
/// narrow widths so long values never overflow.
class _FieldGrid extends StatelessWidget {
  final List<_Field> fields;

  const _FieldGrid({required this.fields});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: [
            for (final f in fields)
              SizedBox(
                width: itemWidth,
                child: _FieldTile(field: f),
              ),
          ],
        );
      },
    );
  }
}

class _FieldTile extends StatelessWidget {
  final _Field field;

  const _FieldTile({required this.field});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AdaptiveThemeColor.onSurfaceVariant(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          field.value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}

class _Operators extends StatelessWidget {
  final List<String> operators;

  const _Operators({required this.operators});

  @override
  Widget build(BuildContext context) {
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final logos = trainlog.getOperatorImages(
      operators.join(','),
      maxWidth: 40,
      maxHeight: 40,
      separator: ',',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < operators.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == operators.length - 1 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (i < logos.length)
                  withOperatorLogoBg(
                    context,
                    SizedBox(width: 40, height: 40, child: logos[i]),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    operators[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
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
