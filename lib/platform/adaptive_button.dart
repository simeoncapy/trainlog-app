import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

enum AdaptiveButtonType {
  normal,
  destructive,
  primary,
  secondary,
  tertiary
}

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
    AdaptiveButtonType type = AdaptiveButtonType.normal,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    double? elevation,
    BorderRadius? borderRadius,
  }) {

    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      minimumSize: minimumSize,
      elevation: elevation ?? (type == AdaptiveButtonType.destructive ? 1 : null),
      // shape: RoundedRectangleBorder(
      //   borderRadius: borderRadius ?? BorderRadius.circular(8),
      // ),
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
    AdaptiveButtonType type = AdaptiveButtonType.normal,
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    CupertinoButtonSize? size,
  }) {

    Widget content = child;

    final bool isDisabled = onPressed == null;

    final Color? effectiveBg = isDisabled
        ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
        : backgroundColor;

    final Color? effectiveFg = isDisabled
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : foregroundColor;

    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            color: effectiveFg,
            size: size == CupertinoButtonSize.large ? 24 : null,
          ),
          const SizedBox(width: 8),
          child,
        ],
      );
    }    

    return CupertinoButton.filled(
      onPressed: onPressed,
      sizeStyle: size ?? CupertinoButtonSize.medium,
      padding: padding,
      color: effectiveBg,
      foregroundColor: effectiveFg,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: content,
    );
  }

  static Color? _bgColorHelper(Color? user, AdaptiveButtonType type, BuildContext context) {
    Color? bgColor;
    if (user != null) {
      bgColor = user;
    } else {
      switch (type) {
        case AdaptiveButtonType.destructive:
          bgColor = AdaptiveThemeColor.errorContainer(context);
          break;
        case AdaptiveButtonType.primary:
          bgColor = AdaptiveThemeColor.primaryContainer(context);
          break;
        case AdaptiveButtonType.secondary:
          bgColor = AdaptiveThemeColor.secondaryContainer(context);
          break;
        case AdaptiveButtonType.tertiary:
          bgColor = AdaptiveThemeColor.tertiary(context);
          break;
        default:
          bgColor = null;
      }
    }

    return bgColor;
  }

  static Color? _fgColorHelper(Color? user, AdaptiveButtonType type, BuildContext context) {
    Color? bgColor;
    if (user != null) {
      bgColor = user;
    } else {
      switch (type) {
        case AdaptiveButtonType.destructive:
          bgColor = AdaptiveThemeColor.onErrorContainer(context);
          break;
        case AdaptiveButtonType.primary:
          bgColor = AdaptiveThemeColor.onPrimaryContainer(context);
          break;
        case AdaptiveButtonType.secondary:
          bgColor = AdaptiveThemeColor.onSecondaryContainer(context);
          break;
        case AdaptiveButtonType.tertiary:
          bgColor = AdaptiveThemeColor.onTertiaryContainer(context);
          break;
        default:
          bgColor = null;
      }
    }

    return bgColor;
  }

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------
  static Widget build({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onPressed,
    IconData? icon,
    AdaptiveButtonType type = AdaptiveButtonType.normal,
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
        type: type,
        backgroundColor: _bgColorHelper(backgroundColor, type, context),
        foregroundColor: _fgColorHelper(foregroundColor, type, context),
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
        type: type,
        backgroundColor: _bgColorHelper(backgroundColor, type, context),
        foregroundColor: _fgColorHelper(foregroundColor, type, context),
        padding: padding,
        minimumSize: minimumSize,
        elevation: elevation,
        borderRadius: borderRadius,
      );
    }
  }
}
