import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LogoBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> valuesTitles;
  final List<Widget> images;
  final String horizontalAxisTitle;
  final List<Color>? colors;
  final Color? color;
  final List<double>? strippedValues;

  const LogoBarChart({
    super.key,
    required this.values,
    required this.valuesTitles,
    required this.images,
    required this.horizontalAxisTitle,
    this.colors,
    this.color,
    this.strippedValues,
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
            BarChartRodStackItem(value, value+(shadowValue ?? 0.0), color.withValues(alpha: 0.5)),
          ]
        ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  // BarChartGroupData _makeGroup(int x, double value, Color color, double? shadowValue) {
  //   final radius = BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8));
  //   const double barWidth = 20;

  //   return BarChartGroupData(
  //     groupVertically: true,
  //     x: x,
  //     barRods: [
  //       BarChartRodData(
  //         toY: value, 
  //         color: color, 
  //         width: barWidth, 
  //         borderRadius: (shadowValue ?? 0.0) > 0.0 ? BorderRadius.zero : radius,
  //       ),
  //       if (shadowValue != null && shadowValue != 0.0)
  //         BarChartRodData(
  //           fromY: value, 
  //           toY: (shadowValue+value), 
  //           color: color.withValues(alpha: 0.5), 
  //           width: barWidth, 
  //           borderRadius: radius
  //         ),
  //     ],
  //     showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        //alignment: BarChartAlignment.spaceBetween,
        rotationQuarterTurns: 1,
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
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
          ),
        ),
      ),
    );
  }
}
