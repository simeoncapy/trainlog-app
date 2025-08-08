import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class LogoBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> valuesTitles;
  final List<Widget> images;
  final String horizontalAxisTitle;
  final List<Color>? colors;
  final Color? color;
  final List<double>? strippedValues;
  final int rotationQuarterTurns;

  const LogoBarChart({
    super.key,
    required this.values,
    required this.valuesTitles,
    required this.images,
    required this.horizontalAxisTitle,
    this.colors,
    this.color,
    this.strippedValues,
    this.rotationQuarterTurns = 0, // default not rotated
  }) : assert(values.length == valuesTitles.length &&
            valuesTitles.length == images.length &&
            (colors == null || images.length == colors.length) &&
            (strippedValues == null || strippedValues.length == values.length));

  @override
  State<LogoBarChart> createState() => _LogoBarChartState();
}

class _LogoBarChartState extends State<LogoBarChart> {
  int touchedGroupIndex = -1;
  late List<Color> _colors;
  late List<Tooltip> _images;
  late final List<GlobalKey<TooltipState>> _tooltipKeys;

  @override
  void initState() {
      super.initState();
      _tooltipKeys = List.generate(widget.values.length, (_) => GlobalKey<TooltipState>());

      _colors = widget.colors ?? List.generate(widget.values.length, (i) => (widget.color ?? Colors.blue));
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
          color: Colors.white,
          rodStackItems: [
            BarChartRodStackItem(0, value, color),
            BarChartRodStackItem(value, value+(shadowValue ?? 0.0), _lighten(color)),
          ]
        ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        //alignment: BarChartAlignment.spaceBetween,
        rotationQuarterTurns: widget.rotationQuarterTurns,
        barGroups: List.generate(
            widget.values.length,
            (i) => _makeGroup(
              i,
              widget.values[i],
              _colors[i],
              widget.strippedValues != null ? widget.strippedValues![i] : null,
            ),
          ),
        titlesData: FlTitlesData( // Because the graph is rotated the axis doesn't fit their real position
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // RIGHT TITLE
          rightTitles: AxisTitles( // BOTTOM TITLE
            axisNameWidget: Text(widget.horizontalAxisTitle), // Unit of the graph
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
            //direction: TooltipDirection.bottom,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Reused lookups
              final title = widget.valuesTitles[groupIndex];
              final axisTitle = widget.horizontalAxisTitle;
              final stack = rod.rodStackItems;

              // Colors
              final color = rod.gradient?.colors.first ?? rod.color;
              final pastTripColor = _colors[groupIndex];
              final futureTripColor = _lighten(pastTripColor);

              // Values with bounds checks
              final pastTrip = stack.isNotEmpty ? stack[0].toY : 0.0;
              final futureTrip = stack.length > 1 ? (stack[1].toY - pastTrip) : 0.0;

              final textStyle = TextStyle(
                color: color,
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
              final past        = TextSpan(text: "${AppLocalizations.of(context)!.yearPastList}: $pastTrip $axisTitle");
              final futureLegend= TextSpan(text: "\n⬤ ", style: TextStyle(color: futureTripColor));
              final future      = TextSpan(text: "${AppLocalizations.of(context)!.yearFutureList}: $futureTrip $axisTitle");

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
