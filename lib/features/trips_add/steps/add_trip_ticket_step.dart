import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/settings/settings_vm.dart';
import 'package:trainlog_app/features/trips_add/widgets/choice_card_selector.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/trip_form/currency_button.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

/// Step 6 of the "Add Trip" wizard: ticket, energy and visibility.
///
/// A "Ticket & extras" headline followed by three sections: the ticket card
/// (price with a currency picker button as its trailing, and the purchase
/// date), then the energy and visibility selectors rendered as rows of
/// choice cards matching the vehicle type step. Business logic is the same
/// as the former TripFormDetails: currency defaults to the user's setting
/// and the initial visibility comes from the account settings.
class AddTripTicketStep extends StatefulWidget {
  const AddTripTicketStep({super.key});

  @override
  State<AddTripTicketStep> createState() => _AddTripTicketStepState();
}

class _AddTripTicketStepState extends State<AddTripTicketStep> {
  late String _currencyCode;
  DateTime? _selectedPurchaseDate;
  int? accountVisibility; // 0/1/2

  @override
  void initState() {
    super.initState();

    final model = context.read<TripFormModel>();
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();

    _currencyCode = model.currencyCode ?? settings.currency;
    model.currencyCode = _currencyCode;
    // The purchase date is optional — no default until the user picks one.
    _selectedPurchaseDate = model.purchaseDate;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCurrencies();
      final accountSettings = await trainlog.fetchAccountSettings();

      if (model.tripVisibility == null) {
        // If visibility is already set in the model (e.g. when editing an
        // existing trip), use it. Otherwise, initialise it based on account
        // settings.
        accountVisibility =
            accountSettings[SettingsVm.accountSettingsKeyVisibility] != null
                ? int.tryParse(
                    accountSettings[SettingsVm.accountSettingsKeyVisibility]!)
                : null;

        switch (accountVisibility) {
          case 0:
            model.setVisibility(TripVisibility.private, init: true);
            break;
          case 1:
            model.setVisibility(TripVisibility.friends, init: true);
            break;
          case 2:
            model.setVisibility(TripVisibility.public, init: true);
            break;
          default:
            model.setVisibility(TripVisibility.private, init: true);
        }
      }
    });
  }

  Future<void> _loadCurrencies() async {
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2500),
    );
    if (picked != null && picked != _selectedPurchaseDate) {
      setState(() => _selectedPurchaseDate = picked);
      model.purchaseDate = _selectedPurchaseDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripTicketExtrasTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // --- Ticket ---
          TripFormSectionLabel(
              '${loc.addTripTicketTitle} (${loc.addTripOptional})'),
          const SizedBox(height: 8),
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
                  _selectedPurchaseDate != null
                      ? formatDateTime(context, _selectedPurchaseDate!,
                          hasTime: false)
                      : loc.addTripDurationNotSet,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _selectedPurchaseDate != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: _selectedPurchaseDate == null
                    ? TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          setState(() => _selectedPurchaseDate = today);
                          model.purchaseDate = today;
                        },
                        child: Text(loc.addTripTodayButton),
                      )
                    : IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        color: theme.colorScheme.onSurfaceVariant,
                        onPressed: () {
                          setState(() => _selectedPurchaseDate = null);
                          model.purchaseDate = null;
                        },
                      ),
                onTap: () => _pickPurchaseDate(model),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Energy ---
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

          // --- Visibility ---
          TripFormSectionLabel(loc.visibility),
          const SizedBox(height: 8),
          ChoiceCardSelector<TripVisibility>(
            options: [
              for (final v in TripVisibility.values)
                ChoiceCardOption(
                  value: v,
                  icon: v.icon(),
                  label: v.label(loc),
                ),
            ],
            value: model.visibility,
            onChanged: model.setVisibility,
          ),
        ],
      ),
    );
  }
}
