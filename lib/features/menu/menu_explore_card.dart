import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

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

/// How an [ExploreCard] is drawn, per design: Material keeps its outlined
/// rounded card; the iOS view passes a borderless continuous-corner card.
class ExploreCardStyle {
  const ExploreCardStyle({this.radius = 14, this.bordered = true});

  final double radius;
  final bool bordered;
}

/// A compact card of the Explore grid on the full-screen menu: the coloured
/// icon square, the label and a chevron on one row, the optional subtitle
/// under the label.
///
/// Colours come from [Theme.of(context).colorScheme]: background
/// [ColorScheme.surface], border [ColorScheme.outline], chevron and
/// subtitle text [ColorScheme.onSurfaceVariant], label
/// [ColorScheme.onSurface].
class ExploreCard extends StatelessWidget {
  final ExploreCardData data;
  final VoidCallback onTap;
  final ExploreCardStyle style;

  const ExploreCard({
    super.key,
    required this.data,
    required this.onTap,
    this.style = const ExploreCardStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: cs.surface,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(style.radius),
            side: style.bordered
                ? BorderSide(color: cs.outline)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        textStyle: textTheme.bodyMedium,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.15,
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
                                textStyle: textTheme.labelSmall,
                                color: data.subtitle!.numberColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' ${data.subtitle!.text}',
                              style: GoogleFonts.hankenGrotesk(
                                textStyle: textTheme.labelSmall,
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
              Icon(
                AdaptiveIcons.chevronForward,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
