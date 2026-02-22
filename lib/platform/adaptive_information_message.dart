import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

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


  static void _showMaterialSnackBar(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(content: Text(message)),
                      );
  }

  static void _showCupertinoDialog(BuildContext context, String message, String? title) {
    if (Navigator.of(context, rootNavigator: true).canPop()) return;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title ?? AppLocalizations.of(context)!.dialogueDefaultInfoTitle),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }

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

    overlayState.insert(entry);
    Timer(Duration(milliseconds: durationMillis), entry.remove);
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

  /// Optional: if you *want* a fully context-free API for non-important messages:
  static void showInfo(String message) {
    if (AppPlatform.isApple) {
      _showCupertinoSnackBar(message);
    } else {
      _showMaterialSnackBar(message);
    }
  }
}
