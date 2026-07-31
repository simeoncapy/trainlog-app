import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/features/trips_add/widgets/choice_card_selector.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/trip_form/currency_button.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

/// Ticket block of the edit form, mirroring the add-trip ticket step: price
/// with its currency picker, purchase date, then the energy and visibility
/// choice cards.
class EditTripTicketSection extends StatefulWidget {
  const EditTripTicketSection({super.key});

  @override
  State<EditTripTicketSection> createState() => _EditTripTicketSectionState();
}

class _EditTripTicketSectionState extends State<EditTripTicketSection> {
  late String _currencyCode;
  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();

    final model = context.read<TripFormModel>();
    _currencyCode = model.currencyCode ?? context.read<SettingsProvider>().currency;
    model.currencyCode = _currencyCode;
    _purchaseDate = model.purchaseDate;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrencies());
  }

  Future<void> _loadCurrencies() async {
    final trainlog = context.read<TrainlogProvider>();
    if (trainlog.availableCurrencies.isEmpty) {
      await trainlog.reloadAvailableCurrencies();
    }
  }

  void _pickCurrency(TripFormModel model, TrainlogProvider trainlog) {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      currencyFilter: trainlog.availableCurrencies.isEmpty
          ? null
          : trainlog.availableCurrencies,
      onSelect: (currency) {
        setState(() => _currencyCode = currency.code);
        model.currencyCode = _currencyCode;
      },
    );
  }

  Future<void> _pickPurchaseDate(TripFormModel model) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2500),
    );
    if (picked == null || picked == _purchaseDate) return;

    setState(() => _purchaseDate = picked);
    model.purchaseDate = _purchaseDate;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();
    final trainlog = context.read<TrainlogProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFormCard(
          children: [
            TripFormValueTile(
              icon: Icons.sell_outlined,
              label: loc.addTripPrice,
              hasValue: model.price != null,
              value: TextFormField(
                initialValue: model.price?.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [DecimalTextInputFormatter()],
                style: AppTheme.monoFont.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    model.price = double.tryParse(value.replaceAll(',', '.'));
                  });
                },
              ),
              trailing: CurrencyButton(
                code: _currencyCode,
                onTap: () => _pickCurrency(model, trainlog),
              ),
            ),
            TripFormValueTile(
              icon: Icons.calendar_today,
              label: loc.addTripPurchaseDate,
              hasValue: model.purchaseDate != null,
              value: Text(
                _purchaseDate != null
                    ? formatDateTime(context, _purchaseDate!, hasTime: false)
                    : loc.addTripDurationNotSet,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _purchaseDate != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: _purchaseDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: () {
                        setState(() => _purchaseDate = null);
                        model.purchaseDate = null;
                      },
                    ),
              onTap: () => _pickPurchaseDate(model),
            ),
          ],
        ),
        const SizedBox(height: 20),

        TripFormSectionLabel(loc.energy),
        const SizedBox(height: 8),
        ChoiceCardSelector<EnergyType>(
          options: [
            ChoiceCardOption(
              value: EnergyType.auto,
              icon: Icons.auto_awesome,
              label: loc.auto,
            ),
            ChoiceCardOption(
              value: EnergyType.electric,
              icon: Icons.bolt,
              label: loc.energyElectric,
            ),
            ChoiceCardOption(
              value: EnergyType.thermic,
              icon: Icons.local_fire_department,
              label: loc.energyThermic,
            ),
          ],
          value: model.energyType,
          onChanged: model.setEnergyType,
        ),
        const SizedBox(height: 20),

        TripFormSectionLabel(loc.visibility),
        const SizedBox(height: 8),
        ChoiceCardSelector<TripVisibility>(
          options: [
            for (final v in TripVisibility.values)
              ChoiceCardOption(value: v, icon: v.icon(), label: v.label(loc)),
          ],
          value: model.visibility,
          onChanged: model.setVisibility,
        ),
      ],
    );
  }
}
