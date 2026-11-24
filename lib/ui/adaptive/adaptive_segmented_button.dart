import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassSegment, GlassSegmentedControl;
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveSegmentedButtonSegment<T extends Object> {
  final T value;
  final Widget? label;
  final Widget? icon;

  const AdaptiveSegmentedButtonSegment({
    required this.value,
    this.label,
    this.icon,
  });
}

class AdaptiveSegmentedButton {
  static Widget build<T extends Object>({
    required BuildContext context,
    required List<AdaptiveSegmentedButtonSegment<T>> segments,
    required T selectedValue,
    required ValueChanged<T> onChanged,
    bool showSelectedIcon = true,
    ButtonStyle? style,
  }) {
    if (AppPlatform.isApple) {
      return _cupertino<T>(
        context: context,
        segments: segments,
        selectedValue: selectedValue,
        onChanged: onChanged,
      );
    }
    return _material<T>(
      context: context,
      segments: segments,
      selectedValue: selectedValue,
      onChanged: onChanged,
      showSelectedIcon: showSelectedIcon,
      style: style,
    );
  }

  static Widget _cupertino<T extends Object>({
    required BuildContext context,
    required List<AdaptiveSegmentedButtonSegment<T>> segments,
    required T selectedValue,
    required ValueChanged<T> onChanged,
  }) {
    // iOS 26: the Liquid Glass control, as on the app's other tab bars. It
    // takes plain strings, so it is used when every label is a plain Text;
    // anything richer falls back to the classic sliding control.
    final glass = _glassSegments(segments);
    if (glass != null) {
      final index = segments.indexWhere((s) => s.value == selectedValue);
      return GlassSegmentedControl(
        segments: glass,
        selectedIndex: index < 0 ? 0 : index,
        onSegmentSelected: (i) => onChanged(segments[i].value),
        height: 40,
        iconSize: 18,
      );
    }

    final children = <T, Widget>{
      for (final seg in segments) seg.value: _cupertinoChild(seg),
    };

    return CupertinoSlidingSegmentedControl<T>(
      children: children,
      groupValue: selectedValue,
      onValueChanged: (T? newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }

  /// Glass segments for [segments], or null when a label isn't a plain Text.
  /// A labelled segment shows its text only (iOS: text or icon, never both).
  static List<GlassSegment>? _glassSegments<T extends Object>(
    List<AdaptiveSegmentedButtonSegment<T>> segments,
  ) {
    final result = <GlassSegment>[];
    for (final seg in segments) {
      final label = seg.label;
      if (label != null) {
        if (label is! Text || label.data == null) return null;
        result.add(GlassSegment(label: label.data, semanticLabel: label.data));
      } else if (seg.icon != null) {
        result.add(GlassSegment(icon: seg.icon));
      } else {
        return null;
      }
    }
    return result;
  }

  static Widget _cupertinoChild<T extends Object>(
    AdaptiveSegmentedButtonSegment<T> seg,
  ) {
    // iOS guideline: a segment shows text OR an icon, never both. When a
    // segment has a label, the icon is dropped (Android keeps both).
    if (seg.label != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: seg.label!,
      );
    }
    if (seg.icon != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: seg.icon!,
      );
    }
    return const SizedBox.shrink();
  }

  static Widget _material<T extends Object>({
    required BuildContext context,
    required List<AdaptiveSegmentedButtonSegment<T>> segments,
    required T selectedValue,
    required ValueChanged<T> onChanged,
    bool showSelectedIcon = true,
    ButtonStyle? style,
  }) {
    return SegmentedButton<T>(
      segments: segments
          .map((seg) => ButtonSegment<T>(
                value: seg.value,
                label: seg.label,
                icon: seg.icon,
              ))
          .toList(),
      selected: {selectedValue},
      onSelectionChanged: (Set<T> newSelection) {
        onChanged(newSelection.first);
      },
      showSelectedIcon: showSelectedIcon,
      style: style,
    );
  }
}
