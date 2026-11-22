import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// Glass of the package's own toast (`lg.GlassToast`), so the text-only
/// message and the one with an icon look alike.
const _toastGlass = lg.LiquidGlassSettings(
  thickness: 25,
  blur: 6,
  refractiveIndex: 1.15,
  saturation: 1.3,
);

/// iOS counterpart of a Material snack bar: a short message on Liquid Glass
/// that drops in under the status bar, like the system banners of iOS 26.
///
/// [show] draws our text-only pill: the package toast's glass and shape
/// (radius 24, at least 48 high) with the text alone, centred, in the app
/// font. [showWithIcon] calls the package's own toast (`lg.GlassToast`),
/// which has an icon. Either goes away on its own after its duration, or
/// when swiped up (ours also on a tap), and only one message is on screen
/// at a time: a new one, of either kind, replaces it.
///
/// Named `AppGlassToast` so it is not confused with the package's
/// `GlassToast`. Screens call it through `AdaptiveInformationMessage`
/// (lib/ui/adaptive), never directly.
class AppGlassToast {
  AppGlassToast._();

  static _GlassToastHandle? _current;

  /// Closes the package toast on screen; null when there is none.
  static VoidCallback? _dismissPackageToast;

  /// Shows [message] alone in the pill, on [overlay].
  static void show(
    OverlayState overlay,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _hideAll();
    final handle = _GlassToastHandle();
    _current = handle;
    handle.entry = OverlayEntry(
      builder: (_) => _GlassToastView(
        key: handle.viewKey,
        message: message,
        onDismissed: () => handle.remove(),
      ),
    );
    overlay.insert(handle.entry!);
    handle.timer = Timer(duration, handle.dismiss);
  }

  /// Shows [message] in the package's toast, with the icon and accent
  /// colour of [type], at the top of the screen.
  ///
  /// [context] must be below an [Overlay] (a screen's context): the package
  /// looks the overlay up from it.
  static void showWithIcon(
    BuildContext context,
    String message, {
    lg.GlassToastType type = lg.GlassToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _hideAll();
    final dismiss = lg.GlassToast.show(
      context,
      message: message,
      type: type,
      position: lg.GlassToastPosition.top,
      duration: duration,
    );
    var gone = false;
    late final VoidCallback dismissOnce;
    dismissOnce = () {
      if (gone) return;
      gone = true;
      if (identical(_dismissPackageToast, dismissOnce)) {
        _dismissPackageToast = null;
      }
      // The package removes its entry itself at the end of its duration or
      // after a swipe, and gives no callback for it: removing it again then
      // fails, and means it is already gone.
      try {
        dismiss();
      } catch (_) {}
    };
    _dismissPackageToast = dismissOnce;
  }

  /// Removes the message on screen, if any (for tests and page changes).
  static void hide() => _hideAll();

  static void _hideAll() {
    _current?.dismiss(animated: false);
    _dismissPackageToast?.call();
  }
}

class _GlassToastHandle {
  final viewKey = GlobalKey<_GlassToastViewState>();
  OverlayEntry? entry;
  Timer? timer;

  void dismiss({bool animated = true}) {
    timer?.cancel();
    final view = viewKey.currentState;
    if (animated && view != null && view.mounted) {
      view.hide();
    } else {
      remove();
    }
  }

  void remove() {
    timer?.cancel();
    // Not `mounted`: an entry inserted in this frame is not built yet, and
    // must still go when a second message replaces it at once.
    final e = entry;
    entry = null;
    e?.remove();
    if (identical(AppGlassToast._current, this)) {
      AppGlassToast._current = null;
    }
  }
}

class _GlassToastView extends StatefulWidget {
  const _GlassToastView({
    super.key,
    required this.message,
    required this.onDismissed,
  });

  final String message;
  final VoidCallback onDismissed;

  @override
  State<_GlassToastView> createState() => _GlassToastViewState();
}

class _GlassToastViewState extends State<_GlassToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 440),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutBack,
    // Out: the glass waits for the text to fade, then slides up.
    reverseCurve: const Interval(0.0, 0.5, curve: Curves.easeIn),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.5, 1.0),
    // Out: the text is gone in the first part, before the glass moves.
    reverseCurve: const Interval(0.5, 1.0),
  );

  void hide() {
    if (!mounted) return;
    _anim.reverse().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      color: CupertinoColors.label.resolveFrom(context),
    );

    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedBuilder(
                animation: _curve,
                // No fade on the glass: it does not draw while partly
                // transparent. In, it drops 24 px while the text fades in;
                // out, the text fades first, then the glass slides up off
                // the screen.
                builder: (context, child) {
                  final leaving = _anim.status == AnimationStatus.reverse;
                  final distance = leaving
                      ? MediaQuery.paddingOf(context).top + 8 + 160
                      : 24.0;
                  return Transform.translate(
                    offset: Offset(0, -distance * (1 - _curve.value)),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: hide,
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < 0) hide();
                  },
                  child: Semantics(
                    liveRegion: true,
                    // Built like the package's toast pill (shared layer,
                    // fixed radius 24), without its icon.
                    child: lg.AdaptiveLiquidGlassLayer(
                      settings: _toastGlass,
                      quality: lg.GlassQuality.premium,
                      child: lg.AdaptiveGlass(
                        shape: const lg.LiquidRoundedSuperellipse(
                          borderRadius: 24,
                        ),
                        settings: _toastGlass,
                        quality: lg.GlassQuality.premium,
                        useOwnLayer: false,
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            maxWidth: 400,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          alignment: Alignment.center,
                          // The glass needs a frame or two to capture what is
                          // behind it, so the text fades in during the
                          // second half of the entrance only.
                          child: FadeTransition(
                            opacity: _textFade,
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: textStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
