import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/dropdown_radio_list.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

/// Adaptive map filter panel. Renders as a [Positioned] widget inside a [Stack].
class MapFilterWidget extends StatelessWidget {
  final VoidCallback onClose;

  const MapFilterWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return _CupertinoMapFilter(onClose: onClose);
    }
    return _MaterialMapFilter(onClose: onClose);
  }
}

// ─── Material ──────────────────────────────────────────────────────────────

class _MaterialMapFilter extends StatelessWidget {
  final VoidCallback onClose;

  const _MaterialMapFilter({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poly = context.watch<PolylineProvider>();
    final mediaQuery = MediaQuery.of(context);
    final maxHeight =
        (mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom) * 0.7;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.yearTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _buildYearFilter(context, l10n, poly),
                      const SizedBox(height: 16),
                      _buildVehicleTypeHeader(context, l10n, poly),
                      const SizedBox(height: 8),
                      VehicleTypeFilterChips(
                        availableTypes: poly.availableTypesWithoutPoi,
                        selectedTypes: poly.selectedTypes,
                        onTypeToggle: (type, selected) {
                          context.read<PolylineProvider>().toggleType(type, selected);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    label: Text(MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeHeader(
      BuildContext context, AppLocalizations l10n, PolylineProvider poly) {
    return Row(
      children: [
        Expanded(
          child: Text(l10n.typeTitle, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(
          onPressed: () =>
              context.read<PolylineProvider>().selectAllVehicleTypes(poly.availableTypesWithoutPoi),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(l10n.mapFilterVehicleTypeAllBtn),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => context
              .read<PolylineProvider>()
              .unselectAllVehicleTypes(poly.availableTypesWithoutPoi),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(l10n.mapFilterVehicleTypeNoneBtn),
        ),
      ],
    );
  }

  DropdownRadioList _buildYearFilter(
      BuildContext context, AppLocalizations l10n, PolylineProvider poly) {
    Widget yearButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () =>
                context.read<PolylineProvider>().selectAllYears(poly.availableYears),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.mapFilterYearsAllBtn),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.read<PolylineProvider>().unselectAllYears(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.mapFilterYearsNoneBtn),
          ),
        ],
      );
    }

    return DropdownRadioList(
      items: [
        MultiLevelItem(
          title: Text(l10n.yearAllList),
          selectedTitle: Text(l10n.yearAllList),
          subItems: const [],
        ),
        MultiLevelItem(
          title: Text(l10n.yearPastList),
          selectedTitle: Text(l10n.yearPastList),
          subItems: const [],
        ),
        MultiLevelItem(
          title: Text(l10n.yearFutureList),
          selectedTitle: Text(l10n.yearFutureList),
          subItems: const [],
        ),
        MultiLevelItem(
          title: Text(l10n.yearYearList),
          selectedTitle: Text(l10n.yearYearList),
          trailing: yearButtons(),
          subItems: poly.availableYears.map((e) => e.toString()).toList(),
        ),
      ],
      selectedTopIndex: poly.selectedYearFilterOption,
      selectedSubStates: {
        3: poly.availableYears.map((y) => poly.selectedYears.contains(y)).toList(),
      },
      onChanged: (top, sub) {
        context.read<PolylineProvider>().updateYearFilter(
              topIndex: top,
              years: poly.availableYears,
              subSelection: sub,
            );
      },
    );
  }
}

// ─── Cupertino ─────────────────────────────────────────────────────────────

class _CupertinoMapFilter extends StatelessWidget {
  final VoidCallback onClose;

  const _CupertinoMapFilter({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poly = context.watch<PolylineProvider>();
    final mediaQuery = MediaQuery.of(context);
    final maxHeight =
        (mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom) * 0.7;

    final Color sheetFill = CupertinoDynamicColor.withBrightness(
      color: const Color(0xE6F2F2F7),
      darkColor: const Color(0xE61C1C1E),
    ).resolveFrom(context);

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: sheetFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.separator
                      .resolveFrom(context)
                      .withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, l10n),
                  Container(
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(context, l10n.yearTitle.toUpperCase()),
                          const SizedBox(height: 6),
                          _buildCupertinoYearFilter(context, l10n, poly),
                          const SizedBox(height: 16),
                          _buildCupertinoVehicleTypeHeader(context, l10n, poly),
                          const SizedBox(height: 8),
                          AdaptiveVehicleTypeFilterChips(
                            availableTypes: poly.availableTypesWithoutPoi,
                            selectedTypes: poly.selectedTypes,
                            onTypeToggle: (type, selected) {
                              context.read<PolylineProvider>().toggleType(type, selected);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 2),
      child: Row(
        children: [
          Text(
            l10n.filterButton,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onClose,
            child: Text(
              CupertinoLocalizations.of(context).doneButtonLabel,
              style: TextStyle(
                color: CupertinoTheme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildCupertinoYearFilter(
      BuildContext context, AppLocalizations l10n, PolylineProvider poly) {
    final options = [
      (l10n.yearAllList, 0),
      (l10n.yearPastList, 1),
      (l10n.yearFutureList, 2),
      (l10n.yearYearList, 3),
    ];

    final tileBackground = CupertinoColors.secondarySystemFill.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: tileBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.asMap().entries.map((entry) {
              final idx = entry.key;
              final (label, value) = entry.value;
              final isSelected = poly.selectedYearFilterOption == value;
              final isLast = idx == options.length - 1;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.read<PolylineProvider>().updateYearFilter(
                            topIndex: value,
                            years: poly.availableYears,
                            subSelection: value == 3
                                ? poly.availableYears
                                    .map((y) => poly.selectedYears.contains(y))
                                    .toList()
                                : [],
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(color: labelColor, fontSize: 16),
                            ),
                          ),
                          if (isSelected)
                            Icon(CupertinoIcons.checkmark, color: primaryColor, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Container(height: 0.5, color: separatorColor),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        if (poly.selectedYearFilterOption == 3) ...[
          const SizedBox(height: 12),
          _buildCupertinoYearChips(context, l10n, poly),
        ],
      ],
    );
  }

  Widget _buildCupertinoYearChips(
      BuildContext context, AppLocalizations l10n, PolylineProvider poly) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionLabel(context, l10n.yearTitle.toUpperCase())),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minSize: 0,
              onPressed: () =>
                  context.read<PolylineProvider>().selectAllYears(poly.availableYears),
              child: Text(
                l10n.mapFilterYearsAllBtn,
                style: TextStyle(fontSize: 14, color: primaryColor),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minSize: 0,
              onPressed: () => context.read<PolylineProvider>().unselectAllYears(),
              child: Text(
                l10n.mapFilterYearsNoneBtn,
                style: TextStyle(fontSize: 14, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: poly.availableYears.map((year) {
            final selected = poly.selectedYears.contains(year);
            final bgColor = selected
                ? primaryColor
                : CupertinoColors.tertiarySystemFill.resolveFrom(context);
            final fgColor = selected
                ? CupertinoColors.white
                : CupertinoColors.secondaryLabel.resolveFrom(context);

            return GestureDetector(
              onTap: () {
                final newSub = poly.availableYears
                    .map((y) => y == year ? !selected : poly.selectedYears.contains(y))
                    .toList();
                context.read<PolylineProvider>().updateYearFilter(
                      topIndex: 3,
                      years: poly.availableYears,
                      subSelection: newSub,
                    );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  year.toString(),
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCupertinoVehicleTypeHeader(
      BuildContext context, AppLocalizations l10n, PolylineProvider poly) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Row(
      children: [
        Expanded(child: _sectionLabel(context, l10n.typeTitle.toUpperCase())),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minSize: 0,
          onPressed: () => context
              .read<PolylineProvider>()
              .selectAllVehicleTypes(poly.availableTypesWithoutPoi),
          child: Text(
            l10n.mapFilterVehicleTypeAllBtn,
            style: TextStyle(fontSize: 14, color: primaryColor),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minSize: 0,
          onPressed: () => context
              .read<PolylineProvider>()
              .unselectAllVehicleTypes(poly.availableTypesWithoutPoi),
          child: Text(
            l10n.mapFilterVehicleTypeNoneBtn,
            style: TextStyle(fontSize: 14, color: primaryColor),
          ),
        ),
      ],
    );
  }
}
