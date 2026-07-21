import 'package:yaml/yaml.dart';

/// The kind of change a changelog item describes.
///
/// Declaration order is the display order in the changelog dialogue:
/// features on top, then minor enhancements, then everything else,
/// with bug fixes at the bottom.
enum ChangelogChangeType {
  feature,
  minor,
  other,
  fix;

  /// Unknown or missing types are treated as [other].
  static ChangelogChangeType fromName(String? name) {
    final normalized = name?.trim().toLowerCase();
    return ChangelogChangeType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => ChangelogChangeType.other,
    );
  }
}

class ChangelogChange {
  final ChangelogChangeType type;
  final String text;

  const ChangelogChange({
    required this.type,
    required this.text,
  });
}

class ChangelogEntry {
  /// Human version string, e.g. "0.4.1".
  final String version;
  final DateTime? date;
  final List<ChangelogChange> changes;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });

  bool get hasChanges => changes.isNotEmpty;

  factory ChangelogEntry.fromYaml(YamlMap map) {
    final changes = <ChangelogChange>[];
    final changesNode = map['changes'];
    if (changesNode is YamlList) {
      for (final item in changesNode) {
        if (item is! YamlMap) continue;
        final text = item['text']?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        changes.add(ChangelogChange(
          type: ChangelogChangeType.fromName(item['type']?.toString()),
          text: text,
        ));
      }
    }

    return ChangelogEntry(
      version: map['version']?.toString().trim() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? ''),
      changes: changes,
    );
  }

  /// Changes grouped by type, keys ordered like [ChangelogChangeType.values]
  /// (feature → minor → other → fix), regardless of the order in the YAML.
  /// Types without any change are omitted.
  Map<ChangelogChangeType, List<ChangelogChange>> get groupedChanges {
    return {
      for (final type in ChangelogChangeType.values)
        if (changes.any((c) => c.type == type))
          type: changes.where((c) => c.type == type).toList(),
    };
  }

  bool isNewerThan(String otherVersion) =>
      otherVersion.isEmpty || compareVersions(version, otherVersion) > 0;

  /// Numeric dotted-version comparison ("0.10.0" > "0.9.1"). Any build
  /// metadata suffix ("+21") is ignored; missing segments count as 0.
  static int compareVersions(String a, String b) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();

    final partsA = parse(a);
    final partsB = parse(b);
    final length = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (var i = 0; i < length; i++) {
      final valueA = i < partsA.length ? partsA[i] : 0;
      final valueB = i < partsB.length ? partsB[i] : 0;
      if (valueA != valueB) return valueA.compareTo(valueB);
    }
    return 0;
  }
}
