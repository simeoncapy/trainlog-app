import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:trainlog_app/utils/date_utils.dart';

class TripsFilterResult {
  final String keyword;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? country;
  final String? operatorName;
  final List<VehicleType> types; // or your enum

  TripsFilterResult({
    required this.keyword,
    this.startDate,
    this.endDate,
    this.country,
    this.operatorName,
    required this.types,
  });
}

class TripsFilterDialog extends StatefulWidget {
  final List<String> operatorOptions;
  final List<String> countryOptions;

  const TripsFilterDialog({
    super.key,
    required this.operatorOptions,
    required this.countryOptions,
  });

  @override
  State<TripsFilterDialog> createState() => _TripsFilterDialogState();
}

class _TripsFilterDialogState extends State<TripsFilterDialog> {
  final TextEditingController _keywordController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  late String _allCountryLabel;
  late String _allOperatorLabel;
  String? _selectedCountry = 'All';
  String? _selectedOperator = 'All';
  final List<VehicleType> _selectedTypes = [];
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context)!;

    _allCountryLabel = localizations.tripsFilterAllCountry;
    _allOperatorLabel = localizations.tripsFilterAllOperator;

    // If already selected was "All", update to localised version
    if (_selectedCountry == null || _selectedCountry == 'All') {
      _selectedCountry = _allCountryLabel;
    }
    if (_selectedOperator == null || _selectedOperator == 'All') {
      _selectedOperator = _allOperatorLabel;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate ?? now));
    final firstDate = isStart
        ? DateTime(1900)
        : _startDate ?? DateTime(1900);
    final lastDate = DateTime(2200);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        //final formatted = '${picked.year}/${picked.month}/${picked.day}';
        final formatted = formatDateTime(context, picked, hasTime: false);


        if (isStart) {
          _startDate = picked;
          _startDateController.text = formatted;

          // Optional: clear end date if now earlier than new start
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = formatted;
        }
      });
    }
  }


  void _toggleType(VehicleType type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> countryOptions = [_allCountryLabel, ...widget.countryOptions];
    final List<String> operatorOptions = [_allOperatorLabel, ...widget.operatorOptions];
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Keyword
              TextField(
                controller: _keywordController,
                decoration: InputDecoration(
                  labelText: localizations.tripsFilterKeyword,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            labelText: localizations.tripsFilterDateFrom,
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _endDateController,
                          decoration: InputDecoration(
                            labelText: localizations.tripsFilterDateTo,
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () async {
                      _startDate = null;
                      _endDate = null;
                      _startDateController.clear();
                      _endDateController.clear();
                    },
                    icon: const Icon(Icons.event_busy),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Country dropdown (searchable)
              DropdownSearch<String>(
                items: countryOptions,
                selectedItem: _selectedCountry,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: localizations.tripsFilterCountry,
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (value) => setState(() => _selectedCountry = value),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isSelected) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontWeight: item == _allCountryLabel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Operator dropdown
              DropdownSearch<String>(
                items: operatorOptions,
                selectedItem: _selectedOperator,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: localizations.tripsFilterOperator,
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (value) => setState(() => _selectedOperator = value),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isSelected) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontWeight: item == _allOperatorLabel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type section
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(localizations.tripsFilterType, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Example types — you can replace this
                  ChoiceChip(
                    label: const Text('Train'),
                    selected: _selectedTypes.contains(VehicleType.train),
                    onSelected: (_) => _toggleType(VehicleType.train),
                  ),
                  ChoiceChip(
                    label: const Text('Bus'),
                    selected: _selectedTypes.contains(VehicleType.bus),
                    onSelected: (_) => _toggleType(VehicleType.bus),
                  ),
                  // Add your own chips here
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(), // Cancel
                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        TripsFilterResult(
                          keyword: _keywordController.text.trim(),
                          startDate: _startDate,
                          endDate: _endDate,
                          country: _selectedCountry,
                          operatorName: _selectedOperator,
                          types: _selectedTypes,
                        ),
                      );
                    },
                    child: Text(MaterialLocalizations.of(context).searchFieldLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
