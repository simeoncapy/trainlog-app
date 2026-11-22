import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';

/// iOS section chip, matching the segmented controls: the
/// active section sits on the white, amber-rimmed thumb, the others on a
/// quiet system fill.
class CupertinoSectionChip extends StatelessWidget {
  const CupertinoSectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const duration = Duration(milliseconds: 200);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? AppColors.amber.withValues(alpha: isDark ? 0.45 : 0.40)
                      : Colors.transparent,
                  width: 0.8,
                ),
              ),
              color: selected
                  ? (isDark ? const Color(0xFF3A4255) : CupertinoColors.white)
                  : CupertinoColors.tertiarySystemFill.resolveFrom(context),
              shadows: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.30 : 0.10,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                color: selected
                    ? CupertinoColors.label.resolveFrom(context)
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
