import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;


  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });



  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      // iOS 26 switch: wider track, and the thumb lifts into a Liquid Glass
      // lens while pressed or dragged. Disabled = dimmed and inert, as on iOS.
      final enabled = onChanged != null;
      return IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: lg.GlassSwitch(
            useOwnLayer: true,
            value: value,
            onChanged: onChanged ?? (_) {},
            activeColor: CupertinoColors.systemGreen.resolveFrom(context),
            width: 63,
            height: 28,
          ),
        ),
      );
    }

    return Switch(value: value, onChanged: onChanged);
  }
}
