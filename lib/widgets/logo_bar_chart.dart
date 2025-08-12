import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

enum UnitFactor {
  base    (1,   ''),
  thousand(1e3, 'k'),
  million (1e6, 'M'),
  billion (1e9, 'G');

  const UnitFactor(this.multiplier, this.suffix);

  final double multiplier;
  final String suffix;

  double apply(double value) => value / multiplier;
}

class LogoBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> valuesTitles;
  final List<Widget> images;
  final String baseUnit;
  final Map<UnitFactor,String>? unitsByFactor;
  final List<Color>? colors;
  final Color? color;
  final List<double>? strippedValues;
  final int rotationQuarterTurns;
  final InlineSpan? unitHelpTooltip;

  const LogoBarChart({
    super.key,
    required this.values,
    required this.valuesTitles,
    required this.images,
    required this.baseUnit,
    this.unitsByFactor,
    this.colors,
    this.color,
    this.strippedValues,
    this.rotationQuarterTurns = 0, // default not rotated
    this.unitHelpTooltip,
  }) : assert(values.length == valuesTitles.length &&
            valuesTitles.length == images.length &&
            (colors == null || images.length == colors.length) &&
            (strippedValues == null || strippedValues.length == values.length));

  @override
  State<LogoBarChart> createState() => _LogoBarChartState();
}

class _LogoBarChartState extends State<LogoBarChart> {
  int touchedGroupIndex = -1;
  late List<Tooltip> _images;
  late final List<GlobalKey<TooltipState>> _tooltipKeys;
  late List<double> _valueScaleAdjusted;
  late List<double>? _strippedScaleAdjusted;
  late Map<UnitFactor,String> _unitsByFactor;
  UnitFactor _factor = UnitFactor.base;
  late String _unitLabel = widget.baseUnit;

  @override
  void initState() {
      super.initState();
      _tooltipKeys = List.generate(widget.values.length, (_) => GlobalKey<TooltipState>());

      _images = List.generate(
        widget.values.length,
        (i) => Tooltip(
          key: _tooltipKeys[i],
          message: widget.valuesTitles[i],
          waitDuration: Duration(milliseconds: 0),
          showDuration: Duration(seconds: 3),
          preferBelow: false,
          child: GestureDetector(
            onTap: () {
              final tooltip = _tooltipKeys[i].currentState;
              tooltip?.ensureTooltipVisible();
            },
            child: widget.images[i],
          ),
        )
      );

      _valueScaleAdjusted = widget.values;
      _strippedScaleAdjusted = widget.strippedValues;
      
      _adjustScale();
  }

  @override
  void didUpdateWidget(covariant LogoBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    _valueScaleAdjusted = widget.values;
    _strippedScaleAdjusted = widget.strippedValues;
    _adjustScale();
  }

  void _adjustScale()
  {
    _unitsByFactor = {
        for (final f in UnitFactor.values) f: widget.baseUnit, // defaults
        ...?widget.unitsByFactor, // override any provided entries
      };

    // 2) Choose a factor based on the largest absolute value (including shadows if any)
    final allVals = <double>[
      ...widget.values,
      if (widget.strippedValues != null) ...widget.strippedValues!,
    ];
    final maxAbs = allVals.isEmpty
        ? 0.0
        : allVals.map((v) => v.abs()).reduce(math.max);

    // Keep scaled numbers < 1000
    _factor = UnitFactor.base;
    for (final f in UnitFactor.values) {
      _factor = f;
      if (f.apply(maxAbs) < 1000) break;
    }

    // 3) Apply factor to lists
    _valueScaleAdjusted = widget.values.map(_factor.apply).toList(growable: false);
    _strippedScaleAdjusted =
        widget.strippedValues?.map(_factor.apply).toList(growable: false);

    // 4) Pick the label for the axis
    _unitLabel = _unitsByFactor[_factor]!;
  }

  Color _lighten(Color color, [double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  BarChartGroupData _makeGroup(int x, double value, Color color, double? shadowValue) {
    return BarChartGroupData(
      groupVertically: true,
      x: x,
      barRods: [
        BarChartRodData(
          toY: value+(shadowValue ?? 0.0), 
          width: 20,
          //color: Colors.white,
          rodStackItems: [
            BarChartRodStackItem(0, value, color),
            if((shadowValue ?? 0.0) > 0.0) BarChartRodStackItem(value, value+(shadowValue ?? 0.0), _lighten(color)),
          ]
        ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  Widget _horizontalAxisTitleBuilder()
  {
    if(widget.unitHelpTooltip == null) return Text(_unitLabel);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_unitLabel),
        const SizedBox(width: 8,),
        Tooltip(
          richMessage: TextSpan(children: [widget.unitHelpTooltip!]),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
          waitDuration: const Duration(milliseconds: 0),
          showDuration: const Duration(seconds: 3),
          preferBelow: false,
          child: Icon(Icons.help),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Color> colors = widget.colors ??
        List.generate(widget.values.length, (i) => widget.color ?? Colors.blue);

    return BarChart(
      BarChartData(
        //alignment: BarChartAlignment.spaceBetween,
        rotationQuarterTurns: widget.rotationQuarterTurns,
        barGroups: List.generate(
            widget.values.length,
            (i) => _makeGroup(
              i,
              _valueScaleAdjusted[i],
              colors[i],
              _strippedScaleAdjusted != null ? _strippedScaleAdjusted![i] : null,
            ),
          ),
        titlesData: FlTitlesData( // Because the graph is rotated the axis doesn't fit their real position
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // RIGHT TITLE
          rightTitles: AxisTitles( // BOTTOM TITLE
            axisNameWidget: _horizontalAxisTitleBuilder(), // Unit of the graph
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              )
            ),
          bottomTitles: AxisTitles( // LEFT TITLE
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: _images[value.toInt()],
                );
              },
            )
          )
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 200,
            // Auto should works for both, but I don't know why for the horizontal graph the tooltip is still going outside
            direction: widget.rotationQuarterTurns == 1 ? TooltipDirection.bottom : TooltipDirection.auto,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Reused lookups
              final title = widget.valuesTitles[groupIndex];
              final stack = rod.rodStackItems;

              // Colors
              final pastTripColor = colors[groupIndex];
              final futureTripColor = _lighten(pastTripColor);

              // Values with bounds checks
              final pastTrip = stack.isNotEmpty ? stack[0].toY : 0.0;
              final futureTrip = stack.length > 1 ? (stack[1].toY - pastTrip) : 0.0;

              final textStyle = TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              );

              final operator = TextSpan(
                text: "$title\n",
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 2.0,
                ),
              );

              final pastLegend  = TextSpan(text: "⬤ ", style: TextStyle(color: pastTripColor));
              final past        = TextSpan(text: "${AppLocalizations.of(context)!.yearPastList}: ${formatNumber(context, pastTrip)} $_unitLabel");
              final futureLegend= TextSpan(text: "\n⬤ ", style: TextStyle(color: futureTripColor));
              final future      = TextSpan(text: "${AppLocalizations.of(context)!.yearFutureList}: ${formatNumber(context, futureTrip)} $_unitLabel");

              final texts = <TextSpan>[
                operator,
                pastLegend,
                past,
                if (futureTrip > 0) ...[futureLegend, future],
              ];

              return BarTooltipItem(
                "",
                textStyle,
                textAlign: TextAlign.left,
                children: texts,
              );
            },
          ),
        ),
      ),
    );
  }
}
