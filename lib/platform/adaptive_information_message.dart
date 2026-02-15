import 'package:flutter/material.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveInformationMessage {

  static void _showMaterialSnackBar(BuildContext context, String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(content: Text(message)),
                      );
  }

  static void _showCupertinoDialog(BuildContext context, String message) {
    if (Navigator.of(context, rootNavigator: true).canPop()) return;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(message),
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
  BuildContext context,
  String message, {
  int durationMillis = 3000,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  final overlayEntry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material( // Needed for shadow rendering reliability
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000), // subtle iOS shadow
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(
    Duration(milliseconds: durationMillis),
    overlayEntry.remove,
  );
}


  static void show(BuildContext context, String message, {bool isImportant = false}) {
    if (AppPlatform.isApple) {
      isImportant ? _showCupertinoDialog(context, message) : _showCupertinoSnackBar(context, message);
    } else {
      _showMaterialSnackBar(context, message);
    }
  }
}