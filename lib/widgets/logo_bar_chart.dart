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
  /// label -> (past, future). Order respected (LinkedHashMap preferred).
  final Map<String, ({double past, double future})> stats;

  /// One icon/widget per row (must match stats length).
  final List<Widget> images;

  /// Optional: map a key to a display title (e.g., country code -> localized name).
  final String Function(String key)? labelBuilder;

  final String baseUnit;
  final Map<UnitFactor, String>? unitsByFactor;

  final List<Color>? colors;   // per-row overrides
  final Color? color;          // single fallback color

  final int rotationQuarterTurns;
  final InlineSpan? unitHelpTooltip;

  const LogoBarChart({
    super.key,
    required this.stats,
    required this.images,
    required this.baseUnit,
    this.labelBuilder,
    this.unitsByFactor,
    this.colors,
    this.color,
    this.rotationQuarterTurns = 0,
    this.unitHelpTooltip,
  }) : assert(
         (colors == null || stats.length == colors.length) &&
         (images.length == stats.length),
         'colors/images length must match stats length'
       );

  @override
  State<LogoBarChart> createState() => _LogoBarChartState();
}

class _LogoBarChartState extends State<LogoBarChart> {
  int touchedGroupIndex = -1;

  late List<GlobalKey<TooltipState>> _tooltipKeys;
  late List<Tooltip> _images;

  late Map<UnitFactor, String> _unitsByFactor;
  UnitFactor _factor = UnitFactor.base;
  late String _unitLabel = widget.baseUnit;

  // Derived from stats (raw then scaled)
  late List<String> _titles;
  late List<double> _rawPast;
  late List<double> _rawFuture;
  late List<double> _pastScaled;
  late List<double> _futureScaled;

  @override
  void initState() {
    super.initState();
    _rebuildFromWidget();
  }

  @override
  void didUpdateWidget(covariant LogoBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildFromWidget();
  }

  void _rebuildFromWidget() {
    final entries = widget.stats.entries.toList(); // preserve order
    final n = entries.length;

    _titles = [
      for (final e in entries) widget.labelBuilder?.call(e.key) ?? e.key,
    ];

    _rawPast   = [for (final e in entries) e.value.past];
    _rawFuture = [for (final e in entries) e.value.future];

    _tooltipKeys = List.generate(n, (_) => GlobalKey<TooltipState>());
    _images = List.generate(
      n,
      (i) => Tooltip(
        key: _tooltipKeys[i],
        message: _titles[i],
        waitDuration: const Duration(milliseconds: 0),
        showDuration: const Duration(seconds: 3),
        preferBelow: false,
        child: GestureDetector(
          onTap: () => _tooltipKeys[i].currentState?.ensureTooltipVisible(),
          child: widget.images[i],
        ),
      ),
    );

    _pastScaled = _rawPast;
    _futureScaled = _rawFuture;

    _adjustScale();
  }

  void _adjustScale() {
    _unitsByFactor = {
      for (final f in UnitFactor.values) f: widget.baseUnit,
      ...?widget.unitsByFactor,
    };

    // Choose scale based on largest absolute (past + future stacked)
    final allVals = <double>[
      for (var i = 0; i < _rawPast.length; i++)
        (_rawPast[i].abs() + _rawFuture[i].abs()),
    ];
    final maxAbs = allVals.isEmpty ? 0.0 : allVals.reduce(math.max);

    _factor = UnitFactor.base;
    for (final f in UnitFactor.values) {
      _factor = f;
      if (f.apply(maxAbs) < 1000) break;
    }

    _pastScaled   = _rawPast.map(_factor.apply).toList(growable: false);
    _futureScaled = _rawFuture.map(_factor.apply).toList(growable: false);

    _unitLabel = _unitsByFactor[_factor]!;
  }

  Color _lighten(Color color, [double amount = 0.3]) {
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  BarChartGroupData _makeGroup(int x, double past, Color color, double future) {
    final total = past + (future);
    return BarChartGroupData(
      groupVertically: true,
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          width: 20,
          rodStackItems: [
            BarChartRodStackItem(0, past, color),
            if (future > 0) BarChartRodStackItem(past, total, _lighten(color)),
          ],
        ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  Widget _horizontalAxisTitleBuilder() {
    if (widget.unitHelpTooltip == null) return Text(_unitLabel);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_unitLabel),
        const SizedBox(width: 8),
        Tooltip(
          richMessage: TextSpan(children: [widget.unitHelpTooltip!]),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
          waitDuration: const Duration(milliseconds: 0),
          showDuration: const Duration(seconds: 3),
          preferBelow: false,
          child: const Icon(Icons.help),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.stats.length;
    final colors = widget.colors ??
        List.generate(n, (i) => widget.color ?? Colors.blue);

    return BarChart(
      BarChartData(
        rotationQuarterTurns: widget.rotationQuarterTurns,
        minY: 0,
        // Optional: add headroom to avoid cramped top
        maxY: _computeMaxY() * 1.1,
        barGroups: List.generate(
          n,
          (i) => _makeGroup(i, _pastScaled[i], colors[i], _futureScaled[i]),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            axisNameWidget: _horizontalAxisTitleBuilder(),
            axisNameSize: 20,
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _images.length) return const SizedBox.shrink();
                return SideTitleWidget(meta: meta, child: _images[i]);
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 200,
            direction: widget.rotationQuarterTurns == 1
                ? TooltipDirection.bottom
                : TooltipDirection.auto,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final title = _titles[groupIndex];
              final stack = rod.rodStackItems;

              final pastColor = colors[groupIndex];
              final futureColor = _lighten(pastColor);

              final past = stack.isNotEmpty ? stack[0].toY : 0.0;
              final future = stack.length > 1 ? (stack[1].toY - past) : 0.0;

              final style = const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);

              final operator = TextSpan(
                text: "$title\n",
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 2.0,
                ),
              );

              final pastLegend   = TextSpan(text: "⬤ ", style: TextStyle(color: pastColor));
              final pastText     = TextSpan(text:
                "${AppLocalizations.of(context)!.yearPastList}: ${formatNumber(context, past)} $_unitLabel");
              final futureLegend = TextSpan(text: "\n⬤ ", style: TextStyle(color: futureColor));
              final futureText   = TextSpan(text:
                "${AppLocalizations.of(context)!.yearFutureList}: ${formatNumber(context, future)} $_unitLabel");

              return BarTooltipItem(
                "",
                style,
                textAlign: TextAlign.left,
                children: [
                  operator,
                  pastLegend, pastText,
                  if (future > 0) ...[futureLegend, futureText],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _computeMaxY() {
    double maxY = 0;
    for (var i = 0; i < _pastScaled.length; i++) {
      final total = (_pastScaled[i].isFinite ? _pastScaled[i] : 0.0) +
                    (_futureScaled[i].isFinite ? _futureScaled[i] : 0.0);
      if (total > maxY) maxY = total;
    }
    return maxY <= 0 ? 1 : maxY;
  }
}
