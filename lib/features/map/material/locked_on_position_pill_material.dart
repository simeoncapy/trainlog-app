import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// Android: a slowly blinking black pill anchored at the top of the map, shown while
/// the map follows the user's position. Returns a [Positioned]: put it
/// directly in the map's Stack.
class MaterialLockedOnPositionPill extends StatefulWidget {
  const MaterialLockedOnPositionPill({super.key});

  @override
  State<MaterialLockedOnPositionPill> createState() => _MaterialLockedOnPositionPillState();
}

class _MaterialLockedOnPositionPillState extends State<MaterialLockedOnPositionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.25,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                AppLocalizations.of(context)!.mapLockedOnPosition,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
