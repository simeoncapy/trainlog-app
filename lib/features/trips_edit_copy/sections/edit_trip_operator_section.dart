import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/widgets/trip_form/dashed_outline_button.dart';
import 'package:trainlog_app/widgets/trip_form/operator_search_overlay.dart';
import 'package:trainlog_app/widgets/trip_form/operator_tiles.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Operator block of the edit form: the operators of the trip stacked as card
/// rows, each with a trailing cross removing it, and a dashed "+ Add operator"
/// action opening the app's operator search overlay.
class EditTripOperatorSection extends StatefulWidget {
  const EditTripOperatorSection({super.key});

  @override
  State<EditTripOperatorSection> createState() =>
      _EditTripOperatorSectionState();
}

class _EditTripOperatorSectionState extends State<EditTripOperatorSection> {
  late final OperatorSearchOverlay _searchOverlay = OperatorSearchOverlay(
    onSelected: _addOperator,
    onClosed: () {
      if (mounted) setState(() {});
    },
  );

  bool _operatorsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_operatorsLoaded) return;
    _operatorsLoaded = true;
    context.read<TrainlogProvider>().reloadOperatorList();
  }

  @override
  void dispose() {
    _searchOverlay.dispose();
    super.dispose();
  }

  void _addOperator(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final model = context.read<TripFormModel>();
    if (model.selectedOperators.contains(trimmed)) return;

    model.setOperators([...model.selectedOperators, trimmed]);
    model.clearOperatorError();
  }

  void _removeOperator(String name) {
    final model = context.read<TripFormModel>();
    model.setOperators(
        model.selectedOperators.where((op) => op != name).toList());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final operators = context.watch<TripFormModel>().selectedOperators;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (operators.isNotEmpty) ...[
          TripFormCard(
            children: [
              for (final op in operators)
                OperatorRow(
                  name: op,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () => _removeOperator(op),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        DashedOutlineButton(
          label: loc.editTripAddOperatorButton,
          onTap: () => _searchOverlay.open(context),
        ),
      ],
    );
  }
}
