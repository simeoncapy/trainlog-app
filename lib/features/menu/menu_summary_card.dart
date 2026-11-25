import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/menu/menu_controller.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Hero card at the top of the full-screen menu.
///
/// The background always uses [ColorScheme.inverseSurface] — navy in light
/// mode, pure white in dark mode — so it reads as a strong branded element
/// that inverts with the theme without any manual `isDark` checks.
/// The profile card at the top of the menu on Android: the Trainlog logo,
/// the user name, the server (unless it is trainlog.me), the trip count and
/// a button sharing the public profile.
class MenuSummaryCard extends StatelessWidget {
  const MenuSummaryCard({super.key, required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final menu = context.watch<AppMenuController>();
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TrainlogProfileIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: _CardText(
              username: menu.username,
              server: menu.customServer,
              tripCount: menu.tripCount,
            ),
          ),
          IconButton(
            onPressed: onShare,
            tooltip: loc.menuShareProfile,
            icon: Icon(AdaptiveIcons.share, color: cs.onInverseSurface),
          ),
        ],
      ),
    );
  }
}

/// The round Trainlog logo of the profile card: amber ring, navy disc.
class TrainlogProfileIcon extends StatelessWidget {
  const TrainlogProfileIcon({super.key, this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Icon colours NEVER change regardless of theme:
    // amber outer circle → navy inner fill → amber icon glyph.
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.amber,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size / 12),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(size * 2 / 15),
        child: SvgPicture.asset(
          'assets/icon/trainlog_icon_foreground_only.svg',
          colorFilter: const ColorFilter.mode(AppColors.amber, BlendMode.srcIn),
        ),
      ),
    );
  }
}

// ── Text content ──────────────────────────────────────────────────────────────

class _CardText extends StatelessWidget {
  final String username;
  final String? server;
  final int? tripCount;

  const _CardText({
    required this.username,
    required this.server,
    required this.tripCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nameColor = cs.onInverseSurface;
    final urlColor = cs.onInverseSurface.withOpacity(0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: TextStyle(
            color: nameColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (server != null) ...[
          const SizedBox(height: 2),
          Text(
            server!,
            style: GoogleFonts.spaceMono(fontSize: 11, color: urlColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (tripCount != null) ...[
          const SizedBox(height: 6),
          TripCountLine(count: tripCount!),
        ],
      ],
    );
  }
}

/// Displays a trip count as "[number] [localised label]" where the number is
/// amber and the label uses [cs.onInverseSurface] at 65 % opacity.
///
/// Designed to sit on an [ColorScheme.inverseSurface] background (navy on
/// light theme, white on dark theme).
class TripCountLine extends StatelessWidget {
  const TripCountLine({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final subtleColor = cs.onInverseSurface.withOpacity(0.65);
    final monoBase = GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w600);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$count',
            style: monoBase.copyWith(color: AppColors.amber),
          ),
          TextSpan(
            text: ' ${loc.menuTripCountLabel(count)}',
            style: monoBase.copyWith(color: subtleColor),
          ),
        ],
      ),
    );
  }
}
