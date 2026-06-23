import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';

/// The top-three award icon: a trophy for #1 and a medal for #2/#3, coloured
/// gold / silver / bronze. Shared by the list rows and the user-position badge,
/// which only differ by [size].
class RankingMedal extends StatelessWidget {
  final int rank;
  final double size;

  const RankingMedal({super.key, required this.rank, this.size = 18});

  static const Color _gold = AppColors.amber;
  static const Color _silver = Color(0xFFB8BCC4);
  static const Color _bronze = Color(0xFFCD7F45);

  /// Whether [rank] earns a medal (top three).
  static bool isMedal(int rank) => rank >= 1 && rank <= 3;

  /// The gold/silver/bronze colour for a top-three [rank].
  static Color colorOf(int rank) =>
      rank == 1 ? _gold : (rank == 2 ? _silver : _bronze);

  @override
  Widget build(BuildContext context) {
    return Icon(
      // Trophy for the winner, a medal for the runners-up.
      rank == 1 ? Icons.emoji_events : Icons.military_tech,
      size: size,
      color: colorOf(rank),
    );
  }
}
