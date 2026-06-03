import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/app_colors.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';

/// Hero card at the top of the full-screen menu.
///
/// The background always uses [ColorScheme.inverseSurface] — navy in light
/// mode, pure white in dark mode — so it reads as a strong branded element
/// that inverts with the theme without any manual `isDark` checks.
class MenuSummaryCard extends StatelessWidget {
  const MenuSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<TrainlogProvider>();
    final trips = context.watch<TripsProvider>();

    return Container(
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _TrainlogIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: _CardText(
              username: auth.username ?? '',
              instanceUrl: auth.instanceUrl,
              trips: trips,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branded icon ──────────────────────────────────────────────────────────────

class _TrainlogIcon extends StatelessWidget {
  const _TrainlogIcon();

  @override
  Widget build(BuildContext context) {
    // Icon colours NEVER change regardless of theme:
    // amber outer circle → navy inner fill → amber icon glyph.
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.amber,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
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
  final String instanceUrl;
  final TripsProvider trips;

  const _CardText({
    required this.username,
    required this.instanceUrl,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // onInverseSurface is the correct readable colour on top of inverseSurface.
    final nameColor = cs.onInverseSurface;
    // Subdued secondary text: same hue, lower opacity.
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
        const SizedBox(height: 2),
        Text(
          instanceUrl,
          style: GoogleFonts.spaceMono(fontSize: 11, color: urlColor),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _TripCount(trips: trips),
      ],
    );
  }
}

class _TripCount extends StatefulWidget {
  final TripsProvider trips;

  const _TripCount({required this.trips});

  @override
  State<_TripCount> createState() => _TripCountState();
}

class _TripCountState extends State<_TripCount> {
  int? _count;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final c = await widget.trips.repository?.count();
    if (mounted) setState(() => _count = c);
  }

  @override
  Widget build(BuildContext context) {
    if (_count == null) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final subtleColor = cs.onInverseSurface.withOpacity(0.65);
    final monoBase = GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w600);

    return RichText(
      text: TextSpan(
        children: [
          // Only the number is amber.
          TextSpan(
            text: '$_count',
            style: monoBase.copyWith(color: AppColors.amber),
          ),
          TextSpan(
            text: ' ${loc.menuTripCountLabel}',
            style: monoBase.copyWith(color: subtleColor),
          ),
        ],
      ),
    );
  }
}
