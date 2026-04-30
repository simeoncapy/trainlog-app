import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:trainlog_app/platform/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

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

/// Shows the trips filter adaptively: a Material [Dialog] on Android,
/// a Cupertino bottom sheet on iOS.
Future<TripsFilterResult?> showAdaptiveTripsFilterDialog(
  BuildContext context, {
  required List<String> operatorOptions,
  required Map<String, String> countryOptions,
  required List<VehicleType> typeOptions,
  TripsFilterResult? initialFilter,
}) async {
  if (AppPlatform.isApple) {
    return showCupertinoModalPopup<TripsFilterResult>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _CupertinoTripsFilter(
        operatorOptions: operatorOptions,
        countryOptions: countryOptions,
        typeOptions: typeOptions,
        initialFilter: initialFilter,
      ),
    );
  }
  return showDialog<TripsFilterResult>(
    context: context,
    builder: (_) => TripsFilterDialog(
      operatorOptions: operatorOptions,
      countryOptions: countryOptions,
      typeOptions: typeOptions,
      initialFilter: initialFilter,
    ),
  );
}

// ─── Material (unchanged) ─────────────────────────────────────────────────

class TripsFilterDialog extends StatefulWidget {
  final List<String> operatorOptions;
  final Map<String, String> countryOptions;
  final List<VehicleType> typeOptions;
  final TripsFilterResult? initialFilter;

  const TripsFilterDialog({
    super.key,
    required this.operatorOptions,
    required this.countryOptions,
    required this.typeOptions,
    this.initialFilter,
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
  late List<VehicleType> _selectedTypes;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      final f = widget.initialFilter!;
      _keywordController.text = f.keyword;
      _selectedCountry = f.country ?? 'All';
      _selectedOperator = f.operatorName ?? 'All';
      _selectedTypes = List.from(f.types);
      _startDate = f.startDate;
      _endDate = f.endDate;
      _startDateController.text = _startDate != null ? formatDateTime(context, _startDate!, hasTime: false) : '';
      _endDateController.text = _endDate != null ? formatDateTime(context, _endDate!, hasTime: false) : '';
    }
    else {
      _selectedTypes = List.from(widget.typeOptions);
    }

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context)!;

    _allCountryLabel = localizations.tripsFilterAllCountry;
    _allOperatorLabel = localizations.tripsFilterAllOperator;

    if (_selectedCountry == null || _selectedCountry == 'All') {
      _selectedCountry = '00'; // always use code internally
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


  @override
  Widget build(BuildContext context) {
    final Map<String, String> countryOptions = {
      '00': _allCountryLabel,
      ...widget.countryOptions,
    };
    final List<String> countryItems = countryOptions.keys.toList(); // country codes
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
                items: countryItems,
                selectedItem: _selectedCountry,
                dropdownBuilder: (context, selectedItem) {
                  final display = countryOptions[selectedItem] ?? selectedItem!;
                  return Text(display);
                },
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
                      item == '00'
                          ? countryOptions[item]!  // "All" label
                          : '${countryCodeToEmoji(item)} ${countryOptions[item] ?? item}',
                      style: TextStyle(
                        fontWeight: item == '00' ? FontWeight.bold : FontWeight.normal,
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
              VehicleTypeFilterChips(
                availableTypes: widget.typeOptions,
                selectedTypes: _selectedTypes.toSet(),
                onTypeToggle: (type, selected) {
                  setState(() {
                    selected ? _selectedTypes.add(type) : _selectedTypes.remove(type);
                  });
                },
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        TripsFilterResult(
                          keyword: _keywordController.text.trim(),
                          startDate: _startDate,
                          endDate: _endDate,
                          country: _selectedCountry == '00' ? null : _selectedCountry,
                          operatorName: _selectedOperator == _allOperatorLabel ? "All" : _selectedOperator,
                          types: _selectedTypes,
                        ),
                      );
                    },
                    label: Text(MaterialLocalizations.of(context).searchFieldLabel),
                    icon: Icon(Icons.search),
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

// ─── Cupertino ────────────────────────────────────────────────────────────

enum _FilterView { main, countryPicker, operatorPicker }

class _CupertinoTripsFilter extends StatefulWidget {
  final List<String> operatorOptions;
  final Map<String, String> countryOptions;
  final List<VehicleType> typeOptions;
  final TripsFilterResult? initialFilter;

  const _CupertinoTripsFilter({
    required this.operatorOptions,
    required this.countryOptions,
    required this.typeOptions,
    this.initialFilter,
  });

  @override
  State<_CupertinoTripsFilter> createState() => _CupertinoTripsFilterState();
}

class _CupertinoTripsFilterState extends State<_CupertinoTripsFilter> {
  final _keywordController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  late String _allCountryLabel;
  late String _allOperatorLabel;
  late String _selectedCountry; // '00' = all
  late String _selectedOperator;
  late List<VehicleType> _selectedTypes;

  _FilterView _view = _FilterView.main;
  final _pickerSearchController = TextEditingController();
  final _pickerScrollController = ScrollController();
  String _pickerQuery = '';

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    if (f != null) {
      _keywordController.text = f.keyword;
      _selectedCountry = f.country ?? '00';
      // Operator: store "All" sentinel; replaced in didChangeDependencies
      _selectedOperator = (f.operatorName == null || f.operatorName == 'All') ? '' : f.operatorName!;
      _selectedTypes = List.from(f.types);
      _startDate = f.startDate;
      _endDate = f.endDate;
    } else {
      _selectedCountry = '00';
      _selectedOperator = '';
      _selectedTypes = List.from(widget.typeOptions);
    }

    _pickerSearchController.addListener(() {
      setState(() => _pickerQuery = _pickerSearchController.text.toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _allCountryLabel = l10n.tripsFilterAllCountry;
    _allOperatorLabel = l10n.tripsFilterAllOperator;
    if (_selectedOperator.isEmpty) _selectedOperator = _allOperatorLabel;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _pickerSearchController.dispose();
    _pickerScrollController.dispose();
    super.dispose();
  }

  // ── Date picker ──────────────────────────────────────────────────────────

  Future<void> _selectDateCupertino(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    DateTime temp = initial;

    await showCupertinoModalPopup<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetCtx) => Container(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    onPressed: () => Navigator.of(sheetCtx, rootNavigator: true).pop(),
                  ),
                  CupertinoButton(
                    child: Text(MaterialLocalizations.of(context).okButtonLabel),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          if (isStart) {
                            _startDate = temp;
                            if (_endDate != null && _endDate!.isBefore(temp)) {
                              _endDate = null;
                            }
                          } else {
                            _endDate = temp;
                          }
                        });
                      }
                      Navigator.of(sheetCtx, rootNavigator: true).pop();
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initial,
                  minimumDate: isStart ? DateTime(1900) : (_startDate ?? DateTime(1900)),
                  maximumDate: DateTime(2200),
                  onDateTimeChanged: (dt) => temp = dt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _displayCountry() {
    if (_selectedCountry == '00') return _allCountryLabel;
    final name = widget.countryOptions[_selectedCountry] ?? _selectedCountry;
    return '${countryCodeToEmoji(_selectedCountry)} $name';
  }

  TripsFilterResult _buildResult() => TripsFilterResult(
        keyword: _keywordController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        country: _selectedCountry == '00' ? null : _selectedCountry,
        operatorName: _selectedOperator == _allOperatorLabel ? 'All' : _selectedOperator,
        types: _selectedTypes,
      );

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sheetBg = CupertinoColors.systemGroupedBackground.resolveFrom(context);

    return Container(
      height: mq.size.height * 0.92,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHandle(context),
            Expanded(
              child: _view == _FilterView.main
                  ? _buildMainView(context)
                  : _buildPickerView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey3.resolveFrom(context),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  // ── Main filter view ──────────────────────────────────────────────────────

  Widget _buildMainView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Column(
      children: [
        // Navigation-bar-style header
        Container(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                  style: TextStyle(color: primaryColor),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.filterButton,
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(_buildResult()),
                child: Text(
                  MaterialLocalizations.of(context).searchFieldLabel,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Keyword ──────────────────────────────────────────────
                _sectionLabel(context, l10n.tripsFilterKeyword.toUpperCase()),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: _keywordController,
                  placeholder: l10n.tripsFilterKeyword,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Icon(
                      CupertinoIcons.search,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      size: 18,
                    ),
                  ),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemFill.resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Date range ───────────────────────────────────────────
                _sectionLabel(context, '${l10n.tripsFilterDateFrom} / ${l10n.tripsFilterDateTo}'.toUpperCase()),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _dateTile(context, isStart: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _dateTile(context, isStart: false)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: CupertinoColors.destructiveRed.resolveFrom(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.calendar_badge_minus,
                          color: CupertinoColors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Country ──────────────────────────────────────────────
                _sectionLabel(context, l10n.tripsFilterCountry.toUpperCase()),
                const SizedBox(height: 6),
                _pickerTile(
                  context,
                  label: _displayCountry(),
                  onTap: () => setState(() {
                    _view = _FilterView.countryPicker;
                    _pickerSearchController.clear();
                    _pickerQuery = '';
                    if (_pickerScrollController.hasClients) {
                      _pickerScrollController.jumpTo(0);
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // ── Operator ─────────────────────────────────────────────
                _sectionLabel(context, l10n.tripsFilterOperator.toUpperCase()),
                const SizedBox(height: 6),
                _pickerTile(
                  context,
                  label: _selectedOperator,
                  onTap: () => setState(() {
                    _view = _FilterView.operatorPicker;
                    _pickerSearchController.clear();
                    if (_pickerScrollController.hasClients) {
                      _pickerScrollController.jumpTo(0);
                    }
                    _pickerQuery = '';
                  }),
                ),
                const SizedBox(height: 16),

                // ── Vehicle types ────────────────────────────────────────
                _sectionLabel(context, l10n.tripsFilterType.toUpperCase()),
                const SizedBox(height: 8),
                AdaptiveVehicleTypeFilterChips(
                  availableTypes: widget.typeOptions,
                  selectedTypes: _selectedTypes.toSet(),
                  onTypeToggle: (type, selected) {
                    setState(() {
                      selected
                          ? _selectedTypes.add(type)
                          : _selectedTypes.remove(type);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateTile(BuildContext context, {required bool isStart}) {
    final l10n = AppLocalizations.of(context)!;
    final date = isStart ? _startDate : _endDate;
    final label = isStart ? l10n.tripsFilterDateFrom : l10n.tripsFilterDateTo;
    final displayText =
        date != null ? formatDateTime(context, date, hasTime: false) : null;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    return GestureDetector(
      onTap: () => _selectDateCupertino(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: secondaryLabel, fontSize: 11),
                  ),
                  Text(
                    displayText ?? '—',
                    style: TextStyle(
                      color: displayText != null
                          ? CupertinoColors.label.resolveFrom(context)
                          : secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(BuildContext context, {required String label, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inline picker view ────────────────────────────────────────────────────

  Widget _buildPickerView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCountry = _view == _FilterView.countryPicker;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);

    // Build item list
    final Map<String, String> countryMap = {'00': _allCountryLabel, ...widget.countryOptions};
    final List<({String value, String display})> items = isCountry
        ? countryMap.entries.map((e) {
            final display = e.key == '00'
                ? e.value
                : '${countryCodeToEmoji(e.key)} ${e.value}';
            return (value: e.key, display: display);
          }).toList()
        : [_allOperatorLabel, ...widget.operatorOptions]
            .map((op) => (value: op, display: op))
            .toList();

    final filtered = _pickerQuery.isEmpty
        ? items
        : items
            .where((i) => i.display.toLowerCase().contains(_pickerQuery))
            .toList();

    void onSelect(String value) {
      setState(() {
        if (isCountry) {
          _selectedCountry = value;
        } else {
          _selectedOperator = value;
        }
        _view = _FilterView.main;
        _pickerSearchController.clear();
        _pickerQuery = '';
      });
    }

    final title = isCountry ? l10n.tripsFilterCountry : l10n.tripsFilterOperator;
    final currentValue = isCountry ? _selectedCountry : _selectedOperator;

    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: separatorColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                onPressed: () => setState(() {
                  _view = _FilterView.main;
                  _pickerSearchController.clear();
                  _pickerQuery = '';
                }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.chevron_left, color: primaryColor, size: 20),
                    const SizedBox(width: 2),
                    Text(
                      l10n.filterButton,
                      style: TextStyle(color: primaryColor),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
              ),
              // Mirror spacer so title is truly centred
              const SizedBox(width: 80),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: CupertinoSearchTextField(
            controller: _pickerSearchController,
            placeholder: MaterialLocalizations.of(context).searchFieldLabel,
          ),
        ),

        Container(height: 0.5, color: separatorColor),

        // List
        Expanded(
          child: CupertinoScrollbar(
            controller: _pickerScrollController,
            child: ListView.builder(
              controller: _pickerScrollController,
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final item = filtered[i];
                final isSelected = isCountry
                    ? item.value == currentValue
                    : item.value == currentValue;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(item.value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.display,
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 16,
                                  fontWeight: (item.value == '00' ||
                                          item.value == _allOperatorLabel)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(CupertinoIcons.checkmark,
                                  color: primaryColor, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (i < filtered.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Container(height: 0.5, color: separatorColor),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
        letterSpacing: 0.5,
      ),
    );
  }
}
