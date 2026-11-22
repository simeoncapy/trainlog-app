import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/ui/cupertino/apple_brand_font.dart';

class AdaptiveInformationMessage {

  static void _showMaterialDialog(
    BuildContext context,
    String message,
    String? title,
  ) {
    if (Navigator.of(context, rootNavigator: true).canPop()) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title ?? AppLocalizations.of(context)!.dialogueDefaultInfoTitle,
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }


  static void _showMaterialSnackBar(
    String message, {
    Duration? duration,
    bool replace = false,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    if (replace) messenger.clearSnackBars();
    messenger.showSnackBar(
      duration == null
          ? SnackBar(content: Text(message))
          : SnackBar(content: Text(message), duration: duration),
    );
  }

  /// Material look of a floating [SnackBar], drawn on the root navigator's
  /// overlay so it shows above modal routes such as bottom sheets, which
  /// cover the root scaffold's snackbars.
  static OverlayEntry? _materialOverlaySnackBar;

  static void _showMaterialOverlaySnackBar(
    String message, {
    int durationMillis = 4000,
  }) {
    final navigatorState = rootNavigatorKey.currentState;
    final overlayState = navigatorState?.overlay;

    if (overlayState == null) return;

    final theme = Theme.of(navigatorState!.context);
    final cs = theme.colorScheme;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: SafeArea(
          child: Material(
            color: cs.inverseSurface,
            elevation: 6,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onInverseSurface),
              ),
            ),
          ),
        ),
      ),
    );

    // Replace the previous message rather than stacking them on repeated taps.
    final previous = _materialOverlaySnackBar;
    if (previous != null && previous.mounted) previous.remove();
    _materialOverlaySnackBar = entry;

    overlayState.insert(entry);
    Timer(Duration(milliseconds: durationMillis), () {
      if (entry.mounted) entry.remove();
      if (identical(_materialOverlaySnackBar, entry)) {
        _materialOverlaySnackBar = null;
      }
    });
  }

  static void _showCupertinoDialog(BuildContext context, String message, String? title) {
    if (Navigator.of(context, rootNavigator: true).canPop()) return;

    showCupertinoDialog(
      context: context,
      builder: (_) => appleDialogTint(context, CupertinoAlertDialog(
        title: AppleBrandFont(
            child: Text(title ?? AppLocalizations.of(context)!.dialogueDefaultInfoTitle)),
        content: AppleBrandFont(child: Text(message)),
        actions: [
          CupertinoDialogAction(
            child: AppleBrandFont(
                child: Text(MaterialLocalizations.of(context).okButtonLabel)),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      )),
    );
  }

  /// Removes the iOS message on screen, so the next one replaces it rather
  /// than stacking under it.
  static VoidCallback? _dismissCupertinoSnackBar;

  static void _showCupertinoSnackBar(
    String message, {
    int durationMillis = 3000,
  }) {
    final navigatorState = rootNavigatorKey.currentState;
    final overlayState = navigatorState?.overlay;

    if (overlayState == null) return;

    // Use root navigator context for theming if available.
    final themeContext = navigatorState!.context;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 24,
        left: 16,
        right: 16,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(themeContext),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DefaultTextStyle(
                style: CupertinoTheme.of(themeContext).textTheme.textStyle.copyWith(fontSize: 14),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // `mounted` is still false until the entry's first frame, so track
    // removal here: two messages shown in the same frame must not stack.
    var removed = false;
    void dismiss() {
      if (removed) return;
      removed = true;
      entry.remove();
      if (identical(_dismissCupertinoSnackBar, dismiss)) {
        _dismissCupertinoSnackBar = null;
      }
    }

    _dismissCupertinoSnackBar?.call();
    _dismissCupertinoSnackBar = dismiss;

    overlayState.insert(entry);
    Timer(Duration(milliseconds: durationMillis), dismiss);
  }


  static void show(
    BuildContext context,
    String message, {
    bool isImportant = false,
    String? title,
  }) {
    if (AppPlatform.isApple) {
      if (isImportant) {
        _showCupertinoDialog(context, message, title);
      } else {
        _showCupertinoSnackBar(message);
      }
    } else {
      if (isImportant) {
        _showMaterialDialog(context, message, title);
      } else {
        _showMaterialSnackBar(message);
      }
    }
  }

  /// A short, non-blocking message: a [SnackBar] on Android, a toast on iOS.
  ///
  /// Screens call this instead of `ScaffoldMessenger.showSnackBar`, so the
  /// message follows the design. [duration] defaults to the platform's usual
  /// time. With [replace], the messages already shown or queued on Android
  /// are cleared first; on iOS a new message always replaces the previous
  /// one.
  static void showInfo(
    String message, {
    Duration? duration,
    bool replace = false,
  }) {
    if (AppPlatform.isApple) {
      if (duration == null) {
        _showCupertinoSnackBar(message);
      } else {
        _showCupertinoSnackBar(
          message,
          durationMillis: duration.inMilliseconds,
        );
      }
    } else {
      _showMaterialSnackBar(message, duration: duration, replace: replace);
    }
  }

  /// Like [showInfo], but stays visible above an open bottom sheet or other
  /// modal route.
  static void showInfoAboveModal(String message) {
    if (AppPlatform.isApple) {
      _showCupertinoSnackBar(message);
    } else {
      _showMaterialOverlaySnackBar(message);
    }
  }
}
