import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  static Widget _cupertinoChild<T extends Object>(
    AdaptiveSegmentedButtonSegment<T> seg,
  ) {
    if (seg.icon != null && seg.label != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg.icon!,
            const SizedBox(width: 4),
            seg.label!,
          ],
        ),
      );
    }
    if (seg.icon != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: seg.icon!,
      );
    }
    if (seg.label != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: seg.label!,
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
