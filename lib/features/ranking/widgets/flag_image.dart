import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// Renders an area flag from the backend static SVG vector service
/// (`/static/images/flags/<code>.svg`, resolved via [TrainlogProvider.flagUrl]).
///
/// [code] is an ISO country code (`"JP"`) or an ISO 3166-2 subdivision code
/// (`"JP-13"`). While the vector loads — or if the backend has no asset for it —
/// the widget falls back to the unicode flag emoji derived from the parent
/// country code, so a row never renders blank.
class FlagImage extends StatelessWidget {
  final String code;
  final double size;

  const FlagImage({super.key, required this.code, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final url = context.read<TrainlogProvider>().flagUrl(code);
    final countryCode = code.split('-').first;

    final fallback = Center(
      child: Text(
        countryCodeToEmoji(countryCode),
        style: TextStyle(fontSize: size * 0.82),
      ),
    );

    return SizedBox(
      width: size,
      height: size * 0.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SvgPicture.network(
          url,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => fallback,
        ),
      ),
    );
  }
}
