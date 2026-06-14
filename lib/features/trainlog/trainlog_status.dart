import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Health of the Trainlog router/instance, as shown on the status page.
enum TrainlogStatus {
  ok, trouble, down;

  Color toColor() {
    switch(this) {
      case ok:
        return Colors.green;
      case trouble:
        return Colors.orange;
      case down:
        return Colors.red;
    }
  }

  String toEmoji() {
    switch(this) {
      case ok:
        return "🟢";
      case trouble:
        return "⚠️";
      case down:
        return "❌";
    }
  }

  Icon toIcon(double? size) {
    switch(this) {
      case ok:
        return Icon( AdaptiveIcons.ok, size: size, color: ok.toColor(),);
      case trouble:
        return Icon( AdaptiveIcons.warning, size: size, color: trouble.toColor(),);
      case down:
        return Icon( AdaptiveIcons.error, size: size, color: down.toColor(),);
    }
  }
}
