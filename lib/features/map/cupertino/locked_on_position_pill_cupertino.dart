import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// iOS: a Liquid Glass pill anchored at the top of the map, shown while the
/// map follows the user's position. The pill itself stays still (glass is
/// not drawn while partly transparent); only its location icon breathes.
/// Returns a [Positioned]: put it directly in the map's Stack.
class CupertinoLockedOnPositionPill extends StatefulWidget {
  const CupertinoLockedOnPositionPill({super.key});

  @override
  State<CupertinoLockedOnPositionPill> createState() =>
      _CupertinoLockedOnPositionPillState();
}

class _CupertinoLockedOnPositionPillState
    extends State<CupertinoLockedOnPositionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _curve = CurvedAnimation(
    parent: _breath,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = CupertinoTheme.of(context).primaryColor;
    final label = CupertinoColors.label.resolveFrom(context);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: LiquidGlass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.1).animate(_curve),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.45, end: 1).animate(_curve),
                    child: Icon(
                      CupertinoIcons.location_fill,
                      size: 15,
                      color: tint,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  AppLocalizations.of(context)!.mapLockedOnPosition,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: label,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
