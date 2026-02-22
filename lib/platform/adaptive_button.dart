import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

enum AdaptiveButtonType {
  isNull,
  normal,
  destructive,
  destructiveContainer,
  primary,
  secondary,
  tertiary,
  primaryContainer,
  secondaryContainer,
  tertiaryContainer
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
    required VoidCallback? onPressed,
    Widget? child,
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
      if(child == null) {
        return IconButton(
          icon: Icon(icon),
          style: style, //tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: onPressed,
        );
      }

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
    required VoidCallback? onPressed,
    Widget? child,
    IconData? icon,
    AdaptiveButtonType type = AdaptiveButtonType.normal,
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    CupertinoButtonSize? size,
  }) {

    Widget? content = child;

    final bool isDisabled = onPressed == null;

    final Color? effectiveBg = isDisabled
        ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
        : backgroundColor;

    final Color? effectiveFg = isDisabled
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : foregroundColor;

    // Reference text style used in Cupertino buttons
    final TextStyle baseTextStyle = CupertinoTheme.of(context).textTheme.textStyle;

    // Pick an explicit icon size so it never shrinks
    final double iconPx = (size ?? CupertinoButtonSize.medium) == CupertinoButtonSize.large ? 24.0 : 20.0;

    // Measure typical text height from current theme (no arbitrary height)
    final double textHeight = _measureCupertinoTextHeight(context, baseTextStyle);

    // Ensure icon-only has at least the same content height as text buttons
    final double targetContentHeight = math.max(iconPx, textHeight);

    Widget buildIcon() { // This is done to keep the same height for icon only button
      if(child != null) {
        return Icon(
            icon, 
            color: effectiveFg,
            size: size == CupertinoButtonSize.large ? 24 : null,
          );
      }

      return SizedBox(
        height: targetContentHeight,
        child: Center(
          child: Icon(icon, color: effectiveFg, size: iconPx),
        ),
      );
    }

    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildIcon(),
          if (child != null) ...[
            const SizedBox(width: 8),
            child,
          ]
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
      child: content!,
    );
  }

  static double _measureCupertinoTextHeight(BuildContext context, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: 'Ag', style: style), // 'Ag' covers ascender/descender
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return tp.height;
  }

  static Color? _bgColorHelper(Color? user, AdaptiveButtonType type, BuildContext context) {
    Color? bgColor;
    if (user != null) {
      bgColor = user;
    } else {
      switch (type) {
        case AdaptiveButtonType.destructive:
          bgColor = AdaptiveThemeColor.error(context);
          break;
        case AdaptiveButtonType.destructiveContainer:
          bgColor = AdaptiveThemeColor.errorContainer(context);
          break;
        case AdaptiveButtonType.primary:
          bgColor = AdaptiveThemeColor.primary(context);
          break;
        case AdaptiveButtonType.secondary:
          bgColor = AdaptiveThemeColor.secondary(context);
          break;
        case AdaptiveButtonType.tertiary:
          bgColor = AdaptiveThemeColor.tertiary(context);
          break;
        case AdaptiveButtonType.primaryContainer:
          bgColor = AdaptiveThemeColor.primaryContainer(context);
          break;
        case AdaptiveButtonType.secondaryContainer:
          bgColor = AdaptiveThemeColor.secondaryContainer(context);
          break;
        case AdaptiveButtonType.tertiaryContainer:
          bgColor = AdaptiveThemeColor.tertiaryContainer(context);
          break;
        case AdaptiveButtonType.normal:
          bgColor = AdaptiveThemeColor.normal(context);
          break;
        default:
          bgColor = null;
      }
    }

    return bgColor;
  }

  static Color? _fgColorHelper(Color? user, AdaptiveButtonType type, BuildContext context) {
    Color? fgColor;
    if (user != null) {
      fgColor = user;
    } else {
      switch (type) {
        case AdaptiveButtonType.destructive:
          fgColor = AdaptiveThemeColor.onError(context);
          break;
        case AdaptiveButtonType.destructiveContainer:
          fgColor = AdaptiveThemeColor.onErrorContainer(context);
          break;
        case AdaptiveButtonType.primary:
          fgColor = AdaptiveThemeColor.onPrimary(context);
          break;
        case AdaptiveButtonType.secondary:
          fgColor = AdaptiveThemeColor.onSecondary(context);
          break;
        case AdaptiveButtonType.tertiary:
          fgColor = AdaptiveThemeColor.onTertiary(context);
          break;
        case AdaptiveButtonType.primaryContainer:
          fgColor = AdaptiveThemeColor.onPrimaryContainer(context);
          break;
        case AdaptiveButtonType.secondaryContainer:
          fgColor = AdaptiveThemeColor.onSecondaryContainer(context);
          break;
        case AdaptiveButtonType.tertiaryContainer:
          fgColor = AdaptiveThemeColor.onTertiaryContainer(context);
          break;
        case AdaptiveButtonType.normal:
          fgColor = AdaptiveThemeColor.onNormal(context);
          break;
        default:
          fgColor = null;
      }
    }

    return fgColor;
  }

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------
  static Widget build({
    required BuildContext context,    
    required VoidCallback? onPressed,
    Widget? label,
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
    if(label == null && icon == null) throw ArgumentError("Icon and label cannot be null together");

    if (AppPlatform.isApple) {
      return _cupertinoButton(
        context: context,
        child: label,
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
        child: label,
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
