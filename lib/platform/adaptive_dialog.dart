import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

enum AdaptiveDialogResult {
  primary,
  secondary,
  neutral,
  cancelled,
}

class AdaptiveDialogAction {
  final String label;
  final AdaptiveDialogResult result;

  /// Material: Elevated/TextButton style is decided in the builder below.
  /// Cupertino: will map to isDefaultAction/isDestructiveAction.
  final bool isDefault;
  final bool isDestructive;

  const AdaptiveDialogAction({
    required this.label,
    required this.result,
    this.isDefault = false,
    this.isDestructive = false,
  });

  static AdaptiveDialogAction ok(BuildContext context) => AdaptiveDialogAction(
        label: MaterialLocalizations.of(context).okButtonLabel,
        result: AdaptiveDialogResult.primary,
        isDefault: true,
      );

  static AdaptiveDialogAction cancel(BuildContext context) => AdaptiveDialogAction(
        label: MaterialLocalizations.of(context).cancelButtonLabel,
        result: AdaptiveDialogResult.cancelled,
      );
}

class AdaptiveDialog {
  static Future<AdaptiveDialogResult> show({
    required BuildContext context,
    String? title,
    required String message,

    /// If null, uses loc.dialogueDefaultInfoTitle for title.
    /// If you want no title at all, pass title: "" (empty).
    List<AdaptiveDialogAction>? actions,

    /// iOS: for destructive confirmations, ActionSheet is often nicer.
    bool useActionSheetOnIOS = false,

    /// If true, tapping outside closes (Material: barrierDismissible; iOS AlertDialog: false by convention).
    bool barrierDismissible = false,
  }) async {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      return AdaptiveDialogResult.cancelled;
    }

    final loc = AppLocalizations.of(context)!;

    final resolvedTitle = (title == null)
        ? loc.dialogueDefaultInfoTitle
        : title; // allow "" to mean "no title text"

    final resolvedActions = actions ??
        <AdaptiveDialogAction>[
          AdaptiveDialogAction.ok(context),
        ];

    if (AppPlatform.isApple) {
      if (useActionSheetOnIOS) {
        return _showCupertinoActionSheet(
          context: context,
          title: resolvedTitle,
          message: message,
          actions: resolvedActions,
          barrierDismissible: barrierDismissible,
        );
      }
      return _showCupertinoAlert(
        context: context,
        title: resolvedTitle,
        message: message,
        actions: resolvedActions,
      );
    }

    return _showMaterialAlert(
      context: context,
      title: resolvedTitle,
      message: message,
      actions: resolvedActions,
      barrierDismissible: barrierDismissible,
    );
  }

  // -----------------------
  // MATERIAL
  // -----------------------
  static Future<AdaptiveDialogResult> _showMaterialAlert({
    required BuildContext context,
    required String title,
    required String message,
    required List<AdaptiveDialogAction> actions,
    required bool barrierDismissible,
  }) async {
    final result = await showDialog<AdaptiveDialogResult>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) {
        return AlertDialog(
          title: title.isEmpty ? null : Text(title),
          content: Text(message),
          actions: actions.map((a) {
            final isCancel = a.result == AdaptiveDialogResult.cancelled;

            // Style choices:
            // - Cancel: TextButton
            // - Destructive: ElevatedButton with error colors
            // - Default/Primary: ElevatedButton
            if (isCancel) {
              return TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(a.result),
                child: Text(a.label),
              );
            }

            if (a.isDestructive) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(a.result),
                child: Text(a.label),
              );
            }

            // Primary/neutral use ElevatedButton for “choice” emphasis
            return ElevatedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(a.result),
              child: Text(a.label),
            );
          }).toList(),
        );
      },
    );

    return result ?? AdaptiveDialogResult.cancelled;
  }

  // -----------------------
  // CUPERTINO ALERT
  // -----------------------
  static Future<AdaptiveDialogResult> _showCupertinoAlert({
    required BuildContext context,
    required String title,
    required String message,
    required List<AdaptiveDialogAction> actions,
  }) async {
    final result = await showCupertinoDialog<AdaptiveDialogResult>(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: title.isEmpty ? null : Text(title),
          content: Text(message),
          actions: actions.map((a) {
            return CupertinoDialogAction(
              isDefaultAction: a.isDefault,
              isDestructiveAction: a.isDestructive,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(a.result),
              child: Text(a.label),
            );
          }).toList(),
        );
      },
    );

    return result ?? AdaptiveDialogResult.cancelled;
  }

  // -----------------------
  // CUPERTINO ACTION SHEET
  // -----------------------
  static Future<AdaptiveDialogResult> _showCupertinoActionSheet({
    required BuildContext context,
    required String title,
    required String message,
    required List<AdaptiveDialogAction> actions,
    required bool barrierDismissible,
  }) async {
    // showCupertinoModalPopup dismisses on outside tap by default.
    final result = await showCupertinoModalPopup<AdaptiveDialogResult>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) {
        // iOS convention: put Cancel in cancelButton, others in actions.
        final cancel = actions.where((a) => a.result == AdaptiveDialogResult.cancelled).toList();
        final nonCancel = actions.where((a) => a.result != AdaptiveDialogResult.cancelled).toList();

        return CupertinoActionSheet(
          title: title.isEmpty ? null : Text(title),
          message: Text(message),
          actions: nonCancel.map((a) {
            return CupertinoActionSheetAction(
              isDestructiveAction: a.isDestructive,
              isDefaultAction: a.isDefault,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(a.result),
              child: Text(a.label),
            );
          }).toList(),
          cancelButton: cancel.isEmpty
              ? null
              : CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(cancel.first.result),
                  child: Text(cancel.first.label),
                ),
        );
      },
    );

    return result ?? AdaptiveDialogResult.cancelled;
  }

  // Convenience: confirm dialog
  static Future<bool> confirm({
    required BuildContext context,
    String? title,
    required String message,
    String? confirmLabel,
    bool destructive = false,
    bool useActionSheetOnIOS = true,
  }) async {
    final res = await show(
      context: context,
      title: title,
      message: message,
      useActionSheetOnIOS: useActionSheetOnIOS && destructive,
      actions: [
        AdaptiveDialogAction.cancel(context),
        AdaptiveDialogAction(
          label: confirmLabel ?? MaterialLocalizations.of(context).okButtonLabel,
          result: AdaptiveDialogResult.primary,
          isDefault: true,
          isDestructive: destructive,
        ),
      ],
    );

    return res == AdaptiveDialogResult.primary;
  }

  /// Close the dialog shown by AdaptiveDialog (always uses rootNavigator).
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  /// Show a dialog/popup with a fully custom child.
  /// - Material: Dialog
  /// - iOS: CupertinoPopupSurface via showCupertinoModalPopup
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    double maxWidth = 500,
    double maxHeightFactor = 0.6,
    EdgeInsetsGeometry insetPadding = const EdgeInsets.all(16),
  }) async {
    if (AppPlatform.isApple) {
      return showCupertinoModalPopup<T>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: barrierDismissible,
        builder: (ctx) {
          final maxH = MediaQuery.of(ctx).size.height * maxHeightFactor;
          return SafeArea(
            child: Center(
              child: Padding(
                padding: insetPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxH,
                  ),
                  child: CupertinoPopupSurface(
                    isSurfacePainted: true,
                    // Optional: keep it for reliable shadows/widgets that rely on Material
                    child: Material(
                      color: Colors.transparent,
                      child: builder(ctx),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * maxHeightFactor;
        return Dialog(
          //insetPadding: insetPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxH,
            ),
            child: builder(ctx),
          ),
        );
      },
    );
  }
}
