import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';

class Monogram extends StatelessWidget {
  final String username;
  final bool highlight;

  const Monogram({super.key, required this.username, required this.highlight});

  static const _palette = <Color>[
    AppColors.blue,
    AppColors.modeBus,
    AppColors.modeTram,
    AppColors.modeAir,
    AppColors.modeFerry,
    AppColors.violet,
    AppColors.amberDk,
  ];

  @override
  Widget build(BuildContext context) {
    final letter =
        username.isEmpty ? '?' : username.substring(0, 1).toUpperCase();
    final color = _palette[username.hashCode.abs() % _palette.length];

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border:
            highlight ? Border.all(color: AppColors.amber, width: 2) : null,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}