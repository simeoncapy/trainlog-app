import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trainlog_app/app/app_colors.dart';
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
/// Visual spec:
/// - White (light) / dark-surface (dark) background
/// - Thin border using the theme line colour
/// - Top-right chevron arrow
/// - Solid-colour rounded-square icon with a white [icon]
/// - [label] in Space Mono bold
/// - Optional coloured [subtitle] number + plain text (Space Mono)
class ExploreCard extends StatelessWidget {
  final ExploreCardData data;
  final VoidCallback onTap;

  const ExploreCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightBg;
    final borderColor = isDark ? AppColors.darkLine : AppColors.lightLine;
    final chevronColor = isDark ? AppColors.darkText3 : AppColors.lightText3;
    final subtitleTextColor = isDark ? AppColors.darkText2 : AppColors.lightText2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + top-right arrow
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
                Icon(Icons.arrow_outward, size: 16, color: chevronColor),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              data.label,
              style: GoogleFonts.spaceMono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            // Subtitle (hidden when null)
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
                        color: subtitleTextColor,
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
