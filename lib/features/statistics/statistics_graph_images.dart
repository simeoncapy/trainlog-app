import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/style_utils.dart';

/// Rows ranked with a number (1..10) before switching to text labels.
const _numberedRankCount = 10;

/// Icon for a vehicle selection; `null` (all modes) shows a stack.
Icon statisticsVehicleIcon(VehicleType? vehicle) => vehicle == null
    ? const Icon(Symbols.stacks, fill: 1)
    : VehicleType.iconOf(vehicle);

/// The images under the bars of the statistics graph, built from the
/// provider's data.
extension StatisticsGraphImages on StatisticsProvider {
  // -------------------------------------------------------------------
  // Graph images: same behavior as your current StatisticsPage
  // - operator: real logo via TrainlogProvider.getOperatorImage(...)
  // - country: flag emoji
  // - others: short text (first few chars), bold
  // -------------------------------------------------------------------
  List<Widget> graphImages(BuildContext context) {
    final keys = currentStats.keys.toList();
    return _barChartImageBuilder(context, graph, keys);
  }

  List<Widget> _barChartImageBuilder(
    BuildContext context,
    GraphType type,
    List<String> data,
  ) {
    // Convert "JP" -> "🇯🇵"
    String flagEmoji(String code) {
      String normalize(String c) {
        final cc = c.trim().toUpperCase();
        return (cc == 'UK') ? 'GB' : cc;
      }

      final cc = normalize(code);
      if (cc.length != 2) return '🏳️';
      const int base = 0x1F1E6; // Regional Indicator Symbol Letter A
      final int a = cc.codeUnitAt(0);
      final int b = cc.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCodes([base + (a - 65), base + (b - 65)]);
    }

    switch (type) {
      case GraphType.operator:
        return List.generate(
          data.length,
          (i) =>
              trainlog.getOperatorImage(data[i], maxWidth: 48, maxHeight: 48),
          // (i) => withOperatorLogoBg(
          //   context,
          //   trainlog.getOperatorImage(data[i], maxWidth: 48, maxHeight: 48),
          // ),
        );

      case GraphType.country:
        return List.generate(
          data.length,
          (i) => Text(flagEmoji(data[i]), style: const TextStyle(fontSize: 18)),
        );

      default:
        return List.generate(
          data.length,
          (i) => Text(
            StatisticsProvider.shortLabel(
              data[i],
              maxLen: StatisticsProvider.shortLabelSize,
            ),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  /// Build graph images for a given ordered list of keys (so it matches `stats.keys`).
  ///
  /// [otherLabel] — when a key equals this string, renders a vehicle-type icon
  /// in a coloured square (the "Other" bucket fallback).
  /// [barColor]   — the colour used for the "Other" square background.
  List<Widget> graphImagesForKeys(
    BuildContext context,
    List<String> keys, {
    String? otherLabel,
    Color barColor = Colors.blue,
  }) {
    // Convert "JP" -> "🇯🇵"
    String flagEmoji(String code) {
      String normalize(String c) {
        final cc = c.trim().toUpperCase();
        return (cc == 'UK') ? 'GB' : cc;
      }

      final cc = normalize(code);
      if (cc.length != 2) return '🏳️';
      const int base = 0x1F1E6;
      final int a = cc.codeUnitAt(0);
      final int b = cc.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCodes([base + (a - 65), base + (b - 65)]);
    }

    Widget otherWidget() {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: barColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(size: 16, color: barColor),
            child: statisticsVehicleIcon(vehicle),
          ),
        ),
      );
    }

    switch (graph) {
      case GraphType.operator:
        return List.generate(keys.length, (i) {
          final name = keys[i];
          if (otherLabel != null && name == otherLabel) return otherWidget();
          return withOperatorLogoBg(
            context,
            trainlog.getOperatorImage(name, maxWidth: 48, maxHeight: 48),
          );
        });

      case GraphType.country:
        return List.generate(keys.length, (i) {
          final name = keys[i];
          if (otherLabel != null && name == otherLabel) return otherWidget();
          return Text(flagEmoji(name), style: const TextStyle(fontSize: 18));
        });

      default:
        return List.generate(keys.length, (i) {
          final name = keys[i];
          if (otherLabel != null && name == otherLabel) return otherWidget();

          if (i < _numberedRankCount) {
            // Numbered indicator (1..10), styled like the ranking list.
            return Text(
              '${i + 1}',
              textAlign: TextAlign.center,
              style: AppTheme.monoFont.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            );
          }
          return Text(
            StatisticsProvider.shortLabel(
              name,
              maxLen: StatisticsProvider.shortLabelSize,
            ),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        });
    }
  }
}
