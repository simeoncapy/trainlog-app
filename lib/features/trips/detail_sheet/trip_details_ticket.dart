import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Ticket section: a dashed-style card showing the ticket icon and the total
/// price using the trip's currency in ISO form (e.g. "1,450 JPY", "39.90 EUR").
/// The value itself is formatted through the localized number formatter so the
/// decimal separator matches the user's locale.
///
/// The fare-type label (e.g. "IC", "Sparpreis") is intentionally not rendered
/// here as the backing API for fare categories is not yet available.
class TripDetailsTicket extends StatefulWidget {
  final Trips trip;

  const TripDetailsTicket({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsTicket> createState() => _TripDetailsTicketState();
}

class _TripDetailsTicketState extends State<TripDetailsTicket> {
  Future<double?>? _convertedPriceFuture;
  late String _userCurrency;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    _userCurrency = settings.currency;

    final price = widget.trip.price;
    final currency = (widget.trip.currency ?? '').trim();

    if (price != null &&
        currency.isNotEmpty &&
        currency != _userCurrency) {
      _convertedPriceFuture = trainlog.convertCurrency(
        price,
        currency,
        widget.trip.purchasingDate ?? DateTime.now(),
        _userCurrency,
      );
    }
  }

  Widget _buildConvertedPrice() {
    return FutureBuilder<double?>(
      future: _convertedPriceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final convertedPrice = snapshot.data!;

        return Text(
          '(~ ${formatCurrency(
            context,
            convertedPrice,
            convertedPrice % 1 != 0,
          )} $_userCurrency)',
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.labelLarge?.fontSize,
            color: detailMutedColor(context),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.trip.price;
    if (price == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    final currency = (widget.trip.currency ?? '').trim();
    final amount = formatCurrency(context, price, price % 1 != 0);
    final priceLabel = currency.isEmpty ? amount : '$amount $currency';

    final purchased = widget.trip.purchasingDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripDetailsSectionHeader(l10n.tripsDetailsSectionTicket),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          priceLabel,
                          style: AppTheme.monoFont.copyWith(
                            fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          softWrap: true,
                        ),
                        _buildConvertedPrice(),
                      ],
                    ),
                    if (purchased != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.tripsDetailPurchasedDate(
                          formatDateTime(context, purchased, hasTime: false),
                        ),
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
                          color: detailMutedColor(context),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
