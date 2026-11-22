import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// iOS counterpart of a Material snack bar: a short message in a Liquid
/// Glass capsule that drops in under the status bar, like the system
/// banners of iOS 26. It goes away on its own after [duration], on a tap, or
/// when swiped up. A new message replaces the one on screen.
///
/// Screens call it through `AdaptiveMessenger` (lib/ui/adaptive), never
/// directly.
class GlassToast {
  GlassToast._();

  static _GlassToastHandle? _current;

  static void show(
    OverlayState overlay,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.dismiss(animated: false);
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

  /// Removes the message on screen, if any (for tests and page changes).
  static void hide() => _current?.dismiss(animated: false);
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
    if (identical(GlassToast._current, this)) GlassToast._current = null;
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
    reverseDuration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
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
                builder: (context, child) => Opacity(
                  opacity: _anim.value,
                  child: Transform.translate(
                    offset: Offset(0, -24 * (1 - _curve.value)),
                    child: child,
                  ),
                ),
                child: GestureDetector(
                  onTap: hide,
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < 0) hide();
                  },
                  child: Semantics(
                    liveRegion: true,
                    child: LiquidGlass(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
    );
  }
}
