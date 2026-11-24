import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;

/// One button revealed by swiping a [SwipeActions] row to the left.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;

  /// The button's fill; its icon and label are white.
  final Color color;
  final VoidCallback onPressed;
}

/// An iOS list row that slides left under the finger to reveal [actions]
/// on its trailing side, as in Mail or Reminders. It snaps open past half
/// the buttons' width (or on a quick flick) and closed otherwise. Tapping a
/// button closes the row and runs it; tapping the open row closes it. Only
/// one row is open at a time, and scrolling the list closes it.
class SwipeActions extends StatefulWidget {
  const SwipeActions({
    super.key,
    required this.actions,
    required this.child,
    this.buttonWidth = 76,
  });

  /// Shown left to right; the last one sits against the trailing edge.
  final List<SwipeAction> actions;
  final Widget child;
  final double buttonWidth;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  /// The open row, closed when another one opens.
  static _SwipeActionsState? _open;

  // 0 = closed, 1 = open (the buttons' full width).
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    upperBound: 1.3, // some rubber band past the buttons
  );
  ScrollPosition? _scroll;

  double get _extent => widget.buttonWidth * widget.actions.length;

  bool get _isOpen => _ctrl.value > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_close);
      _scroll = scroll?..addListener(_close);
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_close);
    if (_open == this) _open = null;
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    if (!_isOpen) return;
    _ctrl.animateTo(0, curve: Curves.easeOutCubic);
    if (_open == this) _open = null;
  }

  void _settle(bool open) {
    if (open) {
      if (_open != this) _open?._close();
      _open = this;
      _ctrl.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _close();
    }
  }

  void _onDragStart(DragStartDetails _) {
    if (_open != this) _open?._close();
    _ctrl.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = -(d.primaryDelta ?? 0) / _extent;
    var next = _ctrl.value + delta;
    // Resist past the buttons' width: only part of the overshoot follows.
    if (next > 1 && delta > 0) {
      final base = _ctrl.value > 1 ? _ctrl.value : 1.0;
      next = base + (next - base) * 0.3;
    }
    _ctrl.value = next.clamp(0.0, _ctrl.upperBound);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -300) return _settle(true);
    if (v > 300) return _settle(false);
    _settle(_ctrl.value > 0.5);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return widget.child;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final sign = isRtl ? -1.0 : 1.0;

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: (d) => _onDragUpdate(
        DragUpdateDetails(
          globalPosition: d.globalPosition,
          delta: d.delta * sign,
          primaryDelta: (d.primaryDelta ?? 0) * sign,
        ),
      ),
      onHorizontalDragEnd: (d) => _onDragEnd(
        DragEndDetails(primaryVelocity: (d.primaryVelocity ?? 0) * sign),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final shift = _ctrl.value * _extent;
            return Stack(
              children: [
                // The buttons, filling the space the row leaves; they
                // stretch together with the rubber band.
                if (shift > 0)
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: 0,
                    bottom: 0,
                    end: 0,
                    width: shift,
                    child: Row(
                      children: [
                        for (final a in widget.actions)
                          Expanded(child: _Button(action: a, onTap: () {
                            _close();
                            a.onPressed();
                          })),
                      ],
                    ),
                  ),
                Transform.translate(
                  offset: Offset(-shift * sign, 0),
                  child: child,
                ),
              ],
            );
          },
          // While open, a tap on the row closes it instead of opening it.
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => _isOpen
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _close,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.action, required this.onTap});

  final SwipeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        .copyWith(color: CupertinoColors.white);
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: action.color,
          // Material only so the label keeps its text style here.
          child: Material(
            type: MaterialType.transparency,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 0,
                maxWidth: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: CupertinoColors.white, size: 22),
                    const SizedBox(height: 4),
                    Text(action.label, style: style, maxLines: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
