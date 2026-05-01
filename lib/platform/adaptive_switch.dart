import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;


  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });



  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }

    return Switch(value: value, onChanged: onChanged);
  }
}
