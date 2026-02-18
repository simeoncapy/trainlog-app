import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveButton {
  static CupertinoButtonSize get large => CupertinoButtonSize.large;
  static CupertinoButtonSize get medium => CupertinoButtonSize.medium;
  static CupertinoButtonSize get small => CupertinoButtonSize.small;

  // ------------------------------------------------------------
  // MATERIAL
  // ------------------------------------------------------------
  static Widget _materialButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onPressed,
    IconData? icon,
    bool destructive = false,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    final Color? bgColor = backgroundColor ??
        (destructive ? Theme.of(context).colorScheme.error : null);

    final Color? fgColor = foregroundColor ??
        (destructive ? Theme.of(context).colorScheme.onError : null);

    final style = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      padding: padding,
      minimumSize: minimumSize,
      elevation: elevation ?? (destructive ? 1 : null),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
        style: style,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  // ------------------------------------------------------------
  // CUPERTINO
  // ------------------------------------------------------------
  static Widget _cupertinoButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onPressed,
    IconData? icon,
    bool destructive = false,
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    CupertinoButtonSize? size,
  }) {
    final Color? bgColor =
        backgroundColor ?? (destructive ? CupertinoColors.systemRed.resolveFrom(context) : null);
    final Color? fgColor = foregroundColor ??
        (destructive ? CupertinoColors.white : null);

    Widget content = child;

    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fgColor,),
          const SizedBox(width: 8),
          child,
        ],
      );
    }

    return CupertinoButton(
      onPressed: onPressed,
      sizeStyle: size ?? CupertinoButtonSize.medium,
      padding:
          padding,// ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      color: bgColor,
      foregroundColor: fgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: content,
    );
  }

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------
  static Widget build({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onPressed,
    IconData? icon,
    bool destructive = false,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    CupertinoButtonSize? size,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    if (AppPlatform.isApple) {
      return _cupertinoButton(
        context: context,
        child: child,
        onPressed: onPressed,
        icon: icon,
        destructive: destructive,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        borderRadius: borderRadius,
        size: size,
      );
    } else {
      return _materialButton(
        context: context,
        child: child,
        onPressed: onPressed,
        icon: icon,
        destructive: destructive,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        minimumSize: minimumSize,
        elevation: elevation,
        borderRadius: borderRadius,
      );
    }
  }
}
