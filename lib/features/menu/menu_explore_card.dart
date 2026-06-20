import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trainlog_app/navigation/nav_models.dart';

/// Data model for a card in the Explore grid.
class ExploreCardData {
  final AppPageId id;
  final IconData icon;
  final String label;
  final Color color;

  /// Optional subtitle: a coloured number and a plain text suffix.
  /// Pass [null] to hide the subtitle row.
  final ExploreCardSubtitle? subtitle;

  const ExploreCardData({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    this.subtitle,
  });
}

class ExploreCardSubtitle {
  final String number;
  final Color numberColor;
  final String text;

  const ExploreCardSubtitle({
    required this.number,
    required this.numberColor,
    required this.text,
  });
}

/// A card used in the 2×2 Explore grid on the full-screen menu.
///
/// All colours are read directly from [Theme.of(context).colorScheme]:
/// - background  → [ColorScheme.surface]
/// - border      → [ColorScheme.outline]
/// - arrow icon  → [ColorScheme.onSurfaceVariant]
/// - title text  → [ColorScheme.onSurface]
/// - subtitle secondary text → [ColorScheme.onSurfaceVariant]
class ExploreCard extends StatelessWidget {
  final ExploreCardData data;
  final VoidCallback onTap;

  const ExploreCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Solid-colour icon square + top-right arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
              ],
            ),
            // Flexible lets the title shrink on very small cards instead of
            // overflowing; up to 2 lines with ellipsis on truncation.
            Flexible(
              child: Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            // Optional coloured subtitle (hidden when null)
            if (data.subtitle != null) ...[
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: data.subtitle!.number,
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: data.subtitle!.numberColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' ${data.subtitle!.text}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
