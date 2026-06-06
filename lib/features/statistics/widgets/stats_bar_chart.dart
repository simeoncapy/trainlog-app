import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/features/statistics/widgets/logo_bar_chart.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Horizontal proportional bar chart.
///
/// The item with the maximum total (past + future) spans 100% of the
/// available track width; every other bar scales down proportionally.
/// Bars are stacked: solid colour for past trips, lighter tint for future.
///
/// Layout per row:
///   [icon]  Label name               value
///           [████████████░░░░░░░░░░░░░░░░░░]  ← bar below label+value
class StatsBarChart extends StatefulWidget {
  final Map<String, ({double past, double future})> stats;
  final List<Widget> images;
  final String Function(String key)? labelBuilder;
  final String baseUnit;
  final Map<UnitFactor, String>? unitsByFactor;
  final Color color;
  final List<Color>? colors;
  final InlineSpan? unitHelpTooltip;
  final String? otherLabel;

  const StatsBarChart({
    super.key,
    required this.stats,
    required this.images,
    required this.baseUnit,
    this.labelBuilder,
    this.unitsByFactor,
    this.color = Colors.blue,
    this.colors,
    this.unitHelpTooltip,
    this.otherLabel,
  }) : assert(
          images.length == stats.length,
          'images.length must match stats.length',
        );

  @override
  State<StatsBarChart> createState() => _StatsBarChartState();
}

class _StatsBarChartState extends State<StatsBarChart> {
  late List<String> _keys;
  late List<String> _titles;
  late List<double> _rawPast;
  late List<double> _rawFuture;
  late List<double> _scaledPast;
  late List<double> _scaledFuture;
  late UnitFactor _factor;
  late String _unitLabel;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant StatsBarChart old) {
    super.didUpdateWidget(old);
    _rebuild();
  }

  void _rebuild() {
    final entries = widget.stats.entries.toList();
    _keys = [for (final e in entries) e.key];
    _titles = [
      for (final e in entries) widget.labelBuilder?.call(e.key) ?? e.key,
    ];
    _rawPast = [for (final e in entries) e.value.past];
    _rawFuture = [for (final e in entries) e.value.future];
    _applyScale();
  }

  void _applyScale() {
    final unitsByFactor = {
      for (final f in UnitFactor.values) f: widget.baseUnit,
      ...?widget.unitsByFactor,
    };

    final maxTotal = _rawPast.isEmpty
        ? 0.0
        : Iterable.generate(_rawPast.length)
            .map((i) => _rawPast[i] + _rawFuture[i])
            .reduce(math.max);

    _factor = UnitFactor.base;
    for (final f in UnitFactor.values) {
      _factor = f;
      if (f.apply(maxTotal) < 1000) break;
    }

    _scaledPast = _rawPast.map(_factor.apply).toList(growable: false);
    _scaledFuture = _rawFuture.map(_factor.apply).toList(growable: false);
    _unitLabel = unitsByFactor[_factor]!;
  }

  Color _lighten(Color color, [double amount = 0.3]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) return const SizedBox.shrink();

    final n = widget.stats.length;
    final colors = widget.colors ?? List.generate(n, (_) => widget.color);

    final maxTotal = Iterable.generate(n)
        .map((i) => (_scaledPast[i] + _scaledFuture[i]).clamp(0.0, double.infinity))
        .fold(0.0, math.max);

    final monoStyle = AppTheme.monoFont.copyWith(
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );

    // Unit label widget — with optional long-press tooltip
    final unitWidget = widget.unitHelpTooltip != null
        ? Tooltip(
            triggerMode: TooltipTriggerMode.longPress,
            richMessage: TextSpan(children: [widget.unitHelpTooltip!]),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            waitDuration: Duration.zero,
            showDuration: const Duration(seconds: 4),
            child: Text(
              _unitLabel,
              style: monoStyle.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          )
        : Text(_unitLabel, style: monoStyle);

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: n,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final past = _scaledPast[i];
        final future = _scaledFuture[i];
        final total = past + future;
        final barFraction = maxTotal > 0 ? (total / maxTotal).clamp(0.0, 1.0) : 0.0;
        final pastFraction = total > 0 ? (past / total).clamp(0.0, 1.0) : 0.0;
        final color = colors[i];
        final futureColor = _lighten(color);

        final pastStr = formatNumber(context, past, noDecimal: past == past.truncateToDouble());
        final futureStr = formatNumber(context, future, noDecimal: future == future.truncateToDouble());
        final hasFuture = future > 0;

        return _BarRow(
          image: widget.images[i],
          label: _titles[i],
          barFraction: barFraction,
          pastFraction: pastFraction,
          pastColor: color,
          futureColor: futureColor,
          hasFuture: hasFuture,
          pastStr: pastStr,
          futureStr: futureStr,
          unitLabel: _unitLabel,
          unitWidget: unitWidget,
          monoStyle: monoStyle,
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  final Widget image;
  final String label;
  final double barFraction;
  final double pastFraction;
  final Color pastColor;
  final Color futureColor;
  final bool hasFuture;
  final String pastStr;
  final String futureStr;
  final String unitLabel;
  final Widget unitWidget;
  final TextStyle monoStyle;

  const _BarRow({
    required this.image,
    required this.label,
    required this.barFraction,
    required this.pastFraction,
    required this.pastColor,
    required this.futureColor,
    required this.hasFuture,
    required this.pastStr,
    required this.futureStr,
    required this.unitLabel,
    required this.unitWidget,
    required this.monoStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left icon (40 px wide, vertically centred with the text row)
        SizedBox(
          width: 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Center(child: image),
          ),
        ),
        const SizedBox(width: 8),
        // Right column: [label + value on same row] then bar below
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + value on same line
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Value: "5,420 km  + 30" or "5,420 km"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(pastStr, style: monoStyle),
                      const SizedBox(width: 4),
                      unitWidget,
                      if (hasFuture) ...[
                        const SizedBox(width: 6),
                        Text(
                          '+ $futureStr',
                          style: monoStyle.copyWith(
                            fontSize: 11,
                            color: monoStyle.color?.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Proportional bar track
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 7,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackW = constraints.maxWidth;
                      final barW = trackW * barFraction;
                      final pastW = barW * pastFraction;
                      final futureW = barW * (1 - pastFraction);
                      return Stack(
                        children: [
                          Container(width: trackW, color: trackColor),
                          Container(width: pastW, color: pastColor),
                          if (hasFuture)
                            Positioned(
                              left: pastW,
                              top: 0,
                              bottom: 0,
                              child: Container(width: futureW, color: futureColor),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
