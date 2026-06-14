import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/style_utils.dart';

/// The "DETAILS" metadata block: vehicle type (mandatory) plus the optional
/// material, seat and registration fields laid out in a responsive grid, and
/// the optional operator(s) section.
///
/// Every optional field is guarded so missing data simply omits its row
/// without leaving empty gaps.
class TripDetailsMetadata extends StatelessWidget {
  final Trips trip;

  const TripDetailsMetadata({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routeColor = tripRouteColor(context, trip);

    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    // Vehicle is mandatory; the rest are optional. Each field carries a small
    // leading icon shown before the value.
    final fields = <_Field>[
      _Field(
        l10n.tripsDetailsLabelVehicle,
        trip.type.label(context),
        icon: trip.type.icon().icon,
        iconColor: routeColor,
      ),
      if (clean(trip.materialType) != null)
        _Field(
          l10n.tripsDetailsLabelMaterial,
          trip.materialType!.trim(),
          icon: Icons.train_outlined,
        ),
      if (clean(trip.seat) != null)
        _Field(
          l10n.tripsDetailsLabelSeat,
          trip.seat!.trim(),
          icon: Icons.event_seat_outlined,
        ),
      if (clean(trip.reg) != null)
        _Field(
          l10n.tripsDetailsLabelRegistration,
          trip.reg!.trim(),
          icon: Icons.tag,
        ),
    ];

    final operators = trip.operatorName.isEmpty
        ? const <String>[]
        : trip.operatorName
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final countries = trip.countryDetails(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripDetailsSectionHeader(l10n.tripsDetailsSectionDetails),
        const SizedBox(height: 10),
        _FieldGrid(fields: fields),
        if (countries.isNotEmpty) ...[
          const SizedBox(height: 20),
          TripDetailsSectionHeader(l10n.tripsDetailsSectionCountry(countries.length)),
          const SizedBox(height: 10),
          _Countries(countries: countries),
        ],
        if (operators.isNotEmpty) ...[
          const SizedBox(height: 20),
          TripDetailsSectionHeader(l10n.tripsDetailsSectionOperator(operators.length)),
          const SizedBox(height: 10),
          _Operators(operators: operators),
        ],
      ],
    );
  }
}

/// Lists the trip's countries with a flag emoji and the localized name, laid
/// out in two responsive columns like the details grid (collapsing to one
/// column on narrow widths).
class _Countries extends StatelessWidget {
  final List<({String code, String emoji, String name})> countries;

  const _Countries({required this.countries});

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
          runSpacing: 12,
          children: [
            for (final c in countries)
              SizedBox(
                width: itemWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.name,
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
      },
    );
  }
}

class _Field {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  const _Field(this.label, this.value, {this.icon, this.iconColor});
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
            color: detailMutedColor(context),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (field.icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  field.icon,
                  size: 18,
                  color: field.iconColor ?? detailMutedColor(context),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                field.value,
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
