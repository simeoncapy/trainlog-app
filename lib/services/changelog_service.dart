import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'package:trainlog_app/data/models/changelog.dart';

/// The parsed content of a changelog asset file.
class ChangelogDocument {
  /// Entries sorted by version, newest first.
  final List<ChangelogEntry> entries;

  /// True when the English file was loaded because no file exists for the
  /// requested (non-English) language.
  final bool isFallback;

  const ChangelogDocument({
    required this.entries,
    required this.isFallback,
  });

  ChangelogEntry? get latest => entries.isEmpty ? null : entries.first;
}

/// Loads release notes from assets/changelog/changelog_<language>.yaml,
/// falling back to changelog_en.yaml for languages without a translation.
class ChangelogService {
  static const _assetDir = 'assets/changelog';

  static Future<ChangelogDocument> load(
    String languageCode, {
    AssetBundle? bundle,
  }) async {
    final effectiveBundle = bundle ?? rootBundle;

    String data;
    var isFallback = false;
    try {
      data = await effectiveBundle
          .loadString('$_assetDir/changelog_$languageCode.yaml');
    } catch (_) {
      try {
        data = await effectiveBundle.loadString('$_assetDir/changelog_en.yaml');
        isFallback = languageCode != 'en';
      } catch (e) {
        debugPrint('⚠️ ChangelogService: no changelog asset available: $e');
        return const ChangelogDocument(entries: [], isFallback: false);
      }
    }

    return ChangelogDocument(entries: parse(data), isFallback: isFallback);
  }

  /// Parses the YAML source. The root is a map with a single
  /// changelog_<language> key holding the list of version entries; the key
  /// name is not checked so a copied file with a stale key still loads.
  @visibleForTesting
  static List<ChangelogEntry> parse(String yamlSource) {
    try {
      final root = loadYaml(yamlSource);
      if (root is! YamlMap || root.isEmpty) return const [];

      final listNode =
          root.values.firstWhere((v) => v is YamlList, orElse: () => null);
      if (listNode is! YamlList) return const [];

      final entries = listNode
          .whereType<YamlMap>()
          .map(ChangelogEntry.fromYaml)
          .where((e) => e.version.isNotEmpty)
          .toList()
        ..sort((a, b) => ChangelogEntry.compareVersions(b.version, a.version));
      return entries;
    } catch (e) {
      debugPrint('⚠️ ChangelogService: failed to parse changelog: $e');
      return const [];
    }
  }
}
