import 'package:flutter/widgets.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// A country resolved for display: its ISO 3166-1 alpha-2 [code], the
/// localized [name] (according to the user's locale) and the flag [emoji].
class CountryDetail {
  final String code;
  final String name;
  final String emoji;

  const CountryDetail({
    required this.code,
    required this.name,
    required this.emoji,
  });

  /// Builds a [CountryDetail] from an ISO country [code], resolving the
  /// localized name through the active [CountryLocalizations] and deriving the
  /// flag emoji from the code.
  factory CountryDetail.fromCode(String code, BuildContext context) {
    return CountryDetail(
      code: code,
      name: countryCodeToName(code, context),
      emoji: countryCodeToEmoji(code),
    );
  }
}
