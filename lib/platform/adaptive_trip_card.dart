import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/platform_utils.dart'; // for AppPlatform.isApple
import 'package:trainlog_app/widgets/trip_details_bottom_sheet.dart';

/// Call this everywhere.
Future<void> showAdaptiveTripBottomSheet(
  BuildContext context, {
  required Trips trip,
}) {
  if (AppPlatform.isApple) {
    return _showTripCardCupertino(context, trip: trip);
  }
  return _showTripSheetMaterial(context, trip: trip);
}

/// Material version (your current one).
Future<void> _showTripSheetMaterial(
  BuildContext context, {
  required Trips trip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final bottom = math.max(mq.viewPadding.bottom, mq.viewInsets.bottom);
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: TripDetailsBottomSheet(trip: trip),
      );
    },
  );
}

/// Cupertino "Apple Maps card" style.
Future<void> _showTripCardCupertino(
  BuildContext context, {
  required Trips trip,
}) {
  final sheetController = DraggableScrollableController();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .25),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final mq = MediaQuery.of(ctx);
      final bottomInset = math.max(mq.viewPadding.bottom, mq.viewInsets.bottom);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // absorb taps so they don't reach the backdrop
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: DraggableScrollableSheet(
                  controller: sheetController,
                  expand: false,
                  initialChildSize: 0.55,
                  minChildSize: 0.30,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return _CupertinoDraggableCard(
                      scrollController: scrollController,
                      sheetController: sheetController,
                      onDismiss: () => Navigator.of(ctx).pop(),
                      child: TripDetailsBottomSheet(trip: trip),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
        end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _CupertinoDraggableCard extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;
  final Widget child;
  final VoidCallback onDismiss;

  const _CupertinoDraggableCard({
    required this.scrollController,
    required this.sheetController,
    required this.child,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final Color sheetFill = CupertinoDynamicColor.withBrightness(
      // Light: iOS-like translucent system background
      color: const Color(0x99F2F2F7),     // ~60% of iOS systemGroupedBackground
      // Dark: iOS-like translucent dark surface
      darkColor: const Color(0xCC1C1C1E), // ~80% of iOS secondarySystemBackground (dark)
    ).resolveFrom(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28), // closer to iOS
        child: DecoratedBox(
          // This is the missing part: a translucent "material" tint above the blur
          decoration: BoxDecoration(
            color: sheetFill,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
          ),
          child: CupertinoPopupSurface(
            // Important: don't paint an opaque surface, we provide our own.
            isSurfacePainted: false,
            child: Column(
              children: [
                // ── Grab handle ─────────────────────────────────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    final delta = -details.delta.dy / screenHeight;
                    final newSize = (sheetController.size + delta).clamp(0.30, 0.95);
                    sheetController.jumpTo(newSize);
                  },
                  onVerticalDragEnd: (details) async {
                    final velocity = details.primaryVelocity ?? 0;

                    if (velocity > 800 || sheetController.size < 0.35) {
                      await sheetController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInCubic,
                      );
                      onDismiss();
                      return;
                    }

                    const anchors = [0.30, 0.55, 0.95];
                    final nearest = anchors.reduce((a, b) =>
                        (a - sheetController.size).abs() < (b - sheetController.size).abs()
                            ? a
                            : b);

                    final overshoot = (nearest - sheetController.size) * 0.12;
                    await sheetController.animateTo(
                      (nearest + overshoot).clamp(0.28, 0.97),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                    );
                    await sheetController.animateTo(
                      nearest,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey3.resolveFrom(context),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Scrollable content ──────────────────────────────────────
                Expanded(
                  child: CupertinoScrollbar(
                    controller: scrollController,
                    child: ListView(
                      controller: scrollController,
                      primary: false,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [child],
                    ),
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